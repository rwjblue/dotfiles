# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

source $ZSH/oh-my-zsh.sh

alias 'ps?'='ps aux | grep'

# Customize to your needs...
export PATH=$HOME/bin:/usr/local/bin:/usr/local/share/npm/bin:/usr/texbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

PROMPT='%1~ %{$fg_bold[red]%}$(command git rev-parse --abbrev-ref HEAD 2> /dev/null)%{$reset_color%}%{$fg[yellow]%} %# %{$reset_color%}'

############################################
# FASD - Command-line productivity booster #
############################################
#
# EXAMPLE BEHAVIORS
# ```
#   v def conf       =>     vim /some/awkward/path/to/type/default.conf
#   z abc            =>     cd /hell/of/a/awkward/path/to/get/to/abcdef
# ```

eval "$(fasd --init auto)"

alias a='fasd -a'        # any
alias s='fasd -si'       # show / search / select
alias d='fasd -d'        # directory
alias f='fasd -f'        # file
alias v='fasd -e vim'    # open the file with vim
alias sd='fasd -sid'     # interactive directory selection
alias sf='fasd -sif'     # interactive file selection
alias z='fasd_cd -d'     # cd, same functionality as j in autojump
alias zz='fasd_cd -d -i' # cd with interactive selection

_FASD_BACKENDS="native viminfo"

alias gst='git status -sb'    # use short version of git status
alias gup='git pull --rebase' # rebase by default
alias gap='git add -p'        # the best way to run git add
alias gd='git diff'           # show unstaged changes
alias gds='git diff --staged' # show staged changes
alias gdh='git diff HEAD'     # show staged changes

export EDITOR="/usr/local/bin/vim"
export BUNDLER_EDITOR="/usr/local/bin/vim"
export CC=/usr/local/bin/gcc-4.2

export RUBY_GC_MALLOC_LIMIT=60000000
export RUBY_FREE_MIN=200000

# deploy remotely
alias cap_deploy_remote="cap deploy RAILS_ENV=development_remote && ps ax | grep orb-runner-gateway | cut -d' ' -f1 | xargs kill"
