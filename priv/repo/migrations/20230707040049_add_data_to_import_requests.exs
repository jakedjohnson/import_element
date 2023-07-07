defmodule ImportElement.Repo.Migrations.AddDataToImportRequests do
  use Ecto.Migration

  def change do
    alter table(:import_requests) do
      add :data, :jsonb
    end
  end
end
