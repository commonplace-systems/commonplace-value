defmodule Commonplace.Value.MixProject do
  use Mix.Project

  def project do
    [
      app: :commonplace_value,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  # ⛔ ZERO RUNTIME DEPS, and that is a property rather than an accident:
  # spec §21 forbids depending on commonplace-log or any higher layer, and a pure
  # value package is also the best case for the Sol fence -- it can produce no
  # false finding about network, credentials, or a live store.
  #
  # stream_data is `only: :test`. Spec §21 permits "test-only property and
  # conformance tooling"; §20 asks for property tests over bounded portable terms.
  defp deps do
    [
      {:stream_data, "~> 1.1", only: :test, runtime: false}
    ]
  end
end
