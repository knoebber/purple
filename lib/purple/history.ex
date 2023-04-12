defmodule Purple.History do
  alias Purple.History.ViewedUrl
  alias Purple.Repo
  import Ecto.Query

  def max_num_user_urls, do: 15

  def save_url(user_id, url) when is_integer(user_id) and is_binary(url) do
    {:ok, viewed_urls} =
      Repo.transaction(fn ->
        existing_records =
          ViewedUrl
          |> where([vu], vu.user_id == ^user_id)
          |> order_by(desc: :freshness)
          |> Repo.all()

        next_freshness =
          case existing_records do
            [] -> 0
            [first | _] -> first.freshness + 1
          end

        existing_record = Enum.find(existing_records, &(&1.url == url))

        fresh_record =
          case existing_record do
            %ViewedUrl{} = vu ->
              vu
              |> Ecto.Changeset.change(freshness: next_freshness)
              |> Repo.update!()

            nil ->
              Repo.insert!(%ViewedUrl{user_id: user_id, url: url, freshness: next_freshness})
          end

        was_record_inserted = is_nil(existing_record)

        if was_record_inserted do
          existing_records
          |> Enum.with_index()
          |> Enum.reduce([fresh_record], fn {record, index}, result ->
            if index >= max_num_user_urls() - 1 do
              Repo.delete!(record)
              result
            else
              [record | result]
            end
          end)
        else
          [fresh_record | List.delete(existing_records, existing_record)]
        end
      end)

    # Viewed urls order should stay stable as freshness changes.
    Enum.sort(viewed_urls, &(&1.id >= &2.id))
  end

  def list_user_viewed_urls(user_id) when is_integer(user_id) do
    ViewedUrl
    |> where([vu], vu.user_id == ^user_id)
    |> order_by(desc: :id)
    |> Repo.all()
  end
end
