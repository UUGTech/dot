#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"
if [[ -z "$target" || "$target" == "-" ]]; then
	exit 0
fi

text=$(
	herdr agent read "$target" --source recent --lines 80 --format text \
		| jq -r '.result.read.text // ""'
)

if [[ -z "$text" ]]; then
	text=$(
		herdr agent read "$target" --source visible --lines 80 --format text \
			| jq -r '.result.read.text // ""'
	)
fi

if [[ -n "$text" ]]; then
	printf '%s\n' "$text"
else
	printf 'No preview available for %s\n' "$target"
fi
