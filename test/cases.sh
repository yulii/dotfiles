#!/bin/sh
# Table-driven checks. Each file under test/cases lists inputs and the
# expected result, one per line: expect<TAB>input. # starts a comment.
set -eu

cd "$(dirname "$0")/.."
root=$(pwd)

fail=0
ng() { printf 'NG  %s\n' "$1"; fail=1; }
ok() { printf 'ok  %s\n' "$1"; }

tab=$(printf '\t')
work=$(mktemp -d "${TMPDIR:-/tmp}/cases.XXXXXX")
trap 'rm -rf "$work"' EXIT

# Print "expect<TAB>input" lines without comments or blanks.
cases() { grep -vE '^(#|$)' "$1"; }

# Hooks: run every Bash PreToolUse hook of the global settings and keep the
# strictest decision. They run in an empty directory, outside any repository.
hooks="$work/hooks"
jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[].command' \
  claude/settings.json >"$hooks"
mkdir "$work/empty"
while IFS="$tab" read -r expect cmd; do
  got=pass
  while IFS= read -r h; do
    d=$(jq -n --arg c "$cmd" '{tool_input: {command: $c}}' |
      (cd "$work/empty" && sh -c "$h") |
      jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null || true)
    case "$d:$got" in
      deny:*) got=deny ;;
      ask:pass) got=ask ;;
    esac
  done <"$hooks"
  if [ "$got" = "$expect" ]; then ok "hook $expect: $cmd"; else ng "hook $expect, got $got: $cmd"; fi
done <<EOF
$(cases test/cases/hooks.tsv)
EOF

# Secrets: stage each line in a scratch repository and scan the index, as the
# commit hook does. The patterns come from this repository's .gitconfig, not
# from whatever is linked into $HOME.
repo="$work/repo"
export GIT_CONFIG_GLOBAL="$root/.gitconfig" GIT_CONFIG_NOSYSTEM=1
git init -q "$repo"
while IFS="$tab" read -r expect line; do
  printf '%s\n' "$line" >"$repo/f.txt"
  git -C "$repo" add f.txt
  if (cd "$repo" && git secrets --scan --cached >/dev/null 2>&1); then got=pass; else got=detect; fi
  if [ "$got" = "$expect" ]; then ok "secrets $expect: $line"; else ng "secrets $expect, got $got: $line"; fi
done <<EOF
$(cases test/cases/secrets.tsv)
EOF

exit $fail
