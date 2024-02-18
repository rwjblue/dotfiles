# helpful unixy aliases
alias lsof-tcp-listen='lsof -iTCP -sTCP:LISTEN -P'

# use eza if it exists
# https://github.com/eza-community/eza (replacement for https://github.com/ogham/exa)
if which eza > /dev/null 2>&1; then
  alias ls='eza --color-scale'
  alias ll='eza -l --all --no-user --changed --sort=modified --color-scale'
  alias lt='eza --tree --level 3 -l --no-permissions --no-user --no-time --color-scale'
else
  # setup ls
  ls / --color=auto > /dev/null 2>&1
  if [[ $? == 0 ]]; then
    alias ls='ls --color=auto'
  fi
fi

