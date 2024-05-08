defmodule CodingtestTest do
  use ExUnit.Case
  doctest Codingtest

  alias Codingtest.{Job, JobQueue}

  setup do
    {:ok, pid} = JobQueue.start_link(nil)
    # on_exit(fn -> JobQueue.stop(pid, true) end) # don't wait for clean stop
    {:ok, pid: pid} # Using pid helps test isolation
  end

  @tag timeout: 30_000
  test "can retry jobs that fail", %{pid: pid} do
    Enum.each(1..3, fn idx -> JobQueue.enqueue(pid, %Job{retry_count: 1, type: :email, payload: %{to: "foo@example.com", from: "bar@example.com", body: "hai there", subject: "Whoa #{idx}"}}) end)
    # Should see 6 attempts in total (3 jobs with 2 attempts each)
    assert JobQueue.stop(pid) === :ok
  end

  @tag timeout: 80_000
  test "can limit the number of jobs running concurrently", %{pid: pid} do
    start_time = System.monotonic_time()
    Enum.each(1..100, fn idx -> JobQueue.enqueue(pid, %Job{type: :sms, payload: %{to: "#{idx}-55555", body: "Hai there"}}) end)
    # Each sms job takes at least 1 second and at most 2 seconds
    # Test should complete under 66 seconds with default concurrency limit of 3
    assert JobQueue.stop(pid) === :ok
    end_time = System.monotonic_time()
    assert end_time - start_time > 30_000 # assert it took more than 30 seconds
  end
end
