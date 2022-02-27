defmodule Petaller.Activities.Run do
  use Ecto.Schema
  import Ecto.Changeset

  schema "runs" do
    field :description, :string
    field :miles, :float
    field :seconds, :integer

    timestamps()
  end

  @doc false
  def changeset(run, attrs) do
    run
    |> cast(attrs, [:miles, :seconds, :description])
    |> validate_required([:miles, :seconds, :description])
  end
end
