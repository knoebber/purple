defmodule Purple do
  @moduledoc """
  Misc functions for purple
  """
  def parse_int!(s) do
    {int, _} = Integer.parse(s)
    int
  end

  def parse_int(s, default) when is_binary(s) do
    case Integer.parse(s) do
      {n, ""} -> n
      _ -> default
    end
  end
 
  def int_from_map(params, key) do
    case Integer.parse(Map.get(params, key, "")) do
      {0, _} -> nil
      {id, ""} -> id
      _ -> nil
    end
  end

  def scan_4_digits(string) do
    case Regex.run(~r/\d{4}/, string) do
      [four] -> four
      _ -> nil
    end
  end

  def titleize(string) when is_binary(string) do
    string
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  def titleize(atom) when is_atom(atom) do
    titleize(Atom.to_string(atom))
  end

  def maybe_list(list) do
    if is_list(list) do
      list
    else
      []
    end
  end

  def drop_falsey_values(map) when is_map(map) do
    Map.reject(map, fn {_, val} ->
      is_nil(val) or val == "" or val == 0 or val == false or val == []
    end)
  end
end
