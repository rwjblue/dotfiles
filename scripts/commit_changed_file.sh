#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <file_path> <commit_message>"
  exit 1
fi

FILE_PATH=$1
COMMIT_MSG=$2

# Covers both modified and untracked files.
has_changes() {
  if [[ "$VCS" == "jj" ]]; then
    [ -n "$(jj diff --summary "$FILE_PATH")" ]
  else
    [ -n "$(git status --porcelain -- "$FILE_PATH")" ]
  fi
}

commit_changes() {
  if [[ "$VCS" == "jj" ]]; then
    jj commit --quiet "$FILE_PATH" -m "$COMMIT_MSG" || {
      echo "Failed to commit changes in $FILE_PATH" >&2
      return 1
    }
  else
    git add -- "$FILE_PATH" || {
      echo "Failed to stage $FILE_PATH" >&2
      return 1
    }

    git commit -m "$COMMIT_MSG" -- "$FILE_PATH" || {
      echo "Failed to commit changes in $FILE_PATH" >&2
      return 1
    }
  fi

  echo "Changes in $FILE_PATH committed successfully with message: $COMMIT_MSG"
}

if command -v jj &>/dev/null && jj root &>/dev/null; then
  VCS="jj"
else
  VCS="git"
fi

if has_changes; then
  commit_changes
else
  echo "No changes in $FILE_PATH"
fi
