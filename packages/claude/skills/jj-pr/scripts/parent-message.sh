#!/bin/bash
# Get the commit message at @- for branch naming
jj log --no-pager -r "@-" -T 'description.first_line()'
