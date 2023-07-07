defmodule ImportElement.Repo.Migrations.AddAccountDetailsTable do
  use Ecto.Migration

  def change do
    create table(:account_details) do
      add :import_request_id, references(:import_requests), null: false
      add :entity_detail_id, references(:entity_details)
      add :uid, :string, null: false
      add :type, :string, null: false
      add :method_id, :string
      add :data, :jsonb

      timestamps()
    end

    create unique_index(:account_details, [:entity_detail_id, :uid, :type])
  end
end
