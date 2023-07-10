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

  def format_params(%{data: data} = payment_detail) do
    money = data |> Map.get("amount") |> Money.parse!()
    data = Map.put(data, "amount", money.amount)
    Map.put(data, "description", "Loan Pmt")
  end
end
