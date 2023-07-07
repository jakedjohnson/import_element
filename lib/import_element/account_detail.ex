defmodule ImportElement.AccountDetail do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias ImportElement.Repo

  schema "account_details" do
    field :uid, :string
    field :type, :string
    field :method_id, :string
    field :data, :map

    belongs_to :import_request, ImportElement.ImportRequest
    belongs_to :entity_detail, ImportElement.EntityDetail

    has_many :outgoing_payments,
             ImportElement.PaymentDetail,
             foreign_key: :source_id

    has_many :incoming_payments,
             ImportElement.PaymentDetail,
             foreign_key: :destination_id

    timestamps()
  end

  def changeset(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(account_details, attrs) do
    account_details
    |> cast(attrs, [:uid, :type, :data, :import_request_id, :entity_detail_id])
  end
end
