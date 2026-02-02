#!/bin/bash
# Check if a PR exists for the given branch
# Usage: check-pr.sh <bookmark-name>
# Returns JSON with url if exists, empty/error if not
gh pr view "$1" --json url,state,title 2>/dev/null
