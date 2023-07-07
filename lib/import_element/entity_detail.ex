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
end
