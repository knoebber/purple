defmodule Petaller.Repo.Migrations.MakeEntryFieldsNonNull do
  use Ecto.Migration

  def change do
    alter table("item_entries") do
      modify(:content, :text, null: false, default: "")
      modify(:item_id, :integer, null: false)
      modify(:is_collapsed, :boolean, default: false, null: false)
      modify(:sort_order, :integer, null: false)
    end
  end
end
