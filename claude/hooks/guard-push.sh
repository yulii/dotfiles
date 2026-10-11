#!/bin/sh
# PreToolUse hook for git push. Every push asks, except git push origin HEAD
# from a branch other than main, master, or develop. Force pushes are denied
# by permissions.deny; this hook asks for the forms those rules miss.
#
# The command is split on ;, |, & and newlines without reading quotes, so a
# push written inside a message also asks.
g='git([[:space:]]+(-[Cc]|--(git-dir|work-tree|namespace|config-env))[[:space:]]+[^[:space:]]+|[[:space:]]+-[^[:space:]]+)*[[:space:]]+'
c=$(jq -r '.tool_input.command // ""')

printf '%s\n' "$c" | tr ';|&' '\n' | while IFS= read -r l; do
  printf '%s' " $l" | grep -Eq "$g"'push([[:space:]]|$)' || continue
  # 2>&1 is split at &, which leaves 2> at the end
  if printf '%s' "$l" | grep -Eq '^[[:space:]]*git[[:space:]]+push[[:space:]]+origin[[:space:]]+HEAD[[:space:]]*(2>)?[[:space:]]*$'; then
    case $(git symbolic-ref --short -q HEAD) in
      '' | main | master | develop) ;;
      *) continue ;;
    esac
  fi
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask",
    permissionDecisionReason: "外へ出す push。確認なしで通すのは、main・master・develop 以外のブランチからの git push origin HEAD だけ。"}}'
  break
done
exit 0
