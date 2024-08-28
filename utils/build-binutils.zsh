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

echo "setting up malleatus/shared_binutils symlinks"
"$HOME/src/malleatus/shared_binutils/target/debug/generate-binutils-symlinks" --workspace-path "$HOME/src/malleatus/shared_binutils/"

echo "Building binutils"
(cd "$DOTFILES/binutils/crates" && cargo build)

echo "setting up binutils symlinks"
"$HOME/src/malleatus/shared_binutils/target/debug/generate-binutils-symlinks" --workspace-path "$DOTFILES/binutils/crates/"
