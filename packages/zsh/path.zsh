# sourced by zshenv and zshrc

function _path_add() {
  case ":$PATH:" in
    *:"$1":*) ;;
    *) PATH="$1${PATH+:$PATH}" ;;
  esac
  export PATH
}

function _path_remove() {
  case ":$PATH:" in
    *:"$1":*)
      PATH=$(echo ":$PATH:" | sd ":$1:" ":" | sd '^:' '' | sd ':$' '')
      ;;
  esac
  export PATH
}

function _ensure_first_path() {
  _path_remove $1
  _path_add $1
}

export CARGO_HOME="$HOME/.cargo"

# NOTE: LinkedIn machine image puts `/opt/homebrew/bin/` on path via
# `/etc/paths.d/`, but it is in the wrong location (it ends up having it's
# binaries like `delta` shadowed), so we remove and prepend it
_ensure_first_path "/opt/homebrew/bin"
_ensure_first_path "/opt/homebrew/sbin"

_ensure_first_path "$CARGO_HOME/bin"

_ensure_first_path "/opt/homebrew/opt/fzf/bin"
_ensure_first_path "$HOME/src/github/rwjblue/dotfiles/packages/binutils/crates/global/target/debug"
_ensure_first_path "$HOME/src/github/malleatus/shared_binutils/global/target/debug"
_ensure_first_path "$HOME/.local/bin"

# this is not using the `# CMD:` system because it captures `$PATH` at the time
# it is ran, and we don't want to do that (it needs to be capturing `$PATH` at
# shell startup time not when we build packages-dist)
eval "$(mise activate zsh)"

