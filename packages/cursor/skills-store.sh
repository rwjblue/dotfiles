#!/usr/bin/env bash
# Print the `files` directory of Cursor's personal synced skill store, or
# nothing when skill sync has never been turned on.
#
# CURSOR_SKILLS_STORE overrides discovery. Nothing sets it; export it only if
# discovery finds more than one store (for example, multiple Cursor teams).
set -euo pipefail

if [ -n "${CURSOR_SKILLS_STORE:-}" ]; then
  echo "$CURSOR_SKILLS_STORE"
  exit 0
fi

stores="$HOME/Library/Application Support/Cursor/AgentStores/cursor_agent_stores"
[ -d "$stores" ] || exit 0

# The personal store is named t<team>-u<user>; per-agent stores are UUIDs.
shopt -s nullglob
candidates=("$stores"/t*-u*/files)
shopt -u nullglob

case "${#candidates[@]}" in
  0) ;;
  1) echo "${candidates[0]}" ;;
  *)
    echo "Expected one personal Cursor store, found ${#candidates[@]}:" >&2
    printf '  %s\n' "${candidates[@]}" >&2
    echo "Set CURSOR_SKILLS_STORE to the right .../files directory." >&2
    exit 1
    ;;
esac
