# TODO: do this jit with aliases
#   - gem
#   - ruby
#   - $HOME/.rbenv/shims/*
#
# eval "$(rbenv init -)"

function rbenv_init {
  eval "$(rbenv init -)"

  unalias gem
  unalias ruby
  unalias pws
  unfunction rbenv_init

  echo "rbenv init ran; re-run your command"
}

alias gem=rbenv_init
alias ruby=rbenv_init
alias pws=rbenv_init
