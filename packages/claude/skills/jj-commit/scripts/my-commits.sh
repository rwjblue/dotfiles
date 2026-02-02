#!/bin/bash
# Show user's recent commit messages for style analysis
jj log --no-pager -r "mine() & ~empty()" --limit 15 -T 'description.first_line() ++ "\n"'
