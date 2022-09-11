defmodule Purple.Maint do
  import Ecto.Query
  alias Purple.Repo
  alias Purple.Board.Item

  @moduledoc """
  Module for maintenance tasks.
  """

  def set_item_active_at do
    items = Item |> order_by(:id) |> Repo.all()

    Enum.each(
      items,
      fn item ->
        item = Repo.preload(item, :entries)
        max_timestamp = Enum.max([item.updated_at] ++ Enum.map(item.entries, & &1.updated_at))
        IO.inspect("item #{item.id} max timestamp is #{max_timestamp}")

        Item
        |> where([i], i.id == ^item.id)
        |> Repo.update_all(set: [last_active_at: max_timestamp])
      end
    )
  end
end
