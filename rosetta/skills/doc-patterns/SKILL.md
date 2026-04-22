---
name: doc-patterns
description: Documents the cross-cutting patterns in a codebase — decorators, middleware, filters on controllers, factory / repository / service conventions, the transversal techniques a contributor needs to recognize. Use when the user says "document the patterns", "document the conventions", "document how decorators are used here", "document the middleware stack", or similar. Hands off to /rosetta:write-docs with the patterns playbook; lets write-docs decide single-page vs landing + children based on how many distinct techniques the researcher surfaces.
argument-hint: "[extra context]"
allowed-tools: Read Write Glob Grep Task Bash(test *) Bash(ls rosetta-docs/*) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *)
---

# doc-patterns

Thin preset over `/rosetta:write-docs`, pre-framed for cross-cutting patterns — the transversal techniques used throughout the codebase (decorators, middleware, filters, factories, repository / service layers).

Pre-framed topic: **"cross-cutting patterns in this project — decorators, middleware, filters, and other transversal techniques a new contributor needs to recognize"**.

## Workflow

### Step 1 — Pre-flight

Run `/rosetta:write-docs`'s Step 1 (`rosetta-docs/` must exist). If missing, refer to `/rosetta:init-docs` and stop.

### Step 2 — Hand off to write-docs

Execute `/rosetta:write-docs` with:

- **topic**: the pre-framed topic above + any `$ARGUMENTS` as extra context
- **playbook_path**: `${CLAUDE_PLUGIN_ROOT}/skills/write-docs/references/patterns.md`

write-docs dispatches `rosetta-code-researcher` with the patterns playbook. The researcher applies the "3+ recurrences = a pattern" rule from patterns.md — one-off techniques become *Edge cases & ambiguities*, not *Key symbols*. write-docs then decides single-page vs landing + children based on how many distinct patterns survive the 3+ filter. If the researcher surfaces ≥3 distinct patterns (typical for medium-to-large codebases), write-docs splits into a landing + per-pattern children.

### Step 3 — Report

write-docs produces the user-facing report. Add one line citing patterns.md sections that shaped non-obvious choices, e.g. *"per patterns.md: excluded the `@legacy_auth` decorator — only 1 call site, below the 3+ threshold."*

## Constraints

- **Never document a one-off as a pattern.** 3+ recurrences is the bar.
- **Never catalogue imported framework decorators** — focus on the team's own idioms.
- **Ask about deprecation before writing.** A pattern that's being phased out deserves a direction-of-travel note, not an endorsement.
- **Never claim `astro check` passed.** The Stop hook is authoritative.
