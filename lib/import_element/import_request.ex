defmodule ImportElement.ImportRequest do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias ImportElement.Repo

  schema "import_requests" do
    field :status, :string, default: "ready"
    field :file, :string
    field :data, :map
    field :completed_at, :utc_datetime

    has_many :entity_details, ImportElement.EntityDetail
    has_many :account_details, ImportElement.AccountDetail
    has_many :payment_details, ImportElement.PaymentDetail

    timestamps()
  end

  def changeset(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(import_request, attrs) do
    import_request
    |> cast(attrs, [:status, :file, :data, :completed_at])
    |> validate_required([:file])
  end

  def create(attrs) do
    {:ok, import_request} =
      attrs
      |> changeset()
      |> Repo.insert()

    import_request
  end

  def update_request(import_request, attrs) do
    {:ok, import_request} =
      import_request
      |> changeset(attrs)
      |> Repo.update()

    import_request
  end

  def update_request_data(import_request, new_data) do
    original_data = Map.get(import_request, :data) || %{}
    merged_data = Map.merge(original_data, new_data)
    update_request(import_request, %{data: merged_data})
  end

  def find(id) do
    Repo.get!(__MODULE__, id)
  end

  def all() do
    __MODULE__
    |> order_by(desc: :updated_at)
    |> Repo.all()
  end

  def totals(import_request_id) do
    corporation_count = ImportElement.EntityDetail.corporation_count(import_request_id)
    individual_count = ImportElement.EntityDetail.individual_count(import_request_id)
    ach_count = ImportElement.AccountDetail.ach_count(import_request_id)
    liability_count = ImportElement.AccountDetail.liability_count(import_request_id)
    payment_count = ImportElement.PaymentDetail.count(import_request_id)
    payment_total = ImportElement.PaymentDetail.total(import_request_id)
    ready_payment_count = ImportElement.PaymentDetail.ready_count(import_request_id)
    ready_payment_total = ImportElement.PaymentDetail.ready_total(import_request_id)

    %{
      corporation_count: corporation_count,
      individual_count: individual_count,
      ach_count: ach_count,
      liability_count: liability_count,
      payment_count: payment_count,
      payment_total: payment_total |> Money.to_string,
      ready_payment_count: ready_payment_count,
      ready_payment_total: ready_payment_total |> Money.to_string
    }
  end
end
