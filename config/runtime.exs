import Config

config :nostrum,
  token: System.fetch_env!("CARDIAN_TOKEN"),
  ffmpeg: nil,
  gateway_intents: [
    :guilds
  ]

config :cardian,
  update_interval: String.to_integer(System.get_env("CARDIAN_UPDATE_INTERVAL", "120")),
  bonk_url: System.get_env("BONK_URL", "http://localhost:3000/order/list?auth=test-token")

config :cardian, Cardian.Repo,
  database: "database.db",
  migration_primary_key: [name: :id, type: :binary_id]

config :sentry,
  dsn: System.fetch_env!("SENTRY_URL"),
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  environment_name: :dev,
  client: SentryReqHttpClient

if config_env() == :prod do
  config :logger,
    level: :info

  config :cardian, Cardian.Repo, database: "/db/database.db"

  config :sentry,
    environment_name: :prod
end
