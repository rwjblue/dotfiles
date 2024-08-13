# helpful unixy aliases
alias lsof-tcp-listen='lsof -iTCP -sTCP:LISTEN -P'

# use eza if it exists
# https://github.com/eza-community/eza (replacement for https://github.com/ogham/exa)
if which eza > /dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -l --all --no-user --changed --sort=modified'
  alias lt='eza --tree --level 3 -l --no-permissions --no-user --no-time'
else
  # setup ls
  ls / --color=auto > /dev/null 2>&1
  if [[ $? == 0 ]]; then
    alias ls='ls --color=auto'
  fi
fi

