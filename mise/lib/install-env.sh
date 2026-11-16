#!/usr/bin/env bash

use_install_path() {
  local dirs=("$HOME/.local/bin" "${CARGO_HOME:-$HOME/.cargo}/bin")
  if [[ "$OSTYPE" == darwin* ]]; then
    dirs+=(/opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /usr/local/sbin)
  fi

  local dir
  for dir in "${dirs[@]}"; do
    if [[ ":$PATH:" != *":$dir:"* ]]; then
      PATH="$PATH:$dir"
    fi
  done
  export PATH
}

use_install_mise_config() {
  local config_dir="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
  if [[ -z "${MISE_GLOBAL_CONFIG_FILE:-}" && ! -f "$config_dir/config.toml" && ! -f "$config_dir/mise.toml" ]]; then
    # Use the checked-in tool manifest and adjacent lockfile before dot:install links them.
    export MISE_GLOBAL_CONFIG_FILE="$MISE_PROJECT_ROOT/packages/mise/config.toml"
  fi
}
