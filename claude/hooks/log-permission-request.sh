#!/bin/sh
# PermissionRequest hook: append each request to
# ~/.claude/permission-requests.jsonl, one JSON object per line.
# It returns no decision, so the permission prompt behaves as before.
#
# Values assigned to *_KEY, *_PASSWORD, *_SECRET, *_TOKEN and Bearer values
# are masked. A value ends at whitespace, a quote, ;, & or |.
# \x27 is a single quote, which cannot appear inside the sh quotes.
jq -c '{time: (now | todate), cwd, session_id, permission_mode,
    permission_verdict, tool_name, tool_input}
  | walk(if type == "string"
      then gsub("(?<k>[A-Za-z0-9_]*(_KEY|_PASSWORD|_SECRET|_TOKEN))=[^\\s\"\\x27;&|]+"; "\(.k)=***")
        | gsub("Bearer [^\\s\"\\x27;&|]+"; "Bearer ***")
      else . end)' >>"$HOME/.claude/permission-requests.jsonl"
