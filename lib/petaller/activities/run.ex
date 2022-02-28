defmodule Petaller.Activities.Run do
  use Ecto.Schema
  import Ecto.Changeset

  schema "runs" do
    field :description, :string, default: ""
    field :miles, :float, default: 0.0
    field :seconds, :integer

    field :hours, :integer, default: 0, virtual: true
    field :minutes, :integer, default: 0, virtual: true
    field :minute_seconds, :integer, default: 0, virtual: true

    timestamps()
  end

  defp calculate_seconds(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        {_, hours} = fetch_field(changeset, :hours)
        {_, minutes} = fetch_field(changeset, :minutes)
        {_, minute_seconds} = fetch_field(changeset, :minute_seconds)

        changeset
        |> delete_change(:hours)
        |> delete_change(:minutes)
        |> delete_change(:minute_seconds)
        |> put_change(:seconds, hours * 3600 + minutes * 60 + minute_seconds)

      _ ->
        changeset
    end
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [:miles, :hours, :minutes, :minute_seconds, :description])
    |> validate_required([:miles])
    |> validate_number(:miles, greater_than: 0)
    |> validate_number(:minutes, less_than: 60)
    |> validate_number(:minute_seconds, less_than: 60)
    |> calculate_seconds
    |> validate_number(:seconds, greater_than: 60)
  end
end
