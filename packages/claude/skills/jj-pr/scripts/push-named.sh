#!/bin/bash
# Create a new bookmark and push
# Usage: push-named.sh bookmark-name
jj git push --named "$1=@-"
