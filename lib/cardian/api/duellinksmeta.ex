defmodule Cardian.Api.Duellinksmeta do
  alias Cardian.Api.MetaSite

  @config %{
    base_url: "https://www.duellinksmeta.com/api/v1",
    site_prefix: "https://www.duellinksmeta.com/articles",
    status_field: :status_dl,
    rarity_field: :rarity_dl,
    sets_field: :sets_dl
  }

  def get_all_cards_raw, do: MetaSite.get_all_cards_raw(@config)

  def update_card_details(cards, raw_dl_cards),
    do: MetaSite.update_card_details(cards, raw_dl_cards, @config)

  def get_all_sets, do: MetaSite.get_all_sets(@config)
end
