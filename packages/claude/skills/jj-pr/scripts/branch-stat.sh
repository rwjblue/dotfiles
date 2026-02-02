#!/bin/bash
# Get diff stats for the branch
jj diff --stat -r "trunk()..@-"
