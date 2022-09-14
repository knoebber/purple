defmodule Purple.Maint do
  alias Purple.Repo
  import Ecto.Query

  @moduledoc """
  Module for maintenance tasks.
  """

  def set_priority() do
    Enum.each(
      Repo.all(Purple.Board.Item),
      fn item ->
        if item.status != :TODO and is_integer(item.priority) do
          Purple.Board.Item
          |> where([i], i.id == ^item.id)
          |> Repo.update_all(set: [priority: nil])
        end
      end
    )
  end
end
