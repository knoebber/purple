defmodule Purple.TransactionParser do
  @doc """
  Parses a transaction from content
  """
  @callback parse(String.t) :: {:ok, Purple.Finance.Transaction} | {:error, String.t}
end
