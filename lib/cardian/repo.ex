defmodule Cardian.Repo do
  use Ecto.Repo,
    otp_app: :cardian,
    adapter: Ecto.Adapters.SQLite3
end
