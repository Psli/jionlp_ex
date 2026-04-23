# JioNLP

[![Hex.pm](https://img.shields.io/hexpm/v/jionlp_ex.svg)](https://hex.pm/packages/jionlp_ex)
[![HexDocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/jionlp_ex)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

Elixir bindings for [**jionlp-rs**](https://github.com/Psli/jionlp_rs) — a
Rust port of [JioNLP](https://github.com/dongrixinyu/JioNLP), a Chinese NLP
preprocessing & parsing toolkit. Backed by a Rust NIF (via
[Rustler](https://github.com/rusterlium/rustler) +
[`rustler_precompiled`](https://github.com/philss/rustler_precompiled)).

- No Python runtime.
- Prebuilt NIF binaries for Linux (gnu/musl × x86_64/aarch64), macOS
  (x86_64/aarch64), and Windows (x86_64) — end users need no Rust toolchain.
- The ~9 MB runtime dictionary is **pulled from `jionlp_rs` GitHub Releases
  on first use** and cached under `~/.cache/jionlp_ex/data/<VER>/`. This
  decouples dictionary updates from library releases — you can bump to a
  newer `jionlp-data-v*` tag without upgrading this package.

## Install

```elixir
# mix.exs
def deps do
  [
    {:jionlp_ex, "~> 0.1"}
  ]
end
```

Then:

```bash
mix deps.get
# Optional: pre-fetch the dictionary (otherwise it downloads on first boot)
mix jionlp.fetch_data
```

No further setup. At application start `JioNLP.Application` checks the
user cache dir; if empty, it downloads the dictionary from
`jionlp_rs` GitHub Releases (with SHA-256 verification) and caches it.

## Quickstart

```elixir
# Sentence splitting
iex> JioNLP.split_sentence("今天天气真好。我要去公园！")
["今天天气真好。", "我要去公园！"]

# Traditional ⇄ Simplified
iex> JioNLP.tra2sim("今天天氣好晴朗")
"今天天气好晴朗"

iex> JioNLP.sim2tra("今天天气好晴朗")
"今天天氣好晴朗"

# Money
iex> JioNLP.parse_money("三千五百万港币")
%JioNLP.MoneyInfo{num: "35000000.00", case: "2", definition: "accurate", unit: "HKD"}

# Time
iex> JioNLP.parse_time("明天下午三点")
%JioNLP.TimeInfo{...}

# Location
iex> JioNLP.parse_location("上海市浦东新区陆家嘴环路1000号")
%JioNLP.ParsedLocation{province: "上海市", city: "上海市", county: "浦东新区", ...}

# ID card
iex> JioNLP.parse_id_card("110101199003078829")
%JioNLP.IdCardInfo{province: "北京市", gender: "male", birthday: "1990-03-07", ...}

# Keyphrase extraction
iex> JioNLP.extract_keyphrase(long_text, 10)
[{"phrase", score}, ...]

# Pinyin
iex> JioNLP.pinyin("拼音测试")
["pīn", "yīn", "cè", "shì"]
```

Full API: [HexDocs](https://hexdocs.pm/jionlp_ex) or `lib/jionlp.ex`
(78 public functions).

## Configuration

All optional — the defaults work for public-internet installs.

```elixir
# config/config.exs

# Pin a specific data version (overrides the baked-in default). Use this to
# pull a newer `jionlp-data-v*` tag without upgrading jionlp_ex itself.
config :jionlp_ex, data_version: "2026.04.1"

# Mirror the dictionary bundle (e.g. internal artifactory). The fetcher
# hits `<base_url>/jionlp-data-v<VER>/jionlp-data-v<VER>.tar.gz`.
config :jionlp_ex, data_base_url: "https://mirror.example.com/jionlp"

# Skip fetching entirely — point at a pre-staged directory. Useful for
# air-gapped environments or for custom/upstream-Python dict overrides.
config :jionlp_ex, dictionary_path: "/opt/jionlp/data"

# Disable boot-time auto-fetch (you'll have to call
# `JioNLP.DataFetcher.ensure/0` or pre-stage the dir).
config :jionlp_ex, auto_fetch: false

# Mirror the precompiled NIF download URL (different artifact than data).
config :jionlp_ex, precompiled_base_url: "https://mirror.example.com/jionlp/nif/v#{version}"
```

## Development

This package lives as a sibling to
[`jionlp_rs`](https://github.com/Psli/jionlp_rs), which is the single
source of truth for both the Rust NIF and the dictionary files.

```bash
git clone https://github.com/Psli/jionlp_rs
git clone https://github.com/Psli/jionlp_ex        # or wherever the Elixir repo lives
# Directory layout must be:
#   parent/
#   ├── jionlp_rs/
#   └── jionlp_ex/

cd jionlp_ex
./scripts/sync_dictionary.sh   # rsync data/ → priv/data/
mix deps.get
JIONLP_BUILD=1 mix test         # forces source build of the NIF
```

`JIONLP_BUILD=1` tells `rustler_precompiled` to build from source instead
of downloading the prebuilt binary — required while doing Rust-side
development.

## Releasing

Three independent release cycles, all driven by tags on `jionlp_rs`:

- **`jionlp-data-v<DATE>`** (e.g. `jionlp-data-v2026.04.1`) — dictionary
  bundle. `release-data.yml` tars `crates/jionlp-core/data/` and uploads
  `jionlp-data-v<DATE>.tar.gz` + `.sha256` to the Release. Bump
  `@default_data_version` in `lib/jionlp/data_fetcher.ex` so new installs
  pull the new tag by default.
- **`jionlp_ex-vX.Y.Z`** — Elixir library + NIF. `release-nif.yml` builds
  14 NIF tarballs. Then locally:
    1. `mix rustler_precompiled.download JioNLP.Native --all --print`
    2. Commit the generated `checksum-Elixir.JioNLP.Native.exs`
    3. `mix hex.publish`
  The Hex tarball is small (~200 KB) — the dictionary is NOT bundled.
- **`jionlp-core-vX.Y.Z`** — Rust crate. `release-crate.yml` runs
  `cargo publish -p jionlp-core`. (Independent of Elixir.)

## Parity & scope

The Rust port targets **JioNLP 0.2.7.x non-LLM APIs**. All lexicon-driven
features (parsing, extraction, cleaning, keyphrase, summary, simhash,
F1 evaluation, NER tooling, etc.) are ported. LLM-dependent helpers are
out of scope.

## License

Apache-2.0, matching the upstream Python project.
