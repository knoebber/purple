defmodule Purple.Finance.PaymentMethod do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payment_methods" do
    field :name, :string

    timestamps()
  end

  def changeset(payment_method, attrs) do
    payment_method
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> update_change(:name, &String.downcase/1)
    |> unique_constraint(:name, message: "already exists")
  end
end
