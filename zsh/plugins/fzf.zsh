# Setup fzf
# ---------

if [[ "$OSTYPE" == darwin* ]]; then
  # Auto-completion
  [[ $- == *i* ]] && source "/opt/homeberw/opt/fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
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

