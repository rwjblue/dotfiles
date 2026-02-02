#!/bin/bash
# Get commit messages in the branch (from trunk to @-)
jj log --no-pager -r "trunk()..@-" -T 'description ++ "\n---\n"'
