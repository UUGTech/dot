#!/usr/bin/env bash
# Thin wrapper around cursor-sessions.py (keeps `prefix+a`-style shell entrypoints).
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec python3 "$script_dir/cursor-sessions.py" "$@"
