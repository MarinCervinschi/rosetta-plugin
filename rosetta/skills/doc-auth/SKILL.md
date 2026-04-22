---
name: doc-auth
description: Documents the authentication layer of a project — flow, session or token handling, middleware / guards / decorators, and the permission model. Use when the user says "document auth", "write docs for authentication", "document the login flow", "document how sessions work", "document the permission model", or similar. Hands off to /rosetta:write-docs with the auth playbook; lets write-docs decide single-page vs landing + children based on the researcher's brief.
argument-hint: "[extra context]"
allowed-tools: Read Write Glob Grep Task Bash(test *) Bash(ls rosetta-docs/*) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *)
---

# doc-auth

Thin preset over `/rosetta:write-docs`, pre-framed for authentication.

Pre-framed topic: **"authentication in this project — flow, session or token handling, middleware / guards / decorators, and the permission model"**.

## Workflow

### Step 1 — Pre-flight

Run `/rosetta:write-docs`'s Step 1 (`rosetta-docs/` must exist). If missing, refer to `/rosetta:init-docs` and stop.

### Step 2 — Hand off to write-docs

Execute `/rosetta:write-docs` with:

- **topic**: the pre-framed topic above + any `$ARGUMENTS` as extra context
- **playbook_path**: `${CLAUDE_PLUGIN_ROOT}/skills/write-docs/references/auth.md`

write-docs will dispatch `rosetta-code-researcher` with the auth playbook, apply the multi-page decision (Step 6), draft the page(s), and hand off to the Stop hook for `astro check`. If the codebase has multiple subsystems (sessions + tokens + guards + permissions as distinct layers), write-docs will split into a landing + children; if it's a single scheme, it produces one page.

### Step 3 — Report

write-docs produces the user-facing report. Add one line citing auth.md sections that shaped non-obvious choices, e.g. *"per auth.md: declined `<CodeTabs>` since the project is single-language."*

## Constraints

- **Never document secrets**, even as examples. Placeholders only.
- **Never invent auth schemes** the code doesn't implement.
- **Never claim `astro check` passed.** The Stop hook is authoritative.
