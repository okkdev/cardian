import Config

config :nostrum,
  token: System.fetch_env!("CARDIAN_TOKEN"),
  gateway_intents: [
    :guilds
  ]

config :cardian,
  update_interval: String.to_integer(System.get_env("CARDIAN_UPDATE_INTERVAL", "120")),
  bonk_url: System.get_env("BONK_URL", "http://localhost:3000/order/list?auth=test-token")

if config_env() == :prod do
  config :logger,
    level: :info
end
