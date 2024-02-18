# Setup fzf
# ---------

if [[ "$OSTYPE" == darwin* ]]; then
  # Auto-completion
  [[ $- == *i* ]] && source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
else
  if [[ ! "$PATH" == */$HOME/.fzf/bin* ]]; then
    export PATH="$PATH:$HOME/.fzf/bin"
  fi

  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "$HOME/.fzf/shell/key-bindings.zsh"
fi

