defmodule Purple.KeyValue do
  @doc """
  Simple key value store that uses Erlang Term Storage - :ets.
  """

  use GenServer
  @name __MODULE__

  def start_link(_), do: GenServer.start_link(@name, [], name: @name)

  def delete(key) do
    GenServer.call(@name, {:delete, key})
  end

  def get(key) do
    case lookup(key) do
      [{^key, value}] -> value
      [] -> nil
    end
  end

  def insert(key, value) do
    GenServer.call(@name, {:insert, {key, value}})
  end

  def lookup(key) do
    :ets.lookup(@name, key)
  end

  @impl GenServer
  def handle_call({:delete, key}, _, state) do
    :ets.delete(@name, key)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:insert, {key, value}}, _, state) do
    :ets.insert(@name, {key, value})
    {:reply, :ok, state}
  end

  @impl GenServer
  def init(_) do
    :ets.new(@name, [:set, :protected, :named_table, read_concurrency: true])
    {:ok, %{}}
  end
end
