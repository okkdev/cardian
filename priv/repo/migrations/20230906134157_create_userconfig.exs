defmodule Cardian.Repo.Migrations.CreateUserconfig do
  use Ecto.Migration

  def change do
    create table(:user_configs) do
      add :discord_id, :integer
      add :format, :string

      timestamps()
    end
  end
end
