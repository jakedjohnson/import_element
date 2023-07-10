defmodule ImportElement.Repo.Migrations.AddCapableToEntitiesAndAccounts do
  use Ecto.Migration

  def change do
    alter table(:entity_details) do
      add :capable, :boolean, default: false
    end

    alter table(:account_details) do
      add :capable, :boolean, default: false
    end
  end
end
