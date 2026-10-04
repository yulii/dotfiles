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

# Hook scripts are run through a scratch HOME that links them as init/links
# does.
mkdir -p "$work/home/.claude/hooks"
grep -E '^claude/hooks/' init/links | while read -r src dst; do
  ln -s "$root/$src" "$work/home/$dst"
done

# Hooks: run every Bash PreToolUse hook of the global settings and keep the
# strictest decision, in the order deny, ask, allow. They run in a scratch
# repository on the branch topic. The branches merged, feature/merged, and
# later have a merged pull request whose head is the first commit, and later
# has moved on since.
# The gh stub fails for ghfail and finds no pull request for other branches.
hooks="$work/hooks"
jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[].command' \
  claude/settings.json >"$hooks"
topic="$work/topic"
git init -q -b topic "$topic"
commit() { git -C "$topic" -c user.name=t -c user.email=t@example.com commit -q --allow-empty --no-verify -m "$1"; }
commit first
first=$(git -C "$topic" rev-parse HEAD)
git -C "$topic" branch merged
git -C "$topic" branch feature/merged
git -C "$topic" branch ghfail
git -C "$topic" branch unmerged
commit second
git -C "$topic" branch later
cat >"$work/gh" <<EOF
#!/bin/sh
# gh pr list --head <branch> --state merged --json headRefOid --jq ...
case "\$4" in
  merged | feature/merged | later) echo $first ;;
  ghfail) exit 1 ;;
esac
EOF
chmod +x "$work/gh"
while IFS="$tab" read -r expect cmd; do
  got=pass
  while IFS= read -r h; do
    d=$(jq -n --arg c "$cmd" '{tool_input: {command: $c}}' |
      (cd "$topic" && HOME="$work/home" GUARD_BRANCH_GH="$work/gh" sh -c "$h") |
      jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null || true)
    case "$d:$got" in
      deny:*) got=deny ;;
      ask:pass | ask:allow) got=ask ;;
      allow:pass) got=allow ;;
    esac
  done <"$hooks"
  if [ "$got" = "$expect" ]; then ok "hook $expect: $cmd"; else ng "hook $expect, got $got: $cmd"; fi
done <<EOF
$(cases test/cases/hooks.tsv)
EOF

# Permission log: run every PermissionRequest hook of the global settings with
# HOME in a scratch directory, then read back the last logged command. The
# suggested rule carries the same command and must be masked the same way.
# The log is split by month, so read the newest file. The hooks must print
# nothing, or Claude Code may take the output as a decision.
plog="$work/plog"
jq -r '.hooks.PermissionRequest[]?.hooks[].command' claude/settings.json >"$plog"
while IFS="$tab" read -r expect cmd; do
  out=
  while IFS= read -r h; do
    out=$out$(jq -n --arg c "$cmd" \
      '{session_id: "s", cwd: "/x", agent_type: "Explore", tool_name: "Bash", tool_input: {command: $c},
        permission_suggestions: [{type: "addRules", rules: [{toolName: "Bash", ruleContent: $c}]}]}' |
      HOME="$work/home" sh -c "$h")
  done <"$plog"
  log=
  for f in "$work"/home/.claude/permission-requests-*.jsonl; do [ -f "$f" ] && log=$f; done
  got=$( [ -n "$log" ] && tail -n 1 "$log" |
    jq -r 'if .agent_type == "Explore" and .permission_suggestions[0].rules[0].ruleContent == .tool_input.command
      then .tool_input.command else "suggestion or agent_type differs" end' || true)
  if [ "$got" != "$expect" ]; then
    ng "permission-log $expect, got $got: $cmd"
  elif [ -n "$out" ]; then
    ng "permission-log printed $out: $cmd"
  else
    ok "permission-log $expect: $cmd"
  fi
done <<EOF
$(cases test/cases/permission-log.tsv)
EOF

# Deny and ask: match each command against the Bash() rules of
# permissions.deny or permissions.ask as shell globs.
for kind in deny ask; do
  rules="$work/$kind"
  jq -r --arg k "$kind" '.permissions[$k][]? | select(startswith("Bash(")) | .[5:-1]' \
    claude/settings.json >"$rules"
  while IFS="$tab" read -r expect cmd; do
    got=pass
    while IFS= read -r r; do
      # shellcheck disable=SC2254 # the rule is the glob
      case "$cmd" in $r) got=$kind ;; esac
    done <"$rules"
    if [ "$got" = "$expect" ]; then ok "$kind $expect: $cmd"; else ng "$kind $expect, got $got: $cmd"; fi
  done <<EOF
$(cases "test/cases/$kind.tsv")
EOF
done

# WebFetch: a domain deny also denies the host to the sandbox. Check each rule
# of the table, then every deny rule of the settings. The sandbox honors a
# bare * and a leading *. that excludes the apex; any other * has no effect.
# shellcheck disable=SC2016 # $a, $r, $d are jq variables
cuts='[.sandbox.network.allowedDomains[]? | ascii_downcase] as $a
  | $r | capture("^WebFetch\\(domain:(?<d>[^)]+)\\)").d | ascii_downcase
  | . as $d
  | select($a | any(
      if $d == "*" then true
      elif ($d | startswith("*.")) then endswith($d[1:])
      else . == $d
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
