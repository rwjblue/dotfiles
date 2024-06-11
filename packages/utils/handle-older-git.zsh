#!/usr/bin/env zsh

set -e

# Get the installed Git version
GIT_VERSION=$(git --version | awk '{print $3}')

# Function to compare versions
version_ge() {
  # Returns 0 (true) if the first version is greater or equal to the second
  [[ "$1" == "$2" ]] && return 0
  [[ "$1" > "$2" ]] && return 0
  return 1
}

# Minimum version required for conflictStyle = zdiff3
MIN_VERSION="2.35.0"

echo "Git version: $GIT_VERSION"

# Check if the installed Git version supports zdiff3
if version_ge "$GIT_VERSION" "$MIN_VERSION"; then
  # nothing to do here, the default dotfiles uses zdiff3 
else
  echo "Git version does not support zdiff3. Using diff3 instead."
  git config --global merge.conflictStyle diff3

  git config --global --unset transfer.fsckobjects || true
  git config --global --unset fetch.fsckobjects || true
  git config --global --unset receive.fsckobjects || true
fi
