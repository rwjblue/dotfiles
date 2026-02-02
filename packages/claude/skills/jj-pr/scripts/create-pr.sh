#!/bin/bash
# Create a draft PR with the given branch and title, reading body from stdin
# Usage: create-pr.sh <bookmark-name> <title> <<'EOF'
#        multiline body
#        EOF
gh pr create --draft --head "$1" --title "$2" --body-file -
