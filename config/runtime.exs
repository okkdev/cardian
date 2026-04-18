import Config

config :nostrum, ffmpeg: nil

otel_endpoint = System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")
otel_auth = System.get_env("OTEL_AUTH", "")
otel_stream = System.get_env("OTEL_STREAM_NAME", "default")

otel_headers =
  [{"stream-name", otel_stream}] ++
    if(otel_auth != "", do: [{"Authorization", "Basic #{otel_auth}"}], else: [])

config :opentelemetry,
  resource: [service: %{name: "cardian"}],
  span_processor: :batch,
  traces_exporter: :otlp

config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: otel_endpoint,
  otlp_headers: otel_headers

config :opentelemetry_experimental,
  readers: [
    %{
      module: :otel_metric_reader,
      config: %{
        exporter:
          {:otel_exporter_metrics_otlp,
           %{protocol: :http_protobuf, endpoint: otel_endpoint, headers: otel_headers}},
        export_interval_ms: 30_000
      }
    }
  ]

config :logger,
  handle_otp_reports: true

config :cardian,
  update_interval: String.to_integer(System.get_env("CARDIAN_UPDATE_INTERVAL", "120")),
  bonk_url: System.get_env("BONK_URL", "http://localhost:3000/order/list?auth=test-token")

config :cardian, Cardian.Repo,
  database: "database.db",
  migration_primary_key: [name: :id, type: :binary_id]

if config_env() == :prod do
  config :logger, level: :info
  config :cardian, Cardian.Repo, database: "/db/database.db"
end
