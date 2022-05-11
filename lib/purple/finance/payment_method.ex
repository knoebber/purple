defmodule Purple.Finance.PaymentMethod do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payment_method" do
    field :name, :string

    timestamps()
  end

  def changeset(payment_method, attrs) do
    payment_method
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
