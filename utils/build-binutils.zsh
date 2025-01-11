#!/usr/bin/env zsh

set -e

DOTFILES=$(dirname "$(dirname "$(realpath "$0")")")

echo "building binutils"

if [ ! -d "$HOME/src/malleatus/shared_binutils/" ]; then
  echo "Cloning malleatus/shared_binutils repository"
  git clone https://github.com/malleatus/shared_binutils.git "$HOME/src/malleatus/shared_binutils/"
fi

echo "Building malleatus/shared_binutils"
(cd "$HOME/src/malleatus/shared_binutils/" && cargo build)

# Create local-dotfiles directory if it doesn't exist
if [ ! -d "$DOTFILES/local-dotfiles/crates" ]; then
  echo "Creating local-dotfiles directory"
  mkdir -p "$DOTFILES/local-dotfiles/crates/"
fi

echo "Building binutils"
(cd "$DOTFILES/binutils" && cargo build)

echo "setting up binutils symlinks"
"$HOME/src/malleatus/shared_binutils/target/debug/generate-binutils-symlinks"

