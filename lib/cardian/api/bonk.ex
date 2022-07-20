defmodule Cardian.Api.Bonk do
  def valid_user?(user_id) when is_integer(user_id) do
    get_valid_users()
    |> Enum.map(& &1["discord_id"])
    |> Enum.member?(Integer.to_string(user_id))
  end

  def get_valid_users() do
    Req.get!(bonk_url()).body
  end

  defp bonk_url() do
    Application.fetch_env!(:cardian, :bonk_url)
  end
end
