defmodule Cardian.Repo.Migrations.AddDiscordIdUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:user_configs, [:discord_id])
  end
end
