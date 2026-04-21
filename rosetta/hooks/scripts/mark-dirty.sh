#!/usr/bin/env bash
# PostToolUse hook — records touched MDX paths for the end-of-turn check.
#
# Reads Claude Code's tool-call JSON from stdin, extracts tool_input.file_path,
# and if the path is an MDX file under rosetta-docs/src/content/docs/, appends
# it to a per-session marker file. check-on-stop.sh consumes the marker at Stop.
#
# Always exits 0 — this hook must never block a tool call.
#
# Requires: jq

set -uo pipefail

payload="$(cat)"

session_id="${CLAUDE_SESSION_ID:-}"
if [ -z "$session_id" ]; then
  session_id="$(printf '%s' "$payload" | jq -r '.session_id // "unknown"' 2>/dev/null || echo unknown)"
fi

file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")"

if [ -z "$file_path" ]; then
  exit 0
fi

# Match any MDX under rosetta-docs/src/content/docs/, at any nesting depth.
case "$file_path" in
  *rosetta-docs/src/content/docs/*.mdx)
    marker="/tmp/rosetta-dirty-${session_id}"
    printf '%s\n' "$file_path" >> "$marker"
    ;;
esac

exit 0
