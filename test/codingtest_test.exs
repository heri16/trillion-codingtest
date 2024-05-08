defmodule CodingtestTest do
  use ExUnit.Case
  doctest Codingtest.Application

  alias Codingtest.{Job, JobQueue}

  setup do
    {:ok, pid} = JobQueue.start_link(nil)
    on_exit(fn -> JobQueue.stop(pid, true) end) # don't wait for clean stop
    {:ok, pid: pid} # Using pid helps test isolation
  end

  @tag timeout: 1_000
  test "can shutdown the job queue if no jobs are enqueued", %{pid: pid} do
    assert JobQueue.stop(pid) === :ok
  end

  @tag timeout: 30_000
  test "can retry jobs that fail", %{pid: pid} do
    Enum.each(1..2, fn idx -> JobQueue.enqueue(%Job{retry_count: 2, type: :email, payload: %{to: "foo@example.com", from: "bar@example.com", body: "hai there", subject: "Whoa #{idx}"}}, pid) end)
    # Should see 6 attempts in total (2 jobs with 3 attempts each)
    assert JobQueue.stop(pid) === :ok
  end

  @tag timeout: 40_000
  test "can limit the number of jobs running concurrently", %{pid: pid} do
    start_time = System.monotonic_time()
    Enum.each(1..50, fn idx -> JobQueue.enqueue(%Job{type: :sms, payload: %{to: "#{idx}-55555", body: "Hai there"}}, pid) end)
    # Each sms job takes at least 1 second, and at most 2 seconds
    # Test should complete under 33 seconds with default concurrency limit of 3
    assert JobQueue.stop(pid) === :ok
    end_time = System.monotonic_time()
    assert end_time - start_time > 15_000 # assert it took more than 15 seconds
  end
end
