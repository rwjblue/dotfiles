#!/usr/bin/env bash
# Link this repo's Agent Skills into a Cursor Cloud Agent home directory.
#
# Cursor runs the `start` command from a host repo's .cursor/environment.json
# (commonly .cursor/background_agent_start.sh). If that start script is set up
# to clone this repo and run $CURSOR_PERSONAL_INSTALL, point that env var at
# this file: packages/cursor/cloud-agent-bootstrap.sh.
#
# Do not run the workstation ./install here.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
skills="$root/packages/agents/skills"

if [ ! -d "$skills" ]; then
  echo "WARNING: skills dir missing: $skills" >&2
  exit 1
fi

mkdir -p "$HOME/.cursor" "$HOME/.agents"
ln -sfn "$skills" "$HOME/.cursor/skills"
ln -sfn "$skills" "$HOME/.agents/skills"
