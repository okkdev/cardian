defmodule Cardian.UserConfigs do
  import Ecto.Query, warn: false
  alias Cardian.Repo
  alias Cardian.Configs.UserConfig

  def list_configs do
    Repo.all(UserConfig)
  end

  def get_config_by_discord_id(discord_id) do
    Repo.get_by(UserConfig, discord_id: discord_id)
  end

  def create_or_update_config(attrs \\ %{}) do
    case get_config_by_discord_id(attrs.discord_id) do
      nil -> %UserConfig{discord_id: attrs.discord_id}
      config -> config
    end
    |> UserConfig.changeset(attrs)
    |> Repo.insert_or_update()
  end
end
