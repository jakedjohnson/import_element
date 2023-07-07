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

  def count(import_request_id) do
    query = __MODULE__ |> where(import_request_id: ^import_request_id)
    Repo.aggregate(query, :count, :id)
  end

  def total(_import_request_id) do
    34_145_999
  end
end
