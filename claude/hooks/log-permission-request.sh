#!/bin/sh
# PermissionRequest hook: append each request to
# ~/.claude/permission-requests-YYYY-MM.jsonl, one JSON object per line. The
# month is in UTC, as is the time field. Old months are removed by hand.
# It returns no decision, so the permission prompt behaves as before.
#
# permission_suggestions lists the rules that would allow the call, which
# shows the subcommands that caused the prompt. agent_type is set inside a
# subagent.
#
# Values assigned to *_KEY, *_PASSWORD, *_SECRET, *_TOKEN and Bearer values
# are masked. A value ends at whitespace, a quote, ;, & or |.
# \x27 is a single quote, which cannot appear inside the sh quotes.
jq -c '{time: (now | todate), cwd, session_id, agent_type, permission_mode,
    permission_suggestions, tool_name, tool_input}
  | walk(if type == "string"
      then gsub("(?<k>[A-Za-z0-9_]*(_KEY|_PASSWORD|_SECRET|_TOKEN))=[^\\s\"\\x27;&|]+"; "\(.k)=***")
        | gsub("Bearer [^\\s\"\\x27;&|]+"; "Bearer ***")
      else . end)' >>"$HOME/.claude/permission-requests-$(date -u +%Y-%m).jsonl"
