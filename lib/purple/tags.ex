defmodule Purple.Tags do
  alias Purple.Repo
  alias Purple.Tags.Tag

  import Ecto.Query

  def extract_tags(content) do
    Regex.scan(~r/#([a-zA-Z0-9]{2,})/, content)
    |> Enum.flat_map(fn [_, match] -> [String.downcase(match)] end)
    |> Enum.uniq()
  end

  def diff_tags([], current_tag_map, result) do
    result ++ for t <- Map.values(current_tag_map), do: {:delete, t}
  end

  def diff_tags([%Tag{} = head | tail], current_tag_map, result) do
    case Map.pop(current_tag_map, head.id) do
      {nil, current_tag_map} -> diff_tags(tail, current_tag_map, result ++ [{:insert, head}])
      {_, current_tag_map} -> diff_tags(tail, current_tag_map, result)
    end
  end

  def diff_tags(current_tags, new_tags) do
    diff_tags(
      new_tags,
      Enum.reduce(
        current_tags,
        %{},
        fn tag = %Tag{}, acc -> Map.put(acc, tag.id, tag) end
      ),
      []
    )
  end

  def get_or_create_tags(names) do
    existing_tag_map =
      Enum.reduce(
        Tag |> where([t], t.name in ^names) |> Repo.all(),
        %{},
        fn %Tag{} = tag, acc -> Map.put(acc, tag.name, tag) end
      )

    Enum.reduce(
      names,
      [],
      fn name, acc ->
        case Tag.changeset(%{name: name}) do
          %{valid?: false} -> acc
          changeset -> acc ++ [changeset]
        end
      end
    )
    |> Enum.map(fn changeset ->
      case Map.get(existing_tag_map, changeset.changes.name) do
        nil -> Repo.insert!(changeset)
        existing -> existing
      end
    end)
  end
end
