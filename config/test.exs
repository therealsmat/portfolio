import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :portfolio, PortfolioWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "CiwNqNVOkQvZ8xWXuRKAQOY0zL0NDl1No0DkBoG7w78sT9eLF1AhId8izFMq2AWx",
  server: false

# In test we don't send emails.
config :portfolio, Portfolio.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
