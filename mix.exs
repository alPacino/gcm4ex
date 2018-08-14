defmodule GCM.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gcm,
      version: "0.0.4",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      package: package,
      name: "gcm4ex",
      source_url: "https://github.com/elabs/gcm4ex",
      description: """
      GCM (Google Cloud Messaging) library for Elixir
      """
    ]
  end

  def application do
    [applications: [
      :logger,
      :poison,
      :httpoison,
      :poolboy
    ],
    mod: {GCM, []}]
  end

  defp deps do
    [
      {:poison, "~> 1.5"},
      {:httpoison, "~> 0.8.0"},
      {:poolboy, "~> 1.5"}
    ]
  end

  defp package do
    [
      maintainers: ["Linus Pettersson", "Nicklas Ramhöj"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/elabs/gcm4ex"}
    ]
  end
end
