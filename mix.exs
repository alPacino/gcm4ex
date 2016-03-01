defmodule GCM.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gcm,
      version: "0.0.11",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      package: package,
      name: "gcm4ex",
      source_url: "https://github.com/chvanikoff/gcm4ex",
      description: """
      GCM (Apple Push Notification Service) library for Elixir
      """
    ]
  end

  def application do
    [applications: [
      :logger,
      :public_key,
      :ssl,
      :poison,
      :poolboy
    ],
    mod: {GCM, []}]
  end

  defp deps do
    [
      {:poison, "~> 1.5"},
      {:poolboy, "~> 1.5"}
    ]
  end

  defp package do
    [
      maintainers: ["Roman Chvanikov"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/chvanikoff/gcm4ex"}
    ]
  end
end