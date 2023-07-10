defmodule ImportElement.MethodApi.Merchant do
  def find(%{"metadata" => %{"plaid_id" => plaid_id}}) do
    {:ok, response} =
      ImportElement.MethodApi.Client.get(
        "/merchants",
        [],
        params: %{"provider_id.plaid" => plaid_id}
      )

    response.body[:data]
  end
end
