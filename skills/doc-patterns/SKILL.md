---
name: doc-patterns
description: Documents the cross-cutting patterns in a codebase — decorators, middleware, filters on controllers, factory / repository / service conventions, the transversal techniques a contributor needs to recognize. Use when the user says "document the patterns", "document the conventions", "document how decorators are used here", "document the middleware stack", or similar. Runs the write-docs engine with a patterns-specific playbook, and asks the user at the start whether to run inline or in background.
argument-hint: "[extra context]"
allowed-tools: Read Write Glob Grep Bash(test *) Bash(ls rosetta-docs/*) Bash(pnpm *) Bash(npm *) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *) Bash(nohup claude *)
---

# doc-patterns

Documents the cross-cutting, transversal techniques used throughout the codebase — decorators, middleware, filters, factories, repository / service layers. A thin preset on top of `write-docs`, pre-framed for patterns and loaded with a patterns-specific playbook.

Pre-framed topic: "cross-cutting patterns in this project — decorators, middleware, filters, and other transversal techniques a new contributor needs to recognize".

Playbook to read: `${CLAUDE_SKILL_DIR}/../write-docs/references/patterns.md`.

## Workflow

### Step 1 — Pre-flight

Run the same `rosetta-docs/` check as `write-docs` Step 1. If missing, redirect to `/rosetta:init-docs` and stop.

### Step 2 — Ask: inline or background?

Prompt the user once, verbatim:

> Should I run inline or in background?
>
> - **inline** (default): I'll work step-by-step and pause to ask which of the recurring techniques I find are current vs. legacy — I can't reliably tell from the code alone.
> - **background**: I'll document every pattern I find that shows up 3+ times, without flagging deprecation state.
>
> (Type `inline` / `background`, or press enter for inline.)

Record the answer. It drives Step 4.

### Step 3 — Read the patterns playbook + rules

Read `${CLAUDE_SKILL_DIR}/../write-docs/references/patterns.md`. Then follow `write-docs` Step 2–4 (package manager detection + rules + schema).

### Step 4 — Execute

- **inline**: continue with `write-docs` Step 5 through Step 12. Apply the "3+ recurrences = a pattern" rule from patterns.md. Classify each pattern's page: rationale goes to `explanation/`, adding-a-new-one goes to `how-to/`. Pause to ask the user whether any pattern is being phased out before writing.

- **background**: compose a self-contained prompt that embeds this skill's workflow, the patterns playbook, and the user's pre-framed topic plus `$ARGUMENTS`. Dispatch via a forked subagent or a backgrounded `claude -p`. Return the identifier and stop.

### Step 5 — Report (inline only)

Use `write-docs`'s Step 12 report format. Cite the `patterns.md` playbook sections applied ("per patterns.md: excluded the `@legacy_auth` decorator — only 1 call site, below the 3+ threshold").

## Constraints

- **Never document a one-off** as a pattern. 3+ recurrences is the bar.
- **Never catalogue imported framework decorators** — focus on the team's own idioms.
- **Ask about deprecation before writing.** A pattern that's being phased out deserves a direction-of-travel note, not an endorsement.
