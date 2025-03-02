#!/bin/zsh

# Ensure both FILE_PATH and COMMIT_MSG are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <file_path> <commit_message>"
  exit 1
fi

FILE_PATH=$1
COMMIT_MSG=$2

# Function to check if file has changes
check_for_changes() {
  local vcs=$1

  if [[ "$vcs" == "jj" ]]; then
    jj diff "$FILE_PATH" | grep . -q
    return $?
  else
    # For git, return 1 if there are changes (opposite of git's exit code)
    git diff --quiet "$FILE_PATH"
    return $((!$?))
  fi
}

# Function to commit changes
commit_changes() {
  local vcs=$1

  if [[ "$vcs" == "jj" ]]; then
    jj commit --quiet "$FILE_PATH" -m "$COMMIT_MSG" || {
      echo "Failed to commit changes in $FILE_PATH" >&2
      return 1
    }
  else
    git add "$FILE_PATH" || {
      echo "Failed to stage $FILE_PATH" >&2
      return 1
    }

    git commit -m "$COMMIT_MSG" || {
      echo "Failed to commit changes in $FILE_PATH" >&2
      return 1
    }
  fi

  echo "Changes in $FILE_PATH committed successfully with message: $COMMIT_MSG"
  return 0
}

# Determine which VCS to use
if command -v jj &>/dev/null && jj root &>/dev/null; then
  VCS="jj"
else
  VCS="git"
fi

# Check for changes and commit if needed
if check_for_changes "$VCS"; then
  commit_changes "$VCS"
  exit $?
else
  echo "No changes in $FILE_PATH"
  exit 0
fi
