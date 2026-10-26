#!/bin/sh
# Only reads: none of these write to GitHub
git status --short
git log --oneline -1
gh pr view 1
gh pr list --state merged
gh pr checks 1
gh run view 1 --log
gh api repos/o/r/pulls --jq '.[].number'
gh api -X GET search/code -f q=x
