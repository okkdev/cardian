defmodule Cardian.Api.Bonk do
  @cache_ttl :timer.minutes(5)

  def valid_user?(user_id) when is_integer(user_id) do
    user_str = Integer.to_string(user_id)

    case get_cached_users() do
      {:ok, users} -> MapSet.member?(users, user_str)
      :miss -> MapSet.member?(fetch_and_cache_users(), user_str)
    end
  end

  defp fetch_and_cache_users do
    users =
      get_valid_users()
      |> Enum.map(& &1["discord_id"])
      |> MapSet.new()

    :ets.insert(:bonk_cache, {:users, users, System.monotonic_time(:millisecond)})
    users
  end

  defp get_cached_users do
    case :ets.lookup(:bonk_cache, :users) do
      [{:users, users, timestamp}] ->
        if System.monotonic_time(:millisecond) - timestamp < @cache_ttl do
          {:ok, users}
        else
          :miss
        end

      [] ->
        :miss
    end
  end

  defp get_valid_users do
    case Req.request(url: bonk_url()) do
      {:ok, resp} -> resp.body
      {:error, _} -> []
    end
  end

  defp bonk_url do
    Application.fetch_env!(:cardian, :bonk_url)
  end
end
