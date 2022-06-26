defmodule Purple.Finance.PaymentMethod do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payment_methods" do
    field :name, :string

    has_many :transactions, Purple.Finance.Transaction

    timestamps()
  end

  def changeset(payment_method, attrs) do
    payment_method
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name, message: "already exists")
  end
end
