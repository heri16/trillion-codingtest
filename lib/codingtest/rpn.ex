defmodule CodingTest.RPN do
  @moduledoc """
  A simple RPN calculator.
  """

  @doc """
  Evaluates an RPN expression.

  ## Examples

      iex> CodingTest.RPN.eval("1 2 + 3 *")
      9

      iex> CodingTest.RPN.eval("2 3 + 4 *")
      14

      iex> CodingTest.RPN.eval("2 3 + 4 * 5 /")
      0.8
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
