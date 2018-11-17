#!/usr/bin/env zsh

set -e # fail if anything exits non-zero

DOTFILES=$(dirname ${(%):-%x})

abspath() {
  # generate absolute path from relative path
  # $1     : relative filename
  # return : absolute path
  if [ -d "$1" ]; then
    # dir
    (cd "$1"; pwd)
  elif [ -f "$1" ]; then
    # file
    if [[ $1 = /* ]]; then
      echo "$1"
    elif [[ $1 == */* ]]; then
      echo "$(cd "${1%/*}"; pwd)/${1##*/}"
    else
      echo "$(pwd)/$1"
    fi
  fi
}

link-dotfile() {
  local SOURCE=$1
  local TARGET=$2

  local ABSOLUTE_SOURCE=$(abspath $DOTFILES/$SOURCE)

  if [ -h $TARGET ]; then
    if [ "$FORCE" = "true" ]; then
      echo "$TARGET already exists, removing it";
      rm -rf $TARGET
      link-dotfile $@
    else
      echo "$TARGET symlink already exists";
    fi
  else
    echo "creating link for $TARGET"
    ln -s $ABSOLUTE_SOURCE $TARGET
  fi
}

copy-dotfile() {
  local SOURCE=$1
  local TARGET=$2

  local ABSOLUTE_SOURCE=$(abspath $DOTFILES/$SOURCE)

  if [ -e $TARGET ]; then
    if [ "$FORCE" = "true" ]; then
      echo "$TARGET already exists, removing it";
      rm -rf $TARGET
      link-dotfile $@
    else
      echo "$TARGET already exists";
    fi
  else
    echo "creating $TARGET"
    cp $ABSOLUTE_SOURCE $TARGET
  fi
}

link-dotfile "zsh/zshenv" "$HOME/.zshenv"
link-dotfile "zsh/zprofile" "$HOME/.zprofile"
link-dotfile "zsh/zshrc" "$HOME/.zshrc"
link-dotfile "zsh/zshrc" "$HOME/.zshrc"
copy-dotfile "zsh/zshrc.local" "$HOME/.zshrc.local"

link-dotfile "git/gitconfig" "$HOME/.gitconfig"
link-dotfile "git/gitignore_global" "$HOME/.gitignore_global"

link-dotfile "tmux/tmux.conf" "$HOME/.tmux.conf"


if [ ! -d ~/.ssh ]; then
  echo "Creating .ssh dir"
  mkdir $HOME/.ssh
fi
link-dotfile "ssh/rc" "$HOME/.ssh/rc"

