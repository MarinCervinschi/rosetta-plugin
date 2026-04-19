---
name: doc-db
description: Documents the database layer of a project — schema, tables, entities, relationships, ORM models. Migrations are covered separately by /rosetta:doc-migrations. Use when the user says "document the database schema", "document the tables", "document the data model", "write docs for the entities", or similar. Runs the write-docs engine with a db-specific playbook, and asks the user at the start whether to run inline or in background.
argument-hint: "[extra context]"
allowed-tools: Read Write Glob Grep Bash(test *) Bash(ls rosetta-docs/*) Bash(pnpm *) Bash(npm *) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *) Bash(nohup claude *)
---

# doc-db

Documents the database layer — schema, tables, entities, relationships, ORM models. A thin preset on top of `write-docs`, pre-framed for db topics and loaded with a db-specific playbook. Migrations are a separate concern — use `/rosetta:doc-migrations` for those.

Pre-framed topic: "database layer of this project — schema, entities, relationships, and the ORM patterns".

Playbook to read: `${CLAUDE_SKILL_DIR}/../write-docs/references/db.md`.

## Workflow

### Step 1 — Pre-flight

Run the same `rosetta-docs/` check as `write-docs` Step 1. If missing, redirect to `/rosetta:init-docs` and stop.

### Step 2 — Ask: inline or background?

Prompt the user once, verbatim:

> Should I run inline or in background?
>
> - **inline** (default): I'll work step-by-step and pause to ask you which tables are load-bearing, whether to include indexes, and other scope questions. You'll see the draft before I write.
> - **background**: I'll make best-judgment decisions and document what looks central, without pausing.
>
> (Type `inline` / `background`, or press enter for inline.)

Record the answer. It drives Step 4.

### Step 3 — Read the db playbook + rules

Read `${CLAUDE_SKILL_DIR}/../write-docs/references/db.md`. Then follow `write-docs` Step 2–4 (package manager detection + rules + schema).

### Step 4 — Execute

- **inline**: continue with `write-docs` Step 5 through Step 12. Use Markdown tables for columns; skip `<ApiRef>` (it's for HTTP endpoints, not tables, per db.md). Ask the user which tables matter most before exhaustively listing.

- **background**: compose a self-contained prompt that embeds this skill's workflow, the db playbook, and the user's pre-framed topic plus `$ARGUMENTS` as extra context. Dispatch via a forked subagent or a backgrounded `claude -p` through Bash. Return the identifier, then stop.

### Step 5 — Report (inline only)

Use `write-docs`'s Step 12 report format. Cite the `db.md` playbook sections that shaped non-obvious choices ("per db.md: scoped to 6 load-bearing tables instead of all 34").

## Constraints

- **Never auto-document every table** unless the user confirms — especially in larger projects.
- **Never use `<ApiRef>` for tables.**
- **Don't document library-provided tables** (session storage, job queues, framework metadata) unless the project interacts with them.
