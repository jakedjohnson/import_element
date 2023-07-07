defmodule ImportElement.Repo.Migrations.AddPaymentDetailsTable do
  use Ecto.Migration

  def change do
    create table(:payment_details) do
      add :import_request_id, references(:import_requests), null: false
      add :source_id, :integer
      add :destination_id, :integer
      add :method_id, :string
      add :data, :jsonb

      timestamps()
    end

    create index(:payment_details, [:import_request_id, :source_id, :destination_id])
  end
end
