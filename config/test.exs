import Config

# set this to false if you want to hit the actual endpoints during development:
config :gogs,
  mock: true

# Do not include metadata nor timestamps in testing logs
config :logger, :console, level: :warn, format: "[$level] $message\n"