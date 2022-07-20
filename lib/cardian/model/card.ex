defmodule Cardian.Model.Card do
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
    :status,
    :rarity,
    :image_url,
    :url,
    :sets,
    :ocg
  ]
end
