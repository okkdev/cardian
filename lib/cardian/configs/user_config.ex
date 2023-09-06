defmodule Cardian.Configs.UserConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  schema "user_configs" do
    field(:discord_id, :integer)
    field(:format, Ecto.Enum, values: [:paper, :md, :dl])

    timestamps()
  end

  def changeset(user_config, params \\ %{}) do
    user_config
    |> cast(params, [:discord_id, :format])
    |> validate_required([:discord_id, :format])
    |> unique_constraint(:discord_id)
  end
end
