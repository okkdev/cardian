defmodule Cardian.Api.Ygoprodeck do
  alias Cardian.Struct.Card

  @url "https://db.ygoprodeck.com/api/v7/cardinfo.php"

  def get_all_cards do
    Req.request(url: @url, params: [format: "genesys", misc: "yes"])
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
    types = resp["type"] |> String.trim_trailing("Monster") |> String.split(" ", trim: true)

    id = resp["id"] |> Integer.to_string() |> String.pad_leading(8, "0")

    %Card{
      id: id,
      type: parse_type(resp["type"]),
      race: resp["race"],
      monster_type: parse_monster_type(resp["frameType"]),
      monster_types: types,
      attribute: resp["attribute"],
      level: resp["level"] || resp["linkval"],
      name: resp["name"],
      description: description,
      pendulum_effect: pendulum_effect,
      atk: resp["atk"],
      def: resp["def"],
      scale: resp["scale"],
      arrows: parse_link_arrows(resp["linkmarkers"]),
      status_tcg: @status_mapping[resp["banlist_info"]["ban_tcg"]],
      status_ocg: @status_mapping[resp["banlist_info"]["ban_ocg"]],
      status_goat: @status_mapping[resp["banlist_info"]["ban_goat"]],
      genesys_points: Enum.at(resp["misc_info"], 0, %{})["genesys_points"] || 0,
      url: get_card_link(id),
      sets_paper: get_sets(resp["card_sets"])
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
      String.contains?(type, "skill") -> :skill
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

  defp parse_monster_type(type) do
    case type |> String.downcase() |> String.trim_trailing("_pendulum") do
      "synchro" -> :synchro
      "effect" -> :effect
      "normal" -> :normal
      "xyz" -> :xyz
      "fusion" -> :fusion
      "ritual" -> :ritual
      "link" -> :link
      _ -> nil
    end
  end

  defp get_sets(sets) when is_list(sets) do
    sets
    |> Enum.map(&(&1["set_code"] |> String.split("-") |> Enum.at(0, &1["set_code"])))
    |> Enum.uniq()
  end

  defp get_sets(_), do: nil

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
