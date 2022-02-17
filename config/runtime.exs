import Config

config :nostrum,
  token: System.fetch_env!("CARDIAN_TOKEN")
