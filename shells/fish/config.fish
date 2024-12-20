function _path_add
    if not contains -- $argv[1] $PATH
        set -gx PATH $argv[1] $PATH
    end
end

function _path_remove
    if set -l index (contains -i -- $argv[1] $PATH)
        set -e PATH[$index]
    end
end

function _ensure_first_path
    _path_remove $argv[1]
    _path_add $argv[1]
end

# Homebrew setup
set -gx HOMEBREW_PREFIX "/opt/homebrew"
set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar"
set -gx HOMEBREW_REPOSITORY "/opt/homebrew"

# Man and Info paths
if test -n "$MANPATH"
    set -gx MANPATH ":$MANPATH"
end
set -gx INFOPATH "/opt/homebrew/share/info:$INFOPATH"

# Ensure homebrew paths are first
_ensure_first_path "/opt/homebrew/bin"
_ensure_first_path "/opt/homebrew/sbin"

# CMD: zoxide init fish
# CMD: starship init fish --print-full-init

# load 1Password configured plugins if 1Password is installed and configured
# see https://developer.1password.com/docs/cli/shell-plugins
if test -f ~/.config/op/plugins.sh
    source ~/.config/op/plugins.sh
end

# Fish vi mode
fish_vi_key_bindings
set -g fish_escape_delay_ms 10

# Environment variables
set -gx LANG 'en_US.UTF-8'
set -gx EDITOR "nvim"
set -gx VOLTA_HOME "$HOME/.volta"
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

# SSH auth sock
if test -r $HOME/.ssh/ssh_auth_sock
    set -gx SSH_AUTH_SOCK $HOME/.ssh/ssh_auth_sock
end

# Cargo setup

if test -d $HOME/.cargo/bin
  fish_add_path --path --prepend --move 
end

# FZF setup
if test (uname) = "Darwin"
    source "/opt/homebrew/opt/fzf/shell/key-bindings.fish"
else
    if not contains -- "$HOME/.fzf/bin" $PATH
        set -gx PATH $PATH "$HOME/.fzf/bin"
    end
    source "$HOME/.fzf/shell/key-bindings.fish"
end

# helpful unixy aliases
alias lsof-tcp-listen='lsof -iTCP -sTCP:LISTEN -P'

# eza setup
if command -v eza > /dev/null
    alias ls='eza'
    alias ll='eza -l --all --no-user --changed --sort=modified'
    alias lt='eza --tree --level 3 -l --no-permissions --no-user --no-time'
else
    # setup ls
    if ls / --color=auto >/dev/null 2>&1
        alias ls='ls --color=auto'
    end
end

# Tmux functions
function __ts
    if test -n "$TMUX"
        set t_cmd 'switch-client'
    else
        set t_cmd 'attach'
    end

    set -l t_session (tmux list-sessions | fzf | cut -d':' -f 1)
    if test -n "$t_session"
        tmux $t_cmd -t $t_session
    end
end

function __tz
    set -l result (zoxide query -- $argv)
    and cd $result
    and tmux rename-window (basename $PWD)
end

# Tmux aliases
alias t='tmux'
alias ts='__ts'
alias gz='__tz'

# use fzf to select a specific window in the tmux session
alias tw='tmux list-windows | fzf  | cut -d':" -f 1 | xargs tmux select-window -t"

# git related aliases
alias g='git'
alias gst='g status -sb'      # use short version of git status
alias gap='g add -p'          # the best way to run git add
alias gd='g diff'             # show unstaged changes
alias gds='g diff --staged'   # show staged changes
alias gc='g commit --verbose' # use verbose mode with $EDITOR

alias gah='g commit --amend -CHEAD' # amend the previous commit without prompting for message

# Ensure paths are in correct order
_ensure_first_path "$VOLTA_HOME/bin"
_ensure_first_path "/opt/homebrew/opt/fzf/bin"
_ensure_first_path "$HOME/src/rwjblue/dotfiles/binutils/crates/global/target/debug"
_ensure_first_path "$HOME/src/malleatus/shared_binutils/global/target/debug"
_ensure_first_path "$HOME/.local/bin"

# Source local config if it exists
if test -f "$HOME/.config/fish/config.local.fish"
    source "$HOME/.config/fish/config.local.fish"
end
