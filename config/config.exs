import Config

# JioNLP pulls its ~9 MB dictionary bundle from `jionlp_rs` GitHub Releases
# on first application start and caches it in the user's cache dir
# (`~/.cache/jionlp_ex/data/<VER>/` on Linux, platform-equivalent via
# `:filename.basedir(:user_cache, ...)` elsewhere). No configuration is
# needed for typical use.
#
# To override — e.g. for air-gapped / internal-mirror / custom-dict setups:
#
#     # Pin a specific data version (bumped in jionlp_ex releases but you
#     # can override to pick up a newer `jionlp-data-v*` tag without
#     # upgrading the library):
#     config :jionlp_ex, data_version: "2026.04.1"
#
#     # Download from an internal mirror:
#     config :jionlp_ex, data_base_url: "https://mirror.example.com/jionlp"
#
#     # Use a pre-staged local directory (disables fetching entirely):
#     config :jionlp_ex, dictionary_path: "/opt/jionlp/data"
#
#     # Disable auto-fetch at application boot (you'll have to call
#     # `JioNLP.DataFetcher.ensure/0` yourself, or stage the dir):
#     config :jionlp_ex, auto_fetch: false
