defmodule ImportElement.Repo.Migrations.AddImportedAtToPaymentDetails do
  use Ecto.Migration

  def change do
    alter table(:payment_details) do
      add :imported_at, :utc_datetime
    end
  end
end
