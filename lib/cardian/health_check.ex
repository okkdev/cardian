defmodule Cardian.HealthCheck do
  use GenServer
  require Logger

  @interval 60_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    schedule()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check, state) do
    with url when is_binary(url) <- push_url(),
         true <- healthy?() do
      case Req.get(url) do
        {:ok, _} -> :ok
        {:error, reason} -> Logger.warning("Health check push failed: #{inspect(reason)}")
      end
    else
      false -> Logger.warning("Health check failed: bot unhealthy")
      _ -> :ok
    end

    schedule()
    {:noreply, state}
  end

  defp healthy? do
    children = Supervisor.which_children(Cardian.Supervisor)

    :ets.info(:cards, :size) > 0 and
      Enum.all?(children, fn
        {_, pid, _, _} when is_pid(pid) -> true
        {_, :undefined, :worker, [Ecto.Migrator]} -> true
        _ -> false
      end)
  end

  defp schedule, do: Process.send_after(self(), :check, @interval)

  defp push_url, do: Application.get_env(:cardian, :push_url)
end
