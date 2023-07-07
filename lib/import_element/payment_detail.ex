defmodule ImportElement.PaymentDetail do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias ImportElement.Repo

  schema "payment_details" do
    field :method_id, :string
    field :data, :map

    belongs_to :import_request, ImportElement.ImportRequest
    belongs_to :source, ImportElement.AccountDetail
    belongs_to :destination, ImportElement.AccountDetail

    timestamps()
  end

  def changeset(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(account_details, attrs) do
    account_details
    |> cast(attrs, [
      :method_id,
      :data,
      :import_request_id,
      :source_id,
      :destination_id
    ])
  end
end
