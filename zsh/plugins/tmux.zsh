# Tmux helper functions

# switch to tmux session using fzf to select
__ts() {
  if [ "$TMUX" ]; then
    t_cmd='switch-client'
  else
    t_cmd='attach'
  fi

  # tmux list-sessions | fzf  | cut -d':' -f 1 | echo xargs tmux ${t_cmd} -t
  t_session=$(tmux list-sessions | fzf  | cut -d':' -f 1)

  # if selected, switch to it
  if [[ -n "$t_session" ]]; then
    tmux $t_cmd -t $t_session
  fi
}

# use `z` (from zoxide setup above) to switch to a directory, if successful
# rename the window to the current working directory; this is generally nice
# when that dir is the name of a specific repo
function __tz {
  z $@ && tmux rename-window  "${PWD##*/}"
}

alias t='tmux'
alias ts='__ts'
alias gz='__tz'

# use fzf to select a specific window in the tmux session
alias tw='tmux list-windows | fzf  | cut -d':" -f 1 | xargs tmux select-window -t"
