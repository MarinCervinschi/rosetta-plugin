#!/usr/bin/env bash
# SessionStart hook — one-line status banner for Rosetta projects.
#
# On session start, probe the docs server at http://localhost:4321/health and
# check whether rosetta-docs/ is scaffolded + personalized. Print a short status
# line to stdout so the initial session context knows the current state,
# avoiding redundant /health probes inside every rosetta skill.
#
# Always exits 0. Silent when there's nothing rosetta-related to report.
#
# Requires: curl, jq (best effort — degrades gracefully if jq missing).

set -uo pipefail

# Fast out: if there's no rosetta-docs/ AND no server, this isn't a rosetta
# project — stay silent so we don't pollute every session's context.
rosetta_docs_present=0
if [ -d "rosetta-docs" ]; then
  rosetta_docs_present=1
fi

health_json=""
if command -v curl >/dev/null 2>&1; then
  health_json="$(curl -fsS -m 1 http://localhost:4321/health 2>/dev/null || true)"
fi

server_is_rosetta=0
version=""
if [ -n "$health_json" ]; then
  if command -v jq >/dev/null 2>&1; then
    svc="$(printf '%s' "$health_json" | jq -r '.service // ""' 2>/dev/null || true)"
    if [ "$svc" = "rosetta" ]; then
      server_is_rosetta=1
      version="$(printf '%s' "$health_json" | jq -r '.version // ""' 2>/dev/null || true)"
    fi
  else
    # jq missing — a grep is enough to decide the branch.
    if printf '%s' "$health_json" | grep -q '"service":"rosetta"'; then
      server_is_rosetta=1
    fi
  fi
fi

if [ "$rosetta_docs_present" -eq 0 ] && [ "$server_is_rosetta" -eq 0 ]; then
  # Not a rosetta project and nothing rosetta-shaped running locally.
  exit 0
fi

# Parse rosetta.config.json (personalization + name) if scaffolded.
project_name=""
personalized="false"
if [ -f "rosetta-docs/src/rosetta.config.json" ] && command -v jq >/dev/null 2>&1; then
  project_name="$(jq -r '.name // ""' rosetta-docs/src/rosetta.config.json 2>/dev/null || true)"
  personalized="$(jq -r '.personalized // false' rosetta-docs/src/rosetta.config.json 2>/dev/null || echo false)"
fi

# Compose a single status line.
{
  printf "rosetta-docs: "
  if [ "$rosetta_docs_present" -eq 1 ]; then
    if [ "$personalized" = "true" ] && [ -n "$project_name" ]; then
      printf "scaffolded + personalized as \"%s\"" "$project_name"
    elif [ "$personalized" = "true" ]; then
      printf "scaffolded + personalized"
    else
      printf "scaffolded (not personalized — /rosetta:personalize-docs to brand)"
    fi
  else
    printf "not scaffolded in this project"
  fi

  if [ "$server_is_rosetta" -eq 1 ]; then
    if [ -n "$version" ]; then
      printf " · server up at http://localhost:4321 (v%s)" "$version"
    else
      printf " · server up at http://localhost:4321"
    fi
  elif [ "$rosetta_docs_present" -eq 1 ]; then
    printf " · server not running (\`pnpm -C rosetta-docs dev\` to start)"
  fi

  printf "\n"
}

exit 0
