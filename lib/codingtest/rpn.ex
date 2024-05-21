defmodule CodingTest.RPN do
  @moduledoc """
  A simple RPN calculator.

  Challenge:
  Create an RPN calculator (integer only).
  RPN is a different syntax for a calculator where you work left to right applying operations until a single value is resolved.
  """

  @doc """
  Evaluates an RPN expression.

  ## Examples

      iex> CodingTest.RPN.eval("2 3 +")
      5

      iex> CodingTest.RPN.eval("3 5 7 + - 5 *")
      -45

      iex> CodingTest.RPN.eval("2 3 + 4 5 - +")
      4

      iex> CodingTest.RPN.eval("-3 abs 5 +")
      8

      iex> CodingTest.RPN.eval("2 3 -4 sum")
      1

      iex> CodingTest.RPN.eval("2 3 -4 sum 7 *")
      7
  """
  def eval(input) when is_binary(input) do
    input
    |> String.split()
    |> Enum.reduce([], fn token, acc ->
      case Integer.parse(token) do
        {num, ""} -> [num | acc]
        {_num, _rem} -> raise "Invalid integer"
        :error ->
          case { token, acc } do
            {"abs", [left | rest]} -> [abs(left) | rest]
            {"sum", all} -> [Enum.sum(all)]
            {"+", [right, left | rest]} -> [left + right | rest]
            {"-", [right, left | rest]} -> [left - right | rest]
            {"*", [right, left | rest]} -> [left * right | rest]
            {"/", [right, left | rest]} -> [div(left, right) | rest]
            _ -> raise "Invalid expression"
          end
      end
    end)
    |> (fn
      [result | []] -> result
      _ -> raise "Incomplete expression"
    end).()
  end

  def eval_without_enum(input) when is_binary(input) do
    eval(String.split(input), [])
  end
  def eval_without_enum(tokens) when is_list(tokens) do
    eval(tokens, [])
  end

  def eval([], [result | []]), do: result
  def eval([], _acc), do: raise "Incomplete expression"
  def eval([token | tail], acc) do
    case Integer.parse(token) do
      {num, ""} -> eval(tail, [num | acc])
      {_num, _rem} -> raise "Invalid integer"
      :error ->
        case {token, acc} do
          {"abs", [left | rest]} -> eval(tail, [abs(left) | rest])
          {"sum", all} -> eval(tail, [sum(all)])
          {operator, [right, left | rest]} ->
            num = op(operator, left, right)
            eval(tail, [num | rest])
          _ -> raise "Invalid expression"
        end
    end
  end

  def op("+", left, right), do: left + right
  def op("-", left, right), do: left - right
  def op("*", left, right), do: left * right
  def op("/", left, right), do: div(left, right)

  def sum(list), do: sum(list, 0)
  def sum([], acc), do: acc
  def sum([h | t], acc), do: sum(t, acc + h)
end
