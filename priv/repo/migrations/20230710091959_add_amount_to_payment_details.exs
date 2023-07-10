defmodule ImportElement.Repo.Migrations.AddAmountToPaymentDetails do
  use Ecto.Migration

  def change do
    alter table(:payment_details) do
      add :amount, :integer
    end
  end
end
