# Codingtest

Coding test for the TrillionNetwork.com

**Challenge:** Create an async (fire and forget) background work job processing system.

## Running the test

```bash
mix deps.get
mix test --trace
```

## Basic Requirements implemented:

- Specify the type of job
- Specify the job arguments required (specified by the handler)
- Complete the job in the background (async)
- Fire and forget semantics. Submitting to the job queue is sufficient and the job system executes the job.
- Specify the maximum concurrency of the work system (it should not execute an arbitrary number of jobs at the same time)
- Submitting the job to the system does not wait for the job to be executed. (No reply / acknowledgement required when submitting a job)
- Any build up of jobs enqueued, should be enqueued and executed in received order

## Bonus Features implemented:

- Error handling (Supervisors)
- Retry queue (with backoff-delay retry strategy)
- Serializable jobs (Jason)
- Lower latency for Genserver (enqueue job will not have head-of-line blocking)
- Maximum retry attempt count configurable per job
- Graceful shutdown of job queue (clean stop)
- Jobs have random completion time between 1 to 2 secs (to better simulate real world conditions)
- ExUnit test that checks for expected duration (to ensure concurrency is real)

## Notes

This project was generated with `mix new --sup` and then modified to fit the
requirements.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/codingtest>.

