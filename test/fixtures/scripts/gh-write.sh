#!/bin/sh
# Writes to GitHub through gh subcommands other than reads
gh pr view 1
gh pr merge 1 --squash
