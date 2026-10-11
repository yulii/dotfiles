#!/bin/sh
# PreToolUse hook for Bash. A command in sandbox.excludedCommands runs outside
# the sandbox only when it stands alone. Chained by |, ;, && or a newline, it
# runs in the sandbox, where writes to protected paths stop it midway and the
# allow rules for it do not apply. Deny it with the reason, so it is run again
# alone.
#
# Quotes, heredoc bodies, and redirections such as 2>&1 are not read, so a
# command named in a message passes. Missed: sh -c, ( ), $( ), and git -C.
# The list comes from the global settings; without it the hook passes.
s="$HOME/.claude/settings.json"
c=$(jq -r '.tool_input.command // ""')

# Drop everything after the first heredoc, then quotes and N>&M, &>
bare=$(printf '%s\n' "$c" |
  awk '/<</ { print; exit } { print }' |
  sed -E "s/('[^']*'|\"([^\"\\\\]|\\\\.)*\")//g; s/[0-9]*>&[0-9-]//g; s/&>//g")
printf '%s' "$bare" | grep -Eq '[|;&]' || [ "$(printf '%s\n' "$bare" | wc -l)" -gt 1 ] || exit 0

# "git pull *" becomes git[[:space:]]+pull
ex=$(jq -r '.sandbox.excludedCommands[]? | sub(" \\*$"; "")' "$s" 2>/dev/null |
  sed -E 's/[][\.^$+?(){}|]/\\&/g; s/[[:space:]]+/[[:space:]]+/g' | paste -sd '|' -)
[ -n "$ex" ] || exit 0

head='(^|[|;&])[[:space:]]*((do|then|else)[[:space:]]+)?'
printf '%s\n' "$bare" | grep -Eq "$head($ex)([[:space:]]|\$)" || exit 0

jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
  permissionDecisionReason: "sandbox.excludedCommands のコマンドは単独で実行する。|・;・&&・改行で連結すると sandbox の中で走り、allow も効かない。1 コマンドずつ実行し、出力は実行後に絞る。2>&1 は付けてよい。"}}'
exit 0
