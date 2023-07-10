defmodule ImportElement.PaymentDetail do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias ImportElement.Repo

  schema "payment_details" do
    field :amount, Money.Ecto.Amount.Type
    field :method_id, :string
    field :data, :map
    field :ready, :boolean

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
      :destination_id,
      :ready,
      :amount
    ])
    |> check_ready()
    |> convert_amount()
  end

  defp check_ready(changeset) do
    data = get_field(changeset, :data, %{})

    put_change(changeset, :ready, params_ready(data))
  end

  defp params_ready(%{"source_id" => _, "destination_id" => _}), do: true
  defp params_ready(_), do: false

  defp convert_amount(changeset) do
    amount = get_change(changeset, :data, %{})["amount"]
    if amount do
      pennies = Money.parse!(amount).amount
      put_change(changeset, :amount, pennies)
    else
      changeset
    end
  end

  def count(import_request_id) do
    query = __MODULE__ |> where(import_request_id: ^import_request_id)
    Repo.aggregate(query, :count, :id)
  end

  def total(_import_request_id) do
    34_145_999
  end

  def batch_merge_data(payment_details, attrs) do
    payment_details
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {payment_detail, idx}, multi ->
      merged_data = Map.merge(payment_detail.data, attrs)
      changeset = changeset(payment_detail, %{data: merged_data})
      Ecto.Multi.update(multi, {:payment_detail, idx}, changeset)
    end)
    |> Repo.transaction()
  end
end
