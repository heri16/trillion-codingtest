defmodule Codingtest.Job do
  @derive {Jason.Encoder, only: [:type, :payload, :retry_count]}
  defstruct type: :unknown, payload: %{}, retry_count: 3, last_error: nil
  @type t :: %__MODULE__{type: atom, payload: map, retry_count: non_neg_integer, last_error: any}

  @doc """
    Runs the job with a random sleep / delay to simulate real work
  """
  def do_job(%__MODULE__{type: :sms, payload: payload}) do
    IO.puts "Begin: Sending sms with payload #{inspect payload}"
    Process.sleep(Enum.random(1_000..2_000))
    IO.puts "Done: Sent sms with payload #{inspect payload}"
  end
  def do_job(%__MODULE__{type: :email, payload: payload}) do
    IO.puts "Begin: sending email with payload #{inspect payload}"
    Process.sleep(2_000)
    raise "Failed to send email. This is on purpose."
    # IO.puts "Done: Sent email with payload #{inspect payload}"
  end
end
