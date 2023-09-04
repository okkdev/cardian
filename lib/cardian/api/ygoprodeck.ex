defmodule Cardian.Api.Ygoprodeck do
  alias Cardian.Struct.Card

  @url "https://db.ygoprodeck.com/api/v7/cardinfo.php"

  def get_all_cards do
    @url
    |> Req.request()
    |> handle_response()
    |> Task.async_stream(&cast_card/1)
    |> Stream.map(fn {:ok, card} -> card end)
    |> Enum.to_list()
  end

  defp cast_card(resp) do
    {pendulum_effect, description} = parse_effects(resp["description"])

    %Card{
      id: resp["konamiID"],
      type: get_card_type(resp["type"]),
      race: resp["race"],
      monster_type: get_monster_type(resp["monsterType"]),
      monster_types: resp["monsterType"],
      attribute: resp["attribute"],
      level: resp["level"] || resp["linkRating"],
      name: resp["name"],
      description: description,
      pendulum_effect: pendulum_effect,
      atk: resp["atk"],
      def: resp["def"],
      scale: resp["scale"],
      arrows: parse_link_arrows(resp["linkArrows"]),
      status: @status_mapping[resp["banStatus"]] || "Unlimited",
      rarity: @rarity_mapping[resp["rarity"]],
      image_url: get_image(resp["_id"]),
      url: get_card_link(resp["name"]),
      sets: Enum.map(resp["obtain"], & &1["source"]["_id"])
    }
  end

  defp handle_response(resp) do
    case resp do
      {:ok, res} ->
        res.body["data"]

      {:error, reason} ->
        raise(inspect(reason))
    end
  end
end
