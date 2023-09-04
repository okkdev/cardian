defmodule Cardian.Api.Ygoprodeck do
  alias Cardian.Struct.Card

  @url "https://db.ygoprodeck.com/api/v7/cardinfo.php"

  def get_all_cards do
    Req.request(url: @url)
    |> handle_response()
    |> Task.async_stream(&cast_card/1, ordered: false)
    |> Stream.map(fn {:ok, card} -> card end)
    |> Enum.to_list()
  end

  @status_mapping %{
    "Semi-Limited" => :semilimited,
    "Limited" => :limited,
    "Banned" => :forbidden
  }

  defp cast_card(resp) do
    {pendulum_effect, description} = parse_effects(resp["desc"])
    types = resp["type"] |> String.trim_trailing("Monster") |> String.split(" ")

    %Card{
      id: to_string(resp["id"]),
      type: parse_type(resp["type"]),
      race: resp["race"],
      monster_type: parse_monster_type(types),
      monster_types: types,
      attribute: resp["attribute"],
      level: resp["level"] || resp["linkval"],
      name: resp["name"],
      description: description,
      pendulum_effect: pendulum_effect,
      atk: resp["atk"],
      def: resp["def"],
      scale: resp["scale"],
      arrows: parse_link_arrows(resp["linkArrows"]),
      status_tcg: @status_mapping[resp["banlist_info"]["ban_tcg"]] || "Unlimited",
      status_ocg: @status_mapping[resp["banlist_info"]["ban_ocg"]] || "Unlimited",
      status_goat: @status_mapping[resp["banlist_info"]["ban_goat"]] || "Unlimited",
      url: get_card_link(resp["id"])
    }
  end

  @arrow_mapping %{
    "Top-Left" => "↖️",
    "Top" => "⬆️",
    "Top-Right" => "↗️",
    "Left" => "⬅️",
    "Right" => "➡️",
    "Bottom-Left" => "↙️",
    "Bottom" => "⬇️",
    "Bottom-Right" => "↘️"
  }

  defp parse_link_arrows(arrows) when is_list(arrows) and length(arrows) > 0 do
    arrows
    |> Enum.map_join(&@arrow_mapping[&1])
    # Add invisible character to force mobile to show small emojis
    |> then(&(&1 <> "‎"))
  end

  defp parse_link_arrows(_), do: nil

  defp parse_type(type) do
    type = String.downcase(type)

    cond do
      String.contains?(type, "monster") -> :monster
      String.contains?(type, "spell") -> :spell
      String.contains?(type, "trap") -> :trap
      :otherwise -> nil
    end
  end

  defp parse_effects("[ Pendulum Effect ]" <> description) do
    [pendulum_effect, rest] = String.split(description, ["---", "[ "], parts: 2)
    [_, description] = String.split(rest, "]", parts: 2)

    {
      String.trim(pendulum_effect),
      String.trim(description)
    }
  end

  defp parse_effects(description), do: {nil, description}

  defp parse_monster_type([type | types]) do
    case String.downcase(type) do
      "synchro" -> :synchro
      "effect" -> :effect
      "normal" -> :normal
      "xyz" -> :xyz
      "fusion" -> :fusion
      "ritual" -> :ritual
      "link" -> :link
      # Skip Pendulum and Flip monsters as this is used for color and level name
      "pendulum" -> parse_monster_type(types)
      "flip" -> parse_monster_type(types)
      _ -> nil
    end
  end

  defp get_card_link(card_id) do
    "https://yugipedia.com/wiki/#{card_id}"
    |> URI.encode()
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
