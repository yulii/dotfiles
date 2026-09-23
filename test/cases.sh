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

# Deny: match each command against the Bash() rules of permissions.deny as
# shell globs.
rules="$work/deny"
jq -r '.permissions.deny[] | select(startswith("Bash(")) | .[5:-1]' \
  claude/settings.json >"$rules"
while IFS="$tab" read -r expect cmd; do
  got=pass
  while IFS= read -r r; do
    # shellcheck disable=SC2254 # the rule is the glob
    case "$cmd" in $r) got=deny ;; esac
  done <"$rules"
  if [ "$got" = "$expect" ]; then ok "deny $expect: $cmd"; else ng "deny $expect, got $got: $cmd"; fi
done <<EOF
$(cases test/cases/deny.tsv)
EOF

# WebFetch: a domain deny also denies the host to the sandbox. Check each rule
# of the table, then every deny rule of the settings. Wildcards follow the
# permissions docs: a bare * matches any host, a leading *. any subdomain, and
# any other * one label.
# shellcheck disable=SC2016 # $a, $r, $d are jq variables
cuts='[.sandbox.network.allowedDomains[]? | ascii_downcase] as $a
  | $r | capture("^WebFetch\\(domain:(?<d>[^)]+)\\)").d | ascii_downcase
  | . as $d
  | select($a | any(
      if $d == "*" then true
      elif ($d | startswith("*.")) then endswith($d[1:])
      else test("^" + ($d | gsub("\\."; "\\.") | gsub("\\*"; "[^.]+")) + "$")
      end))'
while IFS="$tab" read -r expect rule; do
  if [ -n "$(jq -r --arg r "$rule" "$cuts" claude/settings.json)" ]; then got='cut'; else got='keep'; fi
  if [ "$got" = "$expect" ]; then ok "webfetch $expect: $rule"; else ng "webfetch $expect, got $got: $rule"; fi
done <<EOF
$(cases test/cases/webfetch.tsv)
EOF
for f in claude/settings.json .claude/settings.json; do
  hit=$(jq -r '.permissions.deny[]?' "$f" | while IFS= read -r rule; do
    jq -r --arg r "$rule" "$cuts" "$f"
  done)
  if [ -z "$hit" ]; then ok "$f denies no sandbox domain to WebFetch"; else ng "$f denies a sandbox domain to WebFetch: $hit"; fi
done

# Ignore: ask git whether each path is ignored by this repository's
# .gitignore_global, in a scratch repository.
ign="$work/ignore"
git init -q "$ign"
while IFS="$tab" read -r expect path; do
  if git -C "$ign" -c core.excludesFile="$root/.gitignore_global" check-ignore -q --no-index "$path"; then
    got=ignored
  else
    got=tracked
  fi
  if [ "$got" = "$expect" ]; then ok "ignore $expect: $path"; else ng "ignore $expect, got $got: $path"; fi
done <<EOF
$(cases test/cases/ignore.tsv)
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
