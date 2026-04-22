---
name: doc-db
description: Documents the data-layer surface of a project — schemas (as logical groupings), flow, relations, invariants, ORM patterns, AND the migration workflow. One skill for the whole data area. Use when the user says "document the database", "document the tables", "document the data model", "document the schema", "write docs for the entities", "document migrations", "write the migration runbook", or similar. Produces a landing page + subsystem children by default (not a per-table dump — schema files are the DDL reference).
argument-hint: "[extra context]"
allowed-tools: Read Write Glob Grep Task Bash(test *) Bash(ls rosetta-docs/*) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *)
---

# doc-db

Thin preset over `/rosetta:write-docs`, pre-framed for the data layer. Owns the whole data-layer surface: schemas as logical groupings, flow, relations, invariants, ORM patterns, and the migration workflow. Migration workflow renders as one child page inside the data-layer output, not a separate topic.

Pre-framed topic: **"the data-layer surface of this project — schemas as logical groupings, flow, relations, invariants, ORM patterns, and the migration workflow"**.

## Why this skill exists

Schema files (`schema.prisma`, `models/`, `entities/`, migration SQL) are the authoritative reference for table structure. Docs that restate them add no value — they're a rendered mirror of the DDL that goes stale the moment a column is added.

This skill documents **what the schema files can't show**: the logical grouping of entities into subsystems, how data flows through the system, the invariants the schema enforces, and how application code actually reads and writes the data. A reader who wants column types opens the schema file; a reader who wants to understand *why* the data is shaped this way opens these docs.

The output is multi-page by default — one landing with a relationship diagram plus one child per subsystem — because the data layer almost always has orthogonal concerns (identity, billing, content, …) that earn their own page. A single-page output is correct only when the project genuinely has one subsystem.

## Workflow

### Step 1 — Pre-flight

Run `/rosetta:write-docs`'s Step 1 (`rosetta-docs/` must exist). If missing, refer to `/rosetta:init-docs` and stop.

### Step 2 — Hand off to write-docs

Execute `/rosetta:write-docs` with:

- **topic**: the pre-framed topic above + any `$ARGUMENTS` as extra context
- **playbook_path**: `${CLAUDE_PLUGIN_ROOT}/skills/write-docs/references/db.md`

write-docs will:

1. Dispatch `rosetta-code-researcher` with the db.md playbook. The researcher clusters entities into subsystems (by ORM directory, table-name prefix, or FK graph) and extracts query patterns from application code.
2. Apply the multi-page decision (write-docs Step 6). The db.md playbook prescribes landing + children by default; write-docs honors that unless the project has a single flat subsystem.
3. Draft the landing (`reference/database/index.mdx`) with a Mermaid relationship diagram, plus one child per subsystem, plus a child for the migration workflow.
4. Hand off to the Stop hook for `astro check`.

### Step 3 — Report

write-docs produces the user-facing report. Add one line citing the db.md sections that shaped non-obvious choices, e.g. *"per db.md: 4 subsystems from FK clustering; migrations rendered as its own child page."*

## Constraints

- **Never enumerate tables or columns.** Schema files are the DDL reference; docs describe what they can't show — schemas as logical groupings, flow, relations, invariants, query patterns.
- **Never use `<ApiRef>`.** It's for HTTP endpoints, not database entities.
- **Never document library-provided tables** (session storage, job queues, framework migration metadata) unless the application interacts with them at the code layer.
- **Never invent migration process** (rollback playbook, approval flow) the project doesn't have. Name the gap.
- **Never claim `astro check` passed.** The Stop hook is authoritative.
