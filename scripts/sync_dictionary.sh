#!/usr/bin/env bash
#
# Sync runtime dictionary from jionlp_rs (source of truth) to
# jionlp_ex/priv/dictionary. Run this whenever you add/update dict files
# on the Rust side so the Elixir package picks them up.
#
# Why not a symlink? Hex's tar builder does not dereference symlinks in
# all versions, which would ship a broken link to Hex consumers. A hard
# copy is the cross-platform, release-safe option.
#
# Usage: ./scripts/sync_dictionary.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIV_DIR="$SCRIPT_DIR/../priv/data"
SRC_DIR="$SCRIPT_DIR/../../jionlp_rs/crates/jionlp-core/data"

if [[ ! -d "$SRC_DIR" ]]; then
    echo "error: source dictionary not found at $SRC_DIR" >&2
    exit 1
fi

mkdir -p "$PRIV_DIR"
rsync -a --delete "$SRC_DIR/" "$PRIV_DIR/"
echo "synced $(ls "$PRIV_DIR" | wc -l | tr -d ' ') files to $PRIV_DIR"
du -sh "$PRIV_DIR"
