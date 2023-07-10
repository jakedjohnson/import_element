defmodule ImportElement.Repo.Migrations.AddReadyToPaymentDetails do
  use Ecto.Migration

  def change do
    alter table(:payment_details) do
      add :ready, :boolean, default: false
    end
  end
end
