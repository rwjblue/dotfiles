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


"$HOME/src/malleatus/shared_binutils/target/debug/setup-local-dotfiles" \
  --local-dotfiles-path ~/src/workstuff/local-dotfiles \
  --local-crates-target-path ~/src/rwjblue/dotfiles/binutils/local-crates

echo "Building binutils"
(cd "$DOTFILES/binutils" && cargo build)

echo "setting up binutils symlinks"
"$HOME/src/malleatus/shared_binutils/target/debug/generate-binutils-symlinks"

