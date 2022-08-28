defmodule Purple.BoardFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Purple.Board` context.
  """

  def valid_item_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      description: "Test Item 🌞",
      priority: 1,
      status: :TODO
    })
  end

  def valid_entry_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      content: "# Test Entry! 😺\n\n#tdd #purple #postgres\n\n#Checkboxes!\n- x one\n- x two",
      is_collapsed: false
    })
  end

  def item_fixture(attrs \\ %{}) do
    {:ok, item} = Purple.Board.save_item(:create_item, %{}, valid_item_attributes(attrs))

    {:ok, entry} =
      Purple.Board.save_item(
        :create_entry,
        %{},
        # Can add an :entry key to attrs to override default entry.
        valid_entry_attributes(Map.get(attrs, :entry, %{})),
        item.id
      )

    Map.put(item, :entries, [entry])
  end

  def entry_fixture(attrs \\ %{}) do
    %{entries: [entry]} = item_fixture()

    if attrs != %{} do
      {:ok, entry} = Purple.Board.save_item(:update_entry, entry, attrs)
      entry
    else
      entry
    end
  end
end
