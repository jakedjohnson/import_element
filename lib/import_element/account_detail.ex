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
    field :capable, :boolean

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
    |> cast(attrs, [:uid, :type, :data, :import_request_id, :entity_detail_id, :capable, :method_id])
  end

  def ach_count(import_request_id) do
    query = __MODULE__ |> where(import_request_id: ^import_request_id, type: "ach")
    Repo.aggregate(query, :count, :id)
  end

  def liability_count(import_request_id) do
    query = __MODULE__ |> where(import_request_id: ^import_request_id, type: "liability")
    Repo.aggregate(query, :count, :id)
  end

  def all_for_entities(entity_ids) do
      __MODULE__
      |> where(entity_detail_id: ^entity_ids)
      |> Repo.all()
  end

  def sync_merchant(%{type: "liability", data: %{"liability" => params}} = account_detail, merchant) do
    params = Map.put(params, "mch_id", merchant["mch_id"])
    new_data = Map.put(account_detail.data, "liability", params)

    account_detail
    |> changeset(%{data: new_data})
    |> Repo.update()
  end

  def sync_method_response(account, data) do
    changeset = change(account, %{
      method_id: data["id"],
      capable: check_capability(data)
    })
    Repo.update(changeset)
  end

  def check_capability(%{"type" => "liability", "capabilities" => capabilities}) do
    Enum.member?(capabilities, "payments:receive")
  end

  def check_capability(%{"type" => "ach", "capabilities" => capabilities}) do
    Enum.member?(capabilities, "payments:send")
  end
end
