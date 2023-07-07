defmodule ImportElement.Repo.Migrations.AddEntityDetailsTable do
  use Ecto.Migration

  def change do
    create table(:entity_details) do
      add :import_request_id, references(:import_requests), null: false
      add :uid, :string, null: false
      add :type, :string, null: false
      add :method_id, :string
      add :data, :jsonb

      timestamps()
    end

    create unique_index(:entity_details, [:import_request_id, :uid, :type])
  end
end
