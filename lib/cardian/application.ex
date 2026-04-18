defmodule Cardian.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ets.new(:bonk_cache, [:set, :public, :named_table, read_concurrency: true])
    Cardian.Metrics.setup()

    bot_options = %{
      consumer: Cardian.EventConsumer,
      intents: [:guilds],
      wrapped_token: fn -> System.fetch_env!("CARDIAN_TOKEN") end
    }

    children = [
      {Ecto.Migrator, repos: Application.fetch_env!(:cardian, :ecto_repos)},
      {Nostrum.Bot, bot_options},
      Cardian.CardRegistry,
      Cardian.Repo
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cardian.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
