# pyenv is _sooooo_ slow so we only want to run it when we actually need it
function pyenv_init() {
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

  unalias pyenv

  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  echo "pyenv initialized; re-run your command"
}

alias pyenv=pyenv_init
