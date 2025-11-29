defmodule Itihas.Repo do
  use Ecto.Repo,
    otp_app: :itihas,
    adapter: Ecto.Adapters.SQLite3
end
