defmodule Cardian.Builder do
  import Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed

  # %{
  #   "_id" => "60c2b3aaa0e24f2d54a51cec",
  #   "atk" => 1700,
  #   "attribute" => "LIGHT",
  #   "deckTypes" => ["Crusadia", "Cyber Dragon", "Thunder Dragon",
  #    "Dogmatika Nekroz", "Kaiju"],
  #   "def" => 1000,
  #   "description" => "Cannot be Special Summoned. While you control no Set Spells/Traps, neither player can Set Spells/Traps nor activate Spell/Trap Cards that are Set on the field.",
  #   "konamiID" => "13974207",
  #   "level" => 4,
  #   "linkArrows" => [],
  #   "monsterType" => ["Effect"],
  #   "name" => "Denko Sekka",
  #   "obtain" => [
  #     %{
  #       "amount" => 1,
  #       "source" => %{
  #         "_id" => "61eaddc798a43480f06172db",
  #         "name" => "Master Pack"
  #       },
  #       "type" => "sets"
  #     }
  #   ],
  #   "ocgRelease" => "2014-07-19T00:00:00.000Z",
  #   "popRank" => 893,
  #   "race" => "Thunder",
  #   "rarity" => "SR",
  #   "release" => "2022-01-19T06:00:00.000Z",
  #   "tcgRelease" => "2014-11-06T00:00:00.000Z",
  #   "type" => "Monster"
  # }

  def build_card_message(card) do
    embed =
      %Embed{}
      |> put_title(card["name"])

    %{
      embeds: [
        embed
      ]
    }
  end

  def build_user_message(body) do
    %{
      content: body,
      flags: 64
    }
  end

  def build_autocomplete_choices(cards) do
    choices =
      cards
      |> Enum.take(25)
      |> Enum.map(&%{name: &1["name"], value: &1["_id"]})

    %{
      choices: choices
    }
  end
end
