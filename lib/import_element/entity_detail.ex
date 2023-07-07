defmodule ImportElement.EntityDetail do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias ImportElement.Repo

  schema "entity_details" do
    field :uid, :string
    field :type, :string
    field :method_id, :string
    field :data, :map

    belongs_to :import_request, ImportElement.ImportRequest
    has_many :account_details, ImportElement.AccountDetail

    timestamps()
  end

  def changeset(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(entity_details, attrs) do
    entity_details
    |> cast(attrs, [:type, :method_id, :uid, :import_request_id, :data])
    |> validate_required([:uid, :type])
  end

  def all_for_import_request(import_request_id) do
    __MODULE__
    |> where(import_request_id: ^import_request_id)
    |> Repo.all()
  end

  def corporation_count(import_request_id) do
    query = __MODULE__ |> where(import_request_id: ^import_request_id, type: "corporation")
    Repo.aggregate(query, :count, :id)
  end

  def individual_count(import_request_id) do
    query = __MODULE__ |> where(import_request_id: ^import_request_id, type: "individual")
    Repo.aggregate(query, :count, :id)
  end
end
