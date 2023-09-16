defmodule Purple.BoardFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Purple.Board` context.
  """

  alias Purple.Repo
  alias Purple.Board
  import Ecto.Query

  def reset_item_timestamps(%Board.Item{id: id} = item) when is_integer(id) do
    past_timestamp = NaiveDateTime.new!(2022, 09, 11, 12, 53, 0)

    Board.Item
    |> where([i], i.id == ^item.id)
    |> Repo.update_all(
      set: [
        inserted_at: past_timestamp,
        last_active_at: past_timestamp,
        updated_at: past_timestamp
      ]
    )
  end

  def valid_item_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      description: "Test Item 🌞",
      last_active_at: Purple.Date.utc_now(),
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

    {:ok, _} =
      Board.create_item_entry(
        valid_entry_attributes(Map.get(attrs, :entry, %{})),
        item.id
      )

    reset_item_timestamps(item)
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

  def user_board_fixture(attrs \\ %{}) do
    [tag | _] = item_fixture().tags
    {user, attrs} = Map.pop(attrs, "user", Purple.AccountsFixtures.user_fixture())

    attrs =
      Enum.into(attrs, %{
        "name" => "Purple Board (fixture default)",
        "show_done" => true,
        "tags" => [tag]
      })

    {:ok, %Board.UserBoard{} = ub} = Board.create_user_board(attrs, user.id)

    ub
  end
end
