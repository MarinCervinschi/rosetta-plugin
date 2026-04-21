#!/usr/bin/env bash
# PreToolUse(Write) hook — one-shot personalization guard.
#
# When Write targets rosetta-docs/src/rosetta.config.json, compare the incoming
# content against the current on-disk file. If the current file already has
# `"personalized": true` AND the incoming write changes the identity
# (name or tagline), block — the personalize-docs skill is one-shot on
# purpose, and re-personalization clobbers user-written landing-page prose.
#
# Pass-through cases:
#   - current file is missing or has personalized=false (first personalization)
#   - incoming has personalized=false (legitimate reset — the skill's contract
#     says set personalized=false manually if you want to re-personalize)
#   - incoming name+tagline match current (idempotent write; harmless)
#
# Block case: current personalized=true AND incoming personalized=true AND
# (name OR tagline differs). Exit 2 with stderr so Claude Code surfaces the
# error to the model instead of silently clobbering.
#
# Requires: jq.

set -uo pipefail

payload="$(cat 2>/dev/null || echo '')"
[ -z "$payload" ] && exit 0

file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo '')"
content="$(printf '%s' "$payload" | jq -r '.tool_input.content // ""' 2>/dev/null || echo '')"

# Only guard the personalization config.
case "$file_path" in
  *rosetta-docs/src/rosetta.config.json) ;;
  *) exit 0 ;;
esac

# If the on-disk file doesn't exist yet, this is a first-write — nothing to protect.
if [ ! -f "$file_path" ]; then
  exit 0
fi

current_personalized="$(jq -r '.personalized // false' "$file_path" 2>/dev/null || echo false)"
if [ "$current_personalized" != "true" ]; then
  exit 0
fi

# Parse incoming content as JSON. If it isn't valid JSON, let the skill or
# astro check catch it — we're not a syntax gate.
incoming_personalized="$(printf '%s' "$content" | jq -r '.personalized // false' 2>/dev/null || echo '')"
if [ -z "$incoming_personalized" ] || [ "$incoming_personalized" != "true" ]; then
  exit 0
fi

current_name="$(jq -r '.name // ""' "$file_path" 2>/dev/null || echo '')"
current_tagline="$(jq -r '.tagline // ""' "$file_path" 2>/dev/null || echo '')"
incoming_name="$(printf '%s' "$content" | jq -r '.name // ""' 2>/dev/null || echo '')"
incoming_tagline="$(printf '%s' "$content" | jq -r '.tagline // ""' 2>/dev/null || echo '')"

if [ "$current_name" = "$incoming_name" ] && [ "$current_tagline" = "$incoming_tagline" ]; then
  # Same identity — metadata refresh, harmless.
  exit 0
fi

{
  echo "rosetta personalize-guard: blocked write to $file_path"
  echo
  echo "  The site is already personalized as:"
  echo "    name:    \"$current_name\""
  echo "    tagline: \"$current_tagline\""
  echo
  echo "  Incoming write would change identity to:"
  echo "    name:    \"$incoming_name\""
  echo "    tagline: \"$incoming_tagline\""
  echo
  echo "  The /rosetta:personalize-docs skill is one-shot by design — re-personalization"
  echo "  clobbers landing-page prose the user may have written after the first run."
  echo
  echo "  To change identity metadata, edit rosetta-docs/src/rosetta.config.json by hand."
  echo "  To fully re-personalize, first set \"personalized\": false in the config, then re-run"
  echo "  /rosetta:personalize-docs."
} >&2
exit 2
