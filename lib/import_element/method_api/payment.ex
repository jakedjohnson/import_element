defmodule ImportElement.MethodApi.Payment do
  def create(payment_params) do
    {:ok, response} =
      ImportElement.MethodApi.Client.post(
        "/payments",
        Poison.encode!(payment_params),
        [{"Content-Type", "application/json"}]
      )

    response.body[:data]
  end

  def format_params(import_request, %{data: data} = payment_detail) do
    metadata = data |> Map.get("metadata")
    money = data |> Map.get("amount") |> Money.parse!()

    metadata = Map.put(metadata, "import_request_uuid", import_request.uuid)
    data = Map.put(data, "metadata", metadata)
    data = Map.put(data, "amount", money.amount)

    Map.put(data, "description", "Loan Pmt")
  end

  def list() do
    {:ok, response} = ImportElement.MethodApi.Client.get("/payments")
    response.body[:data]
  end
end
