import Config
# set this to false if you want to hit the actual endpoints during development:
config :gogs, mock: false

# Do not include metadata nor timestamps in testing logs
config :logger, :console, level: :debug, format: "[$level] $message\n"
