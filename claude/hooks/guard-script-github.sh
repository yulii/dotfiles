#!/bin/sh
# PreToolUse hook for Bash. A script file run by sh, bash, zsh, dash, ., source,
# or python asks when its contents push or write to GitHub. The other hooks and
# the permission rules see only the command line, and the sandbox still holds
# the GitHub credentials (git push and gh pr create succeed in it), so a push
# inside a script ran without a prompt.
#
# Shell scripts: quoted text and comments are not read, and git or gh must be
# at a command position. Python: quotes, commas, brackets, and parentheses
# become spaces, so ["git", "push"] reads as git push.
# gh passes for help, search, status, view, list, diff, checks, watch,
# auth status without a token flag, and gh api without a method other than
# GET or fields without -X GET. Anything else asks.
#
# Missed: a script that another script or make runs, commands built from
# variables or decoded text, sh < file, xargs sh, and other interpreters.
input=$(cat)
c=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

# kind<TAB>path for every segment that runs a script file. sh -c and
# python -c or -m run no file
files=$(printf '%s\n' "$c" | tr ';|&' '\n' | awk -v q="'" '
  {
    n = split($0, w, /[[:space:]]+/); i = 1
    while (i <= n && (w[i] == "" || w[i] ~ /^[({]+$/ || w[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/)) i++
    if (i > n) next
    cmd = w[i]; sub(/^.*\//, "", cmd)
    if (cmd ~ /^(sh|bash|zsh|dash)$/) { kind = "sh"; bad = "c" }
    else if (cmd ~ /^python3?(\.[0-9]+)?$/) { kind = "py"; bad = "[cm]" }
    else if (cmd == "." || cmd == "source") { kind = "sh"; bad = "" }
    else next
    for (i++; i <= n && w[i] ~ /^-/; i++)
      if (bad != "" && w[i] ~ ("^-[A-Za-z]*" bad)) next
    if (i > n) next
    f = w[i]; gsub(q, "", f); gsub(/"/, "", f)
    print kind "\t" f
  }')
[ -n "$files" ] || exit 0

# Print the first line of the file that pushes or writes to GitHub
scan() {
  awk -v py="$1" -v q="'" '
    function ghwrite(rest,   w, s, t, m) {
      split(rest, w, /[[:space:]]+/); s = w[1]; t = w[2]
      if (s ~ /^(help|--help|version|--version|search|status|completion)$/) return 0
      if (s == "api") {
        if (match(rest, /(-X|--method)(=|[[:space:]]*)[A-Za-z]+/)) {
          m = toupper(substr(rest, RSTART, RLENGTH)); sub(/^(-X|--METHOD)(=|[[:space:]]*)/, "", m)
          return m != "GET"
        }
        return rest ~ /(^|[[:space:]])(-f|-F|--field|--raw-field|--input)([[:space:]=]|$)/
      }
      if (s == "auth") return !(t == "status" && rest !~ /(^|[[:space:]])(-t|--show-token)([[:space:]]|$)/)
      return t !~ /^(view|list|status|diff|checks|watch)$/
    }
    BEGIN {
      if (py) pos = "(^|[[:space:]])"
      else pos = "(^|[;&|({`]|\\$\\(|(do|then|else|exec|command|xargs|time|env|nohup)[[:space:]])[[:space:]]*"
      push = pos "git([[:space:]]+(-[Cc]|--(git-dir|work-tree|namespace|config-env))[[:space:]]+[^[:space:]]+|[[:space:]]+-[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)"
      gh = pos "gh[[:space:]]+"
    }
    {
      l = $0
      if (py) gsub("[\"" q ",()\\[\\]]", " ", l)
      else { sub(/^[[:space:]]*#.*/, "", l); gsub(q "[^" q "]*" q, "", l); gsub(/"[^"]*"/, "", l) }
      if (l ~ push) { print $0; exit }
      while (match(l, gh)) {
        rest = substr(l, RSTART + RLENGTH); l = rest
        if (ghwrite(rest)) { print $0; exit }
      }
    }' "$2"
}

tab=$(printf '\t')
printf '%s\n' "$files" | while IFS="$tab" read -r kind f; do
  case "$f" in
    \~/*) f="$HOME/${f#\~/}" ;;
    /*) ;;
    *) f="${cwd:-$PWD}/$f" ;;
  esac
  [ -f "$f" ] && [ -r "$f" ] || continue
  py=0; [ "$kind" = py ] && py=1
  hit=$(scan "$py" "$f" | cut -c1-160)
  [ -n "$hit" ] || continue
  jq -n --arg f "$f" --arg l "$hit" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: "スクリプト \($f) に push か GitHub への書き込みがある: \($l)"}}'
  break
done
exit 0
