#!/bin/sh
# PreToolUse hook for git branch. Force-deleting or overwriting a branch
# asks, since unmerged commits may be lost.
#
# A lone git branch -D is allowed when every branch is the head of a merged
# pull request at the same commit. Squash merges make git branch -d fail, and
# the commit check keeps anything added after the merge.
# Anything else, or a failing gh, keeps the ask. GUARD_BRANCH_GH replaces gh
# in tests.
g='git([[:space:]]+(-[Cc]|--(git-dir|work-tree|namespace|config-env))[[:space:]]+[^[:space:]]+|[[:space:]]+-[^[:space:]]+)*[[:space:]]+'
c=$(jq -r '.tool_input.command // ""')
printf '%s\n' "$c" | tr ';|&' '\n' |
  grep -Eq -e "$g"'branch([[:space:]].*)?[[:space:]](--force|-[a-zA-Z]*[DMCf][a-zA-Z]*)([[:space:]]|$)' ||
  exit 0

decide() {
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}
ask() { decide ask 'ブランチを強制的に消す・上書きする操作。マージされていないコミットを失うおそれがある。'; }

# One line, git branch -D, then plain branch names: no quotes or expansions
name='[A-Za-z0-9._/][A-Za-z0-9._/-]*'
[ "$(printf '%s\n' "$c" | wc -l)" -eq 1 ] || ask
printf '%s' "$c" | grep -Eq "^git[[:space:]]+branch[[:space:]]+-D([[:space:]]+$name)+[[:space:]]*\$" || ask

for b in $(printf '%s' "$c" | sed -E 's/^git[[:space:]]+branch[[:space:]]+-D//'); do
  oid=$(git rev-parse -q --verify "refs/heads/$b") || ask
  heads=$("${GUARD_BRANCH_GH:-gh}" pr list --head "$b" --state merged --json headRefOid --jq '.[].headRefOid' 2>/dev/null) || ask
  printf '%s\n' "$heads" | grep -qx "$oid" || ask
done
decide allow 'どのブランチも、マージ済みの PR の head と同じコミットを指している。'
