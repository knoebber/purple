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

  def sync_item_tags() do
    Enum.each(
      Repo.all(Purple.Board.Item),
      fn item ->
        Purple.Tags.sync_tags(item.id, :item)
      end
    )
  end

  def fix_file_size() do
    Enum.each(Repo.all(Purple.Uploads.FileRef), fn file_ref ->
      file_ref
      |> Purple.Uploads.FileRef.changeset(%{
        byte_size: File.stat!(Purple.Uploads.get_full_upload_path(file_ref)).size
      })
      |> IO.inspect(label: "changeset")
      |> Repo.update!()
    end)
  end

  def add_merchant_names do
    merchants = Repo.all(Purple.Finance.Merchant) |> Repo.preload(:names)

    Enum.each(merchants, fn m ->
      if m.names == [] do
        Repo.insert!(%Purple.Finance.MerchantName{
          name: m.name,
          is_primary: true,
          merchant_id: m.id
        })
        |> inspect(label: "new merchant name")
      end
    end)
  end

  def update_transaction_merchant_ref do
    transactions = Repo.all(Purple.Finance.Transaction)

    Enum.each(transactions, fn t ->
      if is_nil(t.merchant_name_id) do
        m = Purple.Finance.get_merchant!(t.merchant_id)

        Purple.Finance.Transaction
        |> where([t], t.id == ^t.id)
        |> Repo.update_all(set: [merchant_name_id: hd(m.names).id])
      end
    end)
  end
end
