#!/usr/bin/env bash
# Stop hook — runs `astro check` if any MDX was touched this turn.
#
# Reads the per-session marker written by mark-dirty.sh. If empty or missing,
# exits silently (no MDX work happened). Otherwise runs the docs site's check
# script (pnpm preferred, npm fallback) from the project's cwd. On failure,
# exits 2 with the check output on stderr so Claude Code surfaces the error
# back to the model instead of letting the turn end clean.
#
# Requires: jq (for session id lookup) and pnpm or npm on PATH.

set -uo pipefail

session_id="${CLAUDE_SESSION_ID:-}"
if [ -z "$session_id" ]; then
  payload="$(cat 2>/dev/null || true)"
  if [ -n "$payload" ]; then
    session_id="$(printf '%s' "$payload" | jq -r '.session_id // "unknown"' 2>/dev/null || echo unknown)"
  else
    session_id="unknown"
  fi
fi

marker="/tmp/rosetta-dirty-${session_id}"

# No MDX touched this turn → silent success.
if [ ! -s "$marker" ]; then
  rm -f "$marker"
  exit 0
fi

# Must have a rosetta-docs/ adjacent to cwd. If not, we're either in a
# non-rosetta project or the hook ran from an unexpected cwd — bail out silently
# rather than spurious-failing the turn.
if [ ! -d "rosetta-docs" ]; then
  rm -f "$marker"
  exit 0
fi

# Choose the package manager based on lockfile presence + PATH availability.
if [ -f "rosetta-docs/pnpm-lock.yaml" ] && command -v pnpm >/dev/null 2>&1; then
  output="$(pnpm -C rosetta-docs check 2>&1)"
  rc=$?
elif command -v npm >/dev/null 2>&1; then
  output="$(npm --prefix rosetta-docs run check 2>&1)"
  rc=$?
else
  echo "rosetta docs check skipped: neither pnpm nor npm found on PATH" >&2
  rm -f "$marker"
  exit 0
fi

rm -f "$marker"

if [ "$rc" -ne 0 ]; then
  {
    echo "rosetta-docs check failed (exit $rc). Fix the MDX issues before the turn can end:"
    echo
    echo "$output"
  } >&2
  exit 2
fi

exit 0
