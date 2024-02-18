# ensure we use a stable SSH_AUTH_SOCK (so reconnecting to prior tmux sessions
# continue to be able to auth)
if [[ -r $HOME/.ssh/ssh_auth_sock ]]; then
  export SSH_AUTH_SOCK=$HOME/.ssh/ssh_auth_sock
fi

