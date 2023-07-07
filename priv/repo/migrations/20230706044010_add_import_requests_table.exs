defmodule ImportElement.Repo.Migrations.AddImportRequestsTable do
  use Ecto.Migration

  def change do
    create table(:import_requests) do
      add :file, :string, null: false
      add :status, :string

      timestamps()
    end
  end
end
