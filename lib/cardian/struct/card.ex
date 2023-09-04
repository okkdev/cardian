defmodule Cardian.Struct.Card do
  defstruct [
    :id,
    :type,
    :race,
    :monster_type,
    :monster_types,
    :attribute,
    :level,
    :name,
    :description,
    :pendulum_effect,
    :atk,
    :def,
    :scale,
    :arrows,
    :status_md,
    :status_tcg,
    :status_ocg,
    :status_goat,
    :rarity_md,
    :image_url,
    :url,
    :sets_md,
    :ocg
  ]
end
