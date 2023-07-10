defmodule ImportElement.Repo.Migrations.AddReportPathToImportRequests do
  use Ecto.Migration

  def change do
    alter table(:import_requests) do
      add :report_path, :string
      add :uuid, :uuid, null: false
    end
  end
end
