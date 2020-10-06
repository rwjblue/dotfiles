#!/usr/bin/env zsh

# integrating with the same basic functionality as https://starship.rs/config/#git-status
#
# From https://github.com/starship/starship/blob/v0.45.2/src/modules/git_status.rs#L13-L26
#
# $conflicted$stashed$deleted$renamed$modified$staged$untracked$ahead_behind
# 
# $ahead_behind => Displays diverged ahead or behind format string based on the current status of the repo
#
# The following symbols will be used to represent the repo's status:
#   `=` – This branch has merge conflicts
#   `⇡` – This branch is ahead of the branch being tracked
#   `⇣` – This branch is behind of the branch being tracked
#   `⇕` – This branch has diverged from the branch being tracked
#   `?` — There are untracked files in the working directory
#   `$` — A stash exists for the local repository
#   `!` — There are file modifications in the working directory
#   `+` — A new file has been added to the staging area
#   `»` — A renamed file has been added to the staging area
#   `✘` — A file's deletion has been added to the staging area
#
function gitstatus_prompt_update() {
  local INDEX git_status=""

  # This logic is largely inspired by: https://github.com/denysdovhan/spaceship-prompt/blob/v3.11.2/sections/git_status.zsh
  INDEX=$(command git status --porcelain -b 2> /dev/null)

  # Check for unmerged files
  if $(echo "$INDEX" | command grep '^U[UDA] ' &> /dev/null); then
    git_status+="="
  elif $(echo "$INDEX" | command grep '^AA ' &> /dev/null); then
    git_status+="="
  elif $(echo "$INDEX" | command grep '^DD ' &> /dev/null); then
    git_status+="="
  elif $(echo "$INDEX" | command grep '^[DA]U ' &> /dev/null); then
    git_status+="+"
  fi

  # Check for stashes
  if $(command git rev-parse --verify refs/stash >/dev/null 2>&1); then
    git_status+="$"
  fi

  # Check for deleted files
  if $(echo "$INDEX" | command grep '^D[ UM] ' &> /dev/null); then
    # staged deleted
    git_status+="✘"
  fi

  # Check for renamed files
  if $(echo "$INDEX" | command grep '^R[ MD] ' &> /dev/null); then
    git_status+="»"
  fi

  # Check for modified files
  if $(echo "$INDEX" | command grep '^[ MARC]M ' &> /dev/null); then
    git_status+="!"
  fi

  # Check for untracked files
  if $(echo "$INDEX" | command grep -E '^\?\? ' &> /dev/null); then
    git_status="$SPACESHIP_GIT_STATUS_UNTRACKED$git_status"
  fi

  # Check for staged files
  if $(echo "$INDEX" | command grep '^A[ MDAU] ' &> /dev/null); then
    git_status+="+"
  elif $(echo "$INDEX" | command grep '^M[ MD] ' &> /dev/null); then
    git_status+="+"
  elif $(echo "$INDEX" | command grep '^UA' &> /dev/null); then
    git_status+="+"
  fi

  # Check whether branch is ahead
  local is_ahead=false
  if $(echo "$INDEX" | command grep '^## [^ ]\+ .*ahead' &> /dev/null); then
    is_ahead=true
  fi

  # Check whether branch is behind
  local is_behind=false
  if $(echo "$INDEX" | command grep '^## [^ ]\+ .*behind' &> /dev/null); then
    is_behind=true
  fi

  # Check wheather branch has diverged
  if [[ "$is_ahead" == true && "$is_behind" == true ]]; then
    git_status+="⇕"
  else
    [[ "$is_ahead" == true ]] && git_status+="⇡"
    [[ "$is_behind" == true ]] && git_status="⇣"
  fi

  echo -n "$git_status"
}
gitstatus_prompt_update
