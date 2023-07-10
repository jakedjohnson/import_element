defmodule ImportElement.MethodApi.Entity do
  def create(entity_params) do
    {:ok, response} =
      ImportElement.MethodApi.Client.post(
        "/entities",
        entity_params,
        [{"Content-Type", "application/json"}]
      )

    response.body[:data]
  end

  def format_params(%{"individual" => individual_params} = params) do
    date =
      individual_params["dob"]
      |> String.split("-")
      |> Enum.chunk_every(2)
      |> Enum.reverse()
      |> List.flatten()
      |> Enum.join("-")

    individual_params = Map.put(individual_params, "dob", date)
    individual_params = Map.put(individual_params, "phone", "+15121231111")
    params = Map.put(params, "individual", individual_params)
    Poison.encode!(params)
  end

  def format_params(%{"corporation" => _, "address" => address_params} = params) do
    iowa_zip = "52753"
    address_params = Map.put(address_params, "zip", iowa_zip)
    params = Map.put(params, "address", address_params)
    Poison.encode!(params)
  end
end
