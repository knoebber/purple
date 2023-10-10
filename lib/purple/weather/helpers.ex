defmodule Purple.Weather.Helpers do
  import Ecto.Changeset

  def put_timestamp(%Ecto.Changeset{} = changeset) do
    changeset = validate_number(changeset, :unix_timestamp, greater_than: 1_684_615_665)
    unix_time = get_field(changeset, :unix_timestamp)

    if is_integer(unix_time) do
      put_change(changeset, :timestamp, Purple.Date.unix_to_naive(unix_time))
    else
      changeset
    end
  end
end
