defmodule Cardian.Api.Images do
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

  defp available?(image_url) when is_binary(image_url) do
    image_url
    |> then(&Finch.build(:head, &1))
    |> Finch.request(MyFinch)
    |> then(fn res ->
      case res do
        {:ok, %{status: status}} ->
          status == 200

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
    "https://storage.googleapis.com/ygoprodeck.com/pics_artgame/#{card_id}.jpg"
    |> URI.encode()
  end

  defp remote_image_url(card_id) when is_binary(card_id) do
    "https://storage.googleapis.com/ygoprodeck.com/pics/#{card_id}.jpg"
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

    "https://imaginary.lain.dev/pipeline?url=https://storage.googleapis.com/ygoprodeck.com/pics/#{card_id}.jpg&operations=#{pipeline}"
    |> URI.encode()
  end
end
