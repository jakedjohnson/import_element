defmodule ImportElement.ImportRequest do
  use Ecto.Schema
  import Ecto.Changeset

  alias ImportElement.{EntityDetail, Repo}

  schema "import_requests" do
    field :status, :string, default: "ready"
    field :file, :string

    has_many :entity_details, EntityDetail

    timestamps()
  end

  def changeset(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(import_request, attrs) do
    import_request
    |> cast(attrs, [:status, :file])
    |> validate_required([:file])
  end

  def create(attrs) do
    {:ok, import_request} =
      attrs
      |> changeset()
      |> Repo.insert()

    import_request
  end

  def update(import_request, attrs) do
    {:ok, import_request} =
      import_request
      |> changeset(attrs)
      |> Repo.update()

    import_request
  end
end
