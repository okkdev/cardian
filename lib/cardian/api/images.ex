defmodule Cardian.Api.Images do
  # Get OCG art url
  def get_image_url(%{id: card_id, ocg: true}) do
    if ocg_available?(card_id) do
      {:ok, image_url(card_id <> "_ocg")}
    else
      {:error, "OCG art not found for this card"}
    end
  end

  def get_image_url(%{id: card_id, monster_types: types}) do
    if image_url(card_id) |> available?() do
      {:ok, image_url(card_id)}
    else
      if remote_art_url(card_id) |> available?() do
        {:ok, remote_art_url(card_id)}
      else
        if remote_image_url(card_id) |> available?() do
          {:ok, remote_imaginary_url(card_id, types)}
        else
          {:error, "Card image not found"}
        end
      end
    end
  end

  def ocg_available?(card_id) do
    image_url(card_id <> "_ocg") |> available?()
  end

  defp available?(image_url) when is_binary(image_url) do
    image_url
    |> then(&Req.request(method: :head, url: &1))
    |> then(fn res ->
      case res do
        {:ok, %{status: 200}} ->
          true

        _ ->
          false
      end
    end)
  end

  defp image_url(card_id) when is_binary(card_id) do
    "https://s3.lain.dev/ygo/#{card_id}.webp"
    |> URI.encode()
  end

  defp remote_art_url(card_id) when is_binary(card_id) do
    "https://images.ygoprodeck.com/images/cards_cropped/#{card_id}.jpg"
    |> URI.encode()
  end

  defp remote_image_url(card_id) when is_binary(card_id) do
    "https://images.ygoprodeck.com/images/cards/#{card_id}.jpg"
    |> URI.encode()
  end

  defp remote_imaginary_url(card_id, types) when is_binary(card_id) do
    pipeline =
      cond do
        Enum.member?(types, "Pendulum") ->
          [
            %{
              operation: "resize",
              params: %{
                width: 590,
                force: true
              }
            },
            %{
              operation: "extract",
              params: %{
                top: 155,
                left: 40,
                areawidth: 510,
                areaheight: 380
              }
            },
            %{
              operation: "convert",
              params: %{
                type: "webp"
              }
            }
          ]

        true ->
          [
            %{
              operation: "resize",
              params: %{
                width: 590,
                force: true
              }
            },
            %{
              operation: "extract",
              params: %{
                top: 155,
                left: 70,
                areawidth: 450,
                areaheight: 450
              }
            },
            %{
              operation: "convert",
              params: %{
                type: "webp"
              }
            }
          ]
      end
      |> Jason.encode!()

    "https://imaginary.lain.dev/pipeline?url=https://images.ygoprodeck.com/images/cards/#{card_id}.jpg&operations=#{pipeline}"
    |> URI.encode()
  end
end
