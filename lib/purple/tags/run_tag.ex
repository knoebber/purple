defmodule Purple.Tags.RunTag do
  use Ecto.Schema

  schema "run_tags" do
    belongs_to :run, Purple.Activities.Run
    belongs_to :tag, Purple.Tags.Tag

    timestamps(updated_at: false)
  end
end
