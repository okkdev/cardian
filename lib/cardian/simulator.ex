defmodule Cardian.Simulator do
  require Integer
  alias Cardian.CardRegistry

  def open_pack(pack, amount) when is_integer(amount) do
    cards = CardRegistry.get_cards()
    master_pack_cards = Enum.filter(cards, &Enum.member?(&1.sets, "61eaddc798a43480f06172db"))
    pack_cards = Enum.filter(cards, &Enum.member?(&1.sets, pack.id))

    Enum.flat_map(1..amount, fn pack_num ->
      guaranteed_slot = Enum.random(1..8)

      Enum.map(1..8, fn card_num ->
        Stream.filter(
          case pack.type do
            :selection_pack ->
              pack_cards

            _ ->
              if Integer.is_even(card_num) do
                master_pack_cards
              else
                pack_cards
              end
          end,
          fn card ->
            card.rarity ==
              if card_num == guaranteed_slot do
                if pack_num == 10 do
                  generate_rarity(:super)
                else
                  generate_rarity(:rare)
                end
              else
                generate_rarity()
              end
          end
        )
        |> Enum.random()
      end)
    end)
  end

  defp generate_rarity(min_rarity \\ :normal) do
    odds =
      case min_rarity do
        :normal ->
          %{
            ultra: 0.025,
            super: 0.075,
            rare: 0.35,
            normal: 0.55
          }

        :rare ->
          %{
            ultra: 0.025,
            super: 0.075,
            rare: 0.90
          }

        :super ->
          %{
            ultra: 0.20,
            super: 0.80
          }
      end

    Enum.reduce_while(odds, :rand.uniform(), fn {r, w}, odd ->
      if odd <= w, do: {:halt, r}, else: {:cont, odd - w}
    end)
  end
end
