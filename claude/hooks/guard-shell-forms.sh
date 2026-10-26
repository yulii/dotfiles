#!/bin/sh
# PreToolUse hook for Bash. Deny the shell forms that Claude Code cannot check
# before they run, so it asks for nearly every one even in the sandbox:
#   - for, while, and until loops (92-99% asked)
#   - NAME=$(...) and NAME=`...` (93% asked)
#   - awk, which the sandbox never auto-allows (13 of 14 alone were asked)
#   - a heredoc written to a file (94% asked into a $VAR path, 28% into a
#     plain path); the Write tool writes files. A heredoc on stdin passes
#   - git -c, whose config values such as core.pager run commands
# Rates are from the permission log and transcripts, 2026-10-18 to 10-26.
# A script file run with sh is not asked, loops and all, so the reason says to
# write one. Plain variables such as $TMPDIR or X=literal are mostly not asked
# and pass.
#
# This steers tool choice, which the global CLAUDE.md leaves to denied
# prompts. Those prompts were approved 99% of the time, so the hook denies
# them up front instead.
#
# Heredoc bodies, backslash escapes, and single quotes are not read, so a
# loop in a message or an awk program passes. Missed: sh -c '...', a command
# after time, env, or xargs, and double quotes that hold ; or |.
c=$(jq -r '.tool_input.command // ""')

# Drop heredoc bodies up to their delimiter. <<< is a here-string, not a heredoc
bodies=$(printf '%s\n' "$c" | awk -v q="'" '
  skip { t = $0; if (dash) sub(/^\t+/, "", t); if (t == delim) skip = 0; next }
  { print; s = $0 }
  {
    i = index(s, "<<")
    while (i > 0 && substr(s, i + 2, 1) == "<") { s = substr(s, i + 3); i = index(s, "<<") }
    if (i == 0) next
    r = substr(s, i + 2)
    dash = (substr(r, 1, 1) == "-")
    if (dash) r = substr(r, 2)
    sub(/^[ \t]*/, "", r)
    gsub(q, "", r)
    gsub(/["\\]/, "", r)
    if (match(r, /^[A-Za-z_][A-Za-z0-9_]*/)) { delim = substr(r, 1, RLENGTH); skip = 1 }
  }')

# Then backslash escapes and single quotes, which may span lines
rs=$(printf '\036')
bare=$(printf '%s\n' "$bodies" | sed 's/\\.//g' | tr '\n' "$rs" |
  sed "s/'[^']*'//g" | tr "$rs" '\n')

head='(^|[;&|({`])[[:space:]]*((do|then|else|elif|!)[[:space:]]+)*'
reason=
if printf '%s\n' "$bare" | grep -Eq "$head(for|while|until)([[:space:]]|\$)" ||
  printf '%s\n' "$bare" | grep -Eq '(^|[[:space:];&|(])[A-Za-z_][A-Za-z0-9_]*=(\$\(|`)'; then
  # shellcheck disable=SC2016 # $(…) is text for Claude, not an expansion
  reason='ループと 名前=$(…) は Claude Code が実行前に確かめられず、承認要求になる。スクラッチパッドにスクリプトを書き、sh <パス> で実行する。ファイルの中のループは止まらない。'
fi
if printf '%s\n' "$bare" | grep -Eq "${head}awk([[:space:]]|\$)"; then
  reason="${reason}awk は sandbox の自動許可から外れ、承認要求になる。行の範囲は Read の offset と limit か sed -n 'a,bp'、抽出は grep を使う。集計はスクラッチパッドのスクリプトに書き、sh で実行する。"
fi
# A heredoc line that also redirects to a file or runs tee. N>&M, >&N, and
# /dev/null are not files
if printf '%s\n' "$bare" | grep -E '<<' | grep -vE '<<<' |
  sed -E 's/[0-9]*>&[0-9-]+//g; s/[0-9]*>>?[[:space:]]*\/dev\/null//g' |
  grep -Eq "(>|${head}tee([[:space:]]|\$))"; then
  reason="${reason}ヒアドキュメントでファイルを書き出すと承認要求になる。ファイルは Write ツールで書く（スクラッチパッドのパスかプロジェクトの中。.claude/ の下は確認が出る）。"
fi
if printf '%s\n' "$bare" | grep -Eq "${head}git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?-c[[:space:]]"; then
  reason="${reason}git -c は設定の値でコマンドを動かせるため承認要求になる。core.pager=cat は git --no-pager にし、他の設定は付けずに済む形を選ぶ。"
fi
[ -n "$reason" ] || exit 0

jq -n --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse",
  permissionDecision: "deny", permissionDecisionReason: $r}}'
exit 0
