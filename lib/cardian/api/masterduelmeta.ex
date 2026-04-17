defmodule Cardian.Api.Masterduelmeta do
  alias Cardian.Api.MetaSite

  @config %{
    base_url: "https://www.masterduelmeta.com/api/v1",
    site_prefix: "https://www.masterduelmeta.com/articles",
    status_field: :status_md,
    rarity_field: :rarity_md,
    sets_field: :sets_md
  }

  def get_all_cards_raw, do: MetaSite.get_all_cards_raw(@config)

  def update_card_details(cards, raw_md_cards),
    do: MetaSite.update_card_details(cards, raw_md_cards, @config)

  def get_all_sets, do: MetaSite.get_all_sets(@config)
end
