---
name: doc-migrations
description: Documents the migration workflow of a project — how to add, apply, and roll back migrations; the tool in use; the team's process around destructive changes. Schema itself is covered by /rosetta:doc-db. Use when the user says "document migrations", "document how to add a migration", "write the migration runbook", or similar. Runs the write-docs engine with a migrations-specific playbook, and asks the user at the start whether to run inline or in background.
argument-hint: "[extra context]"
allowed-tools: Read Write Glob Grep Task Bash(test *) Bash(ls rosetta-docs/*) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *) Bash(nohup claude *)
---

# doc-migrations

Documents the migration workflow — authoring, applying, rolling back, and the team process around destructive changes. A thin preset on top of `write-docs`, pre-framed for migrations and loaded with a migrations-specific playbook.

Pre-framed topic: "migration workflow of this project — how to author a new migration, how to apply and roll back, and the team process around destructive changes".

Playbook to read: `${CLAUDE_SKILL_DIR}/../write-docs/references/migrations.md`.

## Workflow

### Step 1 — Pre-flight

Run the same `rosetta-docs/` check as `write-docs` Step 1. If missing, redirect to `/rosetta:init-docs` and stop.

### Step 2 — Ask: inline or background?

Prompt the user once, verbatim:

> Should I run inline or in background?
>
> - **inline** (default): I'll work step-by-step and pause to ask about the rollback playbook, staging gates, and approval flow — things I can't reliably infer from code alone.
> - **background**: I'll document what's in the code and the CI scripts, marking process questions as "not documented" instead of asking.
>
> (Type `inline` / `background`, or press enter for inline.)

Record the answer. It drives Step 4.

### Step 3 — Read the migrations playbook + rules

Read `${CLAUDE_SKILL_DIR}/../write-docs/references/migrations.md`. Then follow `write-docs` Step 2–3 (rules + schema).

### Step 4 — Execute

- **inline**: continue with `write-docs` Step 4 through Step 11. When you reach `write-docs` Step 5 (researcher dispatch), pass `playbook_path=${CLAUDE_SKILL_DIR}/../write-docs/references/migrations.md` so the researcher knows to look for migration scripts, CI jobs, and rollback tooling. Expect a how-to page (author/apply/rollback) and often an explanation page (strategy). Use `<Warning type="danger">` for destructive operations, `caution` for process gates. Ask about staging / approvals / rollback playbook when the researcher's *Edge cases* section surfaces gaps (the code alone rarely tells you).

- **background**: compose a self-contained prompt that embeds this skill's workflow, the migrations playbook, and the user's pre-framed topic plus `$ARGUMENTS`. Dispatch via a forked subagent or a backgrounded `claude -p`. Return the identifier and stop.

### Step 5 — Report (inline only)

Use `write-docs`'s Step 11 report format. Cite the `migrations.md` playbook sections applied ("per migrations.md: named the gap — no documented rollback playbook, surfaced in the explanation page rather than glossed over"). The Stop hook enforces `astro check` — don't claim the check passed yourself.

## Constraints

- **Never invent process** (approval flows, staging gates, rollback procedures). If the project doesn't have one, say so explicitly.
- **Don't re-document the ORM tool from scratch** — link to its canonical docs, describe only project-specific conventions.
- **Use `<Warning type="danger">`** for genuinely destructive operations (column drops, data loss backfills) — not for generic migration advice.
