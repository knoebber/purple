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
        put_change(changeset, :seconds, if(seconds <= 0, do: nil, else: seconds))

      _ ->
        changeset
    end
  end

  defp set_default_date(changeset) do
    if get_field(changeset, :date) do
      changeset
    else
      put_change(changeset, :date, Purple.Date.local_date())
    end
  end

  defp is_positive_number(i) do
    is_number(i) and i > 0
  end

  def format_pace(%__MODULE__{miles: miles, seconds: seconds} = run) do
    if is_positive_number(miles) and is_positive_number(seconds) do
      seconds_per_mile = floor(run.seconds / run.miles)
      minutes_per_mile = div(seconds_per_mile, 60)
      minute_seconds_per_mile = rem(seconds_per_mile, 60)

      String.replace_prefix(
        format_duration(%__MODULE__{
          hours: 0,
          minutes: minutes_per_mile,
          minute_seconds: minute_seconds_per_mile
        }),
        "00:",
        ""
      )
    else
      "N/A"
    end
  end

  def format_duration(%__MODULE__{hours: hours, minutes: minutes, minute_seconds: seconds} = run) do
    if is_number(hours) and
         is_number(minutes) and
         is_number(seconds) and
         hours + minutes + seconds > 0 do
      Enum.map_join(
        [hours, minutes, seconds],
        ":",
        &(&1 |> Integer.to_string() |> String.pad_leading(2, "0"))
      )
    else
      "N/A"
    end
  end

  def changeset(%__MODULE__{} = run, attrs) do
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
