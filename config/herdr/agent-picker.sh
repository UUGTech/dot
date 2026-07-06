#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

target=$(
	herdr agent list \
		| jq -r '
			.result.agents[]
			| [
				(.pane_id // "-"),
				(.agent // "unknown"),
				(.agent_status // "unknown"),
				(.focused | if . then "*" else " " end),
				(.cwd // "-")
			]
			| @tsv
		' \
		| sk \
			--delimiter=$'\t' \
			--with-nth='4,2,3,1,5' \
			--prompt='agent> ' \
			--border \
			--ansi \
			--color='fg:#e0def4,bg:#191724,matched:#ebbcba,current_bg:#26233a,current_fg:#e0def4,current_match:#f6c177,prompt:#9ccfd8,info:#c4a7e7,border:#31748f,header:#9ccfd8' \
			--header='Enter: focus agent' \
			--preview="${script_dir}/agent-preview.sh {1}" \
			--preview-window='right:60%' \
		| awk -F '\t' '{ print $1 }'
)

if [[ -n "${target:-}" && "$target" != "-" ]]; then
	herdr pane zoom "$target" --off
	herdr agent focus "$target"
fi
