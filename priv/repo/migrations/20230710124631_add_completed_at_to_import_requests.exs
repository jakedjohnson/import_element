defmodule ImportElement.Repo.Migrations.AddCompletedAtToImportRequests do
  use Ecto.Migration

  def change do
    alter table(:import_requests) do
      add :completed_at, :utc_datetime
    end
  end
end
