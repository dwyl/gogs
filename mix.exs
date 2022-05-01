defmodule Gogs.MixProject do
  use Mix.Project

  def project do
    [
      app: :gogs,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        c: :test,
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      aliases: aliases(),
      deps: deps(),
      package: package(),
      description: "Interface with a Gogs (Git) Server"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Make HTTP Requests: github.com/edgurgel/httpoison
      {:httpoison, "~> 1.8.0"},

      # Parse JSON data: github.com/michalmuskala/jason
      {:jason, "~> 1.2"},

      # Check environment variables: github.com/dwyl/envar
      {:envar, "~> 1.0.5"},

      # Git interface: github.com/danhper/elixir-git-cli
      {:git_cli, "~> 0.3"},

      # Check test coverage: github.com/parroty/excoveralls
      {:excoveralls, "~> 0.14.4", only: :test},

      # Create Documentation for publishing Hex.docs:
      {:ex_doc, "~> 0.28", only: :dev},
    ]
  end

  defp aliases do
    [
      c: ["coveralls.html"]
    ]
  end

  defp package() do
    [
      files: ~w(lib LICENSE mix.exs README.md),
      name: "gogs",
      licenses: ["GPL-2.0-or-later"],
      maintainers: ["dwyl"],
      links: %{"GitHub" => "https://github.com/dwyl/gogs"}
    ]
  end
end
