defmodule Purple.Activities.Run do
  use Ecto.Schema
  import Ecto.Changeset

  schema "runs" do
    field :description, :string, default: ""
    field :miles, :float, default: 6.0
    field :seconds, :integer, default: nil
    field :date, :date

    field :hours, :integer, default: 0, virtual: true
    field :minutes, :integer, default: 0, virtual: true
    field :minute_seconds, :integer, default: 0, virtual: true

    timestamps()

    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.RunTag
  end

  defp calculate_seconds(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        {_, hours} = fetch_field(changeset, :hours)
        {_, minutes} = fetch_field(changeset, :minutes)
        {_, minute_seconds} = fetch_field(changeset, :minute_seconds)

        seconds = hours * 3600 + minutes * 60 + minute_seconds

        if seconds <= 0 do
          put_change(changeset, :seconds, nil)
        else
          changeset
          |> delete_change(:hours)
          |> delete_change(:minutes)
          |> delete_change(:minute_seconds)
          |> put_change(:seconds, seconds)
        end

      _ ->
        changeset
    end
  end

  defp set_default_date(changeset) do
    if get_field(changeset, :date) do
      changeset
    else
      put_change(
        changeset,
        :date,
        DateTime.utc_now()
        |> DateTime.shift_zone!(Application.get_env(:purple, :default_tz))
        |> DateTime.to_date()
      )
    end
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [:miles, :hours, :minutes, :minute_seconds, :description, :date])
    |> validate_required([:miles])
    |> validate_number(:miles, greater_than: 0)
    |> validate_number(:hours, greater_than: -1)
    |> validate_number(:minutes, greater_than: -1, less_than: 60)
    |> validate_number(:minute_seconds, greater_than: -1, less_than: 60)
    |> calculate_seconds
    |> set_default_date
  end
end
