defmodule Purple.BoardFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Purple.Board` context.
  """

  alias Purple.Repo
  alias Purple.Board
  import Ecto.Query

  def valid_item_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      description: "Test Item 🌞",
      priority: 1,
      last_active_at: Purple.utc_now(),
      status: :TODO
    })
  end

  def valid_entry_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      content:
        "# Entry Fixture! 😺\n\n#tdd #purple #postgres\n+ x fixture checkbox 1\n+ x fixture checkbox2",
      is_collapsed: false
    })
  end

  def item_fixture(attrs \\ %{}) do
    {:ok, item} = Board.create_item(valid_item_attributes(attrs))

    past_timestamp = NaiveDateTime.new!(2022, 09, 11, 12, 53, 0)

    {:ok, _} =
      Board.create_item_entry(
        valid_entry_attributes(Map.get(attrs, :entry, %{})),
        item.id
      )

    Board.Item
    |> where([i], i.id == ^item.id)
    |> Repo.update_all(
      set: [
        inserted_at: past_timestamp,
        last_active_at: past_timestamp,
        updated_at: past_timestamp
      ]
    )

    Board.get_item!(item.id, :entries, :tags)
  end

  def entry_fixture(attrs \\ %{}) do
    %{entries: [entry]} = item_fixture()

    if attrs != %{} do
      {:ok, entry} = Board.update_item_entry(entry, attrs)
      entry
    else
      entry
    end
  end
end
