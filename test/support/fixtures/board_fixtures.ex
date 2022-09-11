defmodule Purple.BoardFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Purple.Board` context.
  """

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
    {:ok, item} = Purple.Board.create_item(valid_item_attributes(attrs))

    {:ok, _} =
      Purple.Board.create_item_entry(
        valid_entry_attributes(Map.get(attrs, :entry, %{})),
        item.id
      )

    Purple.Board.get_item!(item.id, :entries, :tags)
  end

  def entry_fixture(attrs \\ %{}) do
    %{entries: [entry]} = item_fixture()

    if attrs != %{} do
      {:ok, entry} = Purple.Board.update_item_entry(entry, attrs)
      entry
    else
      entry
    end
  end
end
