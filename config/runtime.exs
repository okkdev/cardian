import Config

config :nostrum,
  token: System.fetch_env!("CARDIAN_TOKEN")

config :cardian,
  update_interval: String.to_integer(System.get_env("CARDIAN_UPDATE_INTERVAL", "120"))
