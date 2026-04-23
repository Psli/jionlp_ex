defmodule JioNLP.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Psli/jionlp_rs"

  def project do
    [
      app: :jionlp_ex,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Elixir bindings for jionlp-rs — Chinese NLP preprocessing & parsing, " <>
          "backed by a Rust NIF.",
      package: package(),
      source_url: @source_url,
      docs: [main: "JioNLP", extras: ["../PLAN.md"]],
      aliases: aliases()
    ]
  end

  # `mix jionlp.sync_dict` remains a dev-only convenience for copying
  # `../jionlp_rs/crates/jionlp-core/data/` into `priv/data/` (so local
  # iex/ExUnit runs don't need network access). The Hex tarball no longer
  # ships `priv/data/` — end users get the dictionary by downloading from
  # `jionlp_rs` GitHub Releases (see `JioNLP.DataFetcher`).
  defp aliases do
    [
      "jionlp.sync_dict": ["cmd ./scripts/sync_dictionary.sh"]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl, :crypto, :public_key],
      mod: {JioNLP.Application, []}
    ]
  end

  defp deps do
    [
      # `rustler_precompiled` ships prebuilt NIF binaries via GitHub Releases so
      # end users don't need a Rust toolchain. It falls back to `rustler` and
      # compiles from source when the binary for the current target isn't
      # available (e.g. during dev work, or on unsupported platforms).
      {:rustler_precompiled, "~> 0.7"},
      {:rustler, "~> 0.34.0", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      # The dictionary is NOT bundled. `JioNLP.DataFetcher` downloads it from
      # `jionlp_rs` GitHub Releases on first use and caches it under
      # `~/.cache/jionlp_ex/data/<VER>/` (platform-equivalent via
      # `:filename.basedir(:user_cache, ...)`). This decouples dictionary
      # updates from library releases.
      #
      # The Rust source tree is included for `JIONLP_BUILD=1` fallback, but
      # the `data/` directory inside it is excluded (~9 MB we don't want
      # duplicating on Hex).
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*",
        "../jionlp_rs/Cargo.toml",
        "../jionlp_rs/Cargo.lock",
        "../jionlp_rs/.cargo",
        "../jionlp_rs/crates/jionlp-core/src",
        "../jionlp_rs/crates/jionlp-core/Cargo.toml",
        "../jionlp_rs/crates/jionlp_nif/src",
        "../jionlp_rs/crates/jionlp_nif/Cargo.toml"
      ]
    ]
  end
end
