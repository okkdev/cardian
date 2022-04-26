defmodule Cardian.Api.Images do
  def get_image(card_id) when is_binary(card_id) do
    if available?(card_id) do
      {:ok, image_url(card_id)}
    else
      {:error, "Card image not found"}
    end
  end

  def available?(card_id) when is_binary(card_id) do
    image_url(card_id)
    |> then(&Finch.build(:head, &1))
    |> Finch.request(MyFinch)
    |> then(fn {:ok, %{status: status}} -> status == 200 end)
  end

  defp image_url(card_id) when is_binary(card_id) do
    "https://s3.lain.dev/ygo/#{card_id}.webp"
    |> URI.encode()
  end
end
