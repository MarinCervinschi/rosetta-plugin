#!/usr/bin/env bash
# PreToolUse(Write) hook — early frontmatter sanity check on MDX writes.
#
# When Write targets an MDX under rosetta-docs/src/content/docs/<category>/,
# parse the incoming content's `category:` field and compare it to the parent
# Diátaxis folder segment. A mismatch is the #1 build failure for new pages —
# catching it here surfaces a specific error before the Stop hook runs
# `astro check`, which is both slower and more cryptic.
#
# Warning-only: exit 1 + stderr, never exit 2 (block). A user may legitimately
# move a page across folders during a Diátaxis reorg — `astro check` remains
# the authoritative gate.
#
# Requires: jq, awk. Silent-pass on anything unexpected.

set -uo pipefail

payload="$(cat 2>/dev/null || echo '')"
[ -z "$payload" ] && exit 0

file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo '')"
content="$(printf '%s' "$payload" | jq -r '.tool_input.content // ""' 2>/dev/null || echo '')"

# Only concerned with MDX under rosetta-docs/src/content/docs/.
case "$file_path" in
  *rosetta-docs/src/content/docs/*.mdx) ;;
  *) exit 0 ;;
esac

# Extract the parent Diátaxis folder: the path segment immediately after
# `rosetta-docs/src/content/docs/`. Sub-grouping folders are allowed
# (e.g. how-to/deploy/vercel.mdx) — the Diátaxis folder is the first segment.
diataxis_folder="$(printf '%s' "$file_path" \
  | awk 'match($0, /rosetta-docs\/src\/content\/docs\/([^\/]+)/, a) {print a[1]}')"

case "$diataxis_folder" in
  tutorials|how-to|reference|explanation) ;;
  *) exit 0 ;;  # Not one of the four known folders — let astro check decide.
esac

# Extract the `category:` field from the frontmatter (between the first two --- lines).
category="$(printf '%s' "$content" \
  | awk '/^---$/{f++; next} f==1 && /^category:/{print; exit}' \
  | sed -E 's/^category:[[:space:]]*//; s/^["'\''"]//; s/["'\''"]$//; s/[[:space:]]+$//')"

# No frontmatter category → let the schema catch it. This guard is only for the mismatch case.
[ -z "$category" ] && exit 0

if [ "$category" != "$diataxis_folder" ]; then
  {
    echo "rosetta frontmatter-guard: category mismatch in ${file_path}"
    echo "  frontmatter category: \"$category\""
    echo "  parent folder:        \"$diataxis_folder\""
    echo
    echo "  The \`category\` frontmatter must equal the parent Diátaxis folder."
    echo "  Either move the file to rosetta-docs/src/content/docs/$category/,"
    echo "  or change the frontmatter to 'category: $diataxis_folder'."
    echo
    echo "  (Warning only — the Write will proceed. astro check would fail at end-of-turn.)"
  } >&2
  exit 1
fi

exit 0
