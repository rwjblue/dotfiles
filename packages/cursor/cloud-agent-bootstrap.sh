#!/usr/bin/env bash
# Link this repo's Agent Skills into a Cursor Cloud Agent home directory.
#
# Cursor runs the `start` command from a host repo's .cursor/environment.json
# (commonly .cursor/background_agent_start.sh). If that start script is set up
# to clone this repo and run $CURSOR_PERSONAL_INSTALL, point that env var at
# this file: packages/cursor/cloud-agent-bootstrap.sh.
#
# Private skills: set these Cloud Agent secrets to also link skills from a
# private repo. The token needs read-only Contents access to that repo; the
# Cloud Agent's own GitHub token usually can't see personal private repos.
#
#   CURSOR_PRIVATE_SKILLS_REPO   owner/repo
#   CURSOR_PRIVATE_SKILLS_TOKEN  fine-grained PAT
#   CURSOR_PRIVATE_SKILLS_PATH   skills dir inside that repo (default: skills)
#
# Do not run the workstation ./install here.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
skills="$root/packages/agents/skills"

if [ ! -d "$skills" ]; then
  echo "WARNING: skills dir missing: $skills" >&2
  exit 1
fi

if [ -n "${CURSOR_PRIVATE_SKILLS_REPO:-}" ] && [ -n "${CURSOR_PRIVATE_SKILLS_TOKEN:-}" ]; then
  private="$HOME/.cache/cursor-private-skills"
  auth=$(printf 'x-access-token:%s' "$CURSOR_PRIVATE_SKILLS_TOKEN" | base64 | tr -d '\n')
  rm -rf "$private"
  # A header keeps the token out of the clone's .git/config.
  if git -c "http.https://github.com/.extraheader=AUTHORIZATION: basic $auth" \
    clone --quiet --depth 1 "https://github.com/$CURSOR_PRIVATE_SKILLS_REPO.git" "$private"; then
    # Link every directory, including shared helpers that skills reference
    # by relative path.
    for dir in "$private/${CURSOR_PRIVATE_SKILLS_PATH:-skills}"/*/; do
      ln -sfn "${dir%/}" "$skills/$(basename "$dir")"
    done
  else
    echo "WARNING: failed to clone private skills repo $CURSOR_PRIVATE_SKILLS_REPO" >&2
  fi
fi

mkdir -p "$HOME/.cursor" "$HOME/.agents"
ln -sfn "$skills" "$HOME/.cursor/skills"
ln -sfn "$skills" "$HOME/.agents/skills"
