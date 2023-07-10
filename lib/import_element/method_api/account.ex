defmodule ImportElement.MethodApi.Account do
  def create(account_params) do
    {:ok, response} =
      ImportElement.MethodApi.Client.post(
        "/accounts",
        account_params,
        [{"Content-Type", "application/json"}]
      )

    response.body[:data]
  end

  def format_params(entity, account) do
    account.data
    |> Map.put("holder_id", entity.method_id)
    |> Poison.encode!()
  end
end
