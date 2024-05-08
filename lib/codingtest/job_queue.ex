defmodule Codingtest.JobQueue do
  use GenServer

  alias Codingtest.Job

  @type pending :: list(Job.t())
  @type running :: %{reference() => Job.t()}

  ####################
  # Client
  ####################

  def start_link(name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, %{ max_running: 3 }, name: name)
  end

  def enqueue(%Job{} = job) do
    # Cast using the local registration name
    GenServer.cast(__MODULE__, {:enqueue, job})
  end
  def enqueue(pid, %Job{} = job) when is_pid(pid) do
    GenServer.cast(pid, {:enqueue, job})
  end
  def enqueue(job_type, job_payload) when is_atom(job_type) do
    # Cast using the local registration name
    GenServer.cast(__MODULE__, {:enqueue, %Job{type: job_type, payload: job_payload}})
  end
  def enqueue(pid, job_type, job_payload) when is_pid(pid) do
    GenServer.cast(pid, {:enqueue, %Job{type: job_type, payload: job_payload}})
  end

  def stop(pid, force? \\ false, timeout \\ :infinity) when is_pid(pid) do
    if force? do
      GenServer.stop(pid, :normal, timeout)
    else
      GenServer.call(pid, :stop, timeout)
    end
  end


  ####################
  # Server (callbacks)
  ####################

  @impl true
  def init(%{ max_running: max_running }) do
    # pending is a list of pending jobs
    # running is a map of running jobs, with a supervised task-reference as the key
    # max_running is the maximum number of running jobs
    # requested_stop is a list of pids that have requested to stop the job queue cleanly
    {:ok, %{ pending: [], running: %{}, max_running: max_running, requested_stop: [] }}
  end

  @impl true
  def handle_cast({:enqueue, %Job{} = job}, %{ pending: pending } = state) do
    IO.puts "Enqueueing Job #{job.type} (#{inspect job.payload})"
    # Update the state, then continue after all casts in process inbox are handled
    {:noreply, %{state | pending: [job | pending]}, {:continue, :from_cast}}
  end

  # If the task completed successfully
  @impl true
  def handle_info({ref, result}, %{ running: running } = state) do
    # Remove the task from the running map
    {completed_job, remain_running} = Map.pop!(running, ref)

    # Print the result
    IO.puts "Job #{completed_job.type} (#{inspect completed_job.payload}) completed: #{inspect result}"

    # We don't care about the :normal DOWN message
    Process.demonitor(ref, [:flush])

    # Update the state, then continue after all other info in process inbox are handled
    {:noreply, %{state | running: remain_running}, {:continue, :from_info}}
  end

  # If the task failed
  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, %{ pending: pending, running: running } = state) do
    # Remove the task from the running map
    {failed_job, remain_running} = Map.pop!(running, ref)

    # Print the error message
    case reason do
      {%RuntimeError{message: message}, _} ->
        IO.puts "Job #{failed_job.type} (#{inspect failed_job.payload}) failed: #{ message }"
      _ ->
        IO.puts "Job #{failed_job.type} (#{inspect failed_job.payload}) failed:"
        IO.inspect(reason)
    end

    # Enqueue the failed task again at the end of the queue
    now_pending =
      if failed_job.retry_count > 0 do
        IO.puts "Job #{failed_job.type} (#{inspect failed_job.payload}) will retry again soon."
        failed_job = %{failed_job | retry_count: failed_job.retry_count - 1, last_error: reason}
        [failed_job | pending]
      else
        IO.puts "Job #{failed_job.type} (#{inspect failed_job.payload}) has no more retry attempts left."
        pending
      end

    # Update the state, then continue after all other info in process inbox are handled
    {:noreply, %{state | pending: now_pending, running: remain_running}, {:continue, :from_info}}
  end

  # Handle starting any pending jobs in the queue
  @impl true
  def handle_continue(_from, %{ pending: [], running: running, requested_stop: requested_stop } = state) when map_size(running) == 0 and length(requested_stop) > 0 do
    Enum.each(requested_stop, fn pid -> GenServer.reply(pid, :ok) end)
    {:stop, :normal, state}
  end
  def handle_continue(_from, %{ pending: pending, running: running, max_running: max_running } = state) do
    # Check if we have enough running jobs
    case start_pending_jobs(pending, running, max_running) do
      {[], _, _} ->
        {:noreply, state}
      {_tasks, now_pending, now_running} ->
        {:noreply, %{state | pending: now_pending, running: now_running}}
    end
  end

  # Handle graceful stop / shutdown
  @impl true
  def handle_call(:stop, _from, %{ pending: [], running: running } = state) when map_size(running) == 0 do
    IO.puts "Shutting down job queue now as no pending jobs are left..."
    {:stop, :normal, state}
  end
  def handle_call(:stop, from, %{ requested_stop: requested_stop } = state) do
    IO.puts "Shutting down job queue once all pending jobs are completed..."
    {:noreply, %{state | requested_stop: [from | requested_stop]}}
  end


  ####################
  # Helper Functions
  ####################

  # Starts any pending jobs in the queue.
  @spec start_pending_jobs(pending, running, non_neg_integer()) :: {list({reference(), Job.t()}), pending, running}
  defp start_pending_jobs(pending, running, max_running) when is_map(running) do
    running_count = map_size(running)
    if running_count < max_running do
      # calculate how many jobs to start
      start_how_many = max_running - running_count
      # split from the end of the pending list
      {jobs, remaining} = pending |> Enum.reverse() |> Enum.split(start_how_many)
      # start the jobs, keeping each `task.ref` as a key-value pair for easier error handling
      tasks = jobs |> Enum.map(&{start_job(&1).ref, &1})
      {tasks, Enum.reverse(remaining), Enum.into(tasks, running)}
    else
      {[], pending, running}
    end
  end

  # Starts a new task in the background for a job.
  @spec start_job(Job.t()) :: Task.t()
  defp start_job(job) do
    Task.Supervisor.async_nolink(Codingtest.TaskSupervisor, fn -> Job.do_job(job) end)
  end

end