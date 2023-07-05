defmodule ImportElement.Repo do
  use Ecto.Repo,
    otp_app: :import_element,
    adapter: Ecto.Adapters.Postgres
end
