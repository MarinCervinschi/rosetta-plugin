# Playbook — `db`

Loaded by `/rosetta:doc-db` — documents the **data-layer surface end-to-end**: schemas (as logical groupings), flow, relations, invariants, and the migration workflow. One skill for the whole data area. Migrations are no longer a separate preset; the migration runbook is one child page inside the data-layer output.

## Non-goal: do NOT enumerate tables or columns

Schema files are the source of truth for DDL. `schema.prisma`, migration SQL, `models/`, `entities/` — those **are** the per-table reference. Docs that restate them add no value and rot the moment a column is added.

**What to document instead: what the schema files can't show.**

- *Schemas* in the sense of logical groupings — this cluster of entities is the "users" area, that cluster is "billing". Detection heuristics below.
- *Flow* — how data enters the system, how it moves between subsystems, how it exits (deletion, archival, export).
- *Relations* — how entities connect at a conceptual level: "a User has one active Subscription; a Subscription has many Invoices." Not the FK column list.
- *Invariants* — the load-bearing rules the schema encodes: uniqueness constraints that matter, soft-delete semantics, ownership rules, multi-tenant scoping.
- *Query patterns* — how application code actually reads and writes: ORM queries vs raw SQL vs stored procs, hot paths, and where they live. Cite call sites.

If a reader wants column types or defaults, they open the schema file. That's fine — that's the contract.

## Default output: multi-page

Don't draft one monster page. The data area almost always has logical subsystems. Follow write-docs Step 6 and split: a landing at `reference/database/` + one child page per subsystem + one child page for the migration workflow.

If the project genuinely has a single flat schema with no obvious grouping, declare "single subsystem" and use one page — don't force a split.

## Where to look (for the researcher)

- `schema.sql`, `schema.prisma`, `*.sql` under `db/` or `migrations/`
- `models/` or `entities/` (ORM classes)
- ORM config: `alembic.ini`, `drizzle.config.*`, `knexfile.*`, `prisma/schema.prisma`, `ormconfig.*`
- **.NET / EF Core**:
  - any `*.csproj` referencing `Microsoft.EntityFrameworkCore*` packages
  - the `DbContext` class (inherits from `DbContext`; typically one per bounded context) — its `DbSet<T>` properties enumerate the tracked entities and are the fastest way to map the schema
  - entity classes under `Entities/`, `Domain/`, `Models/`, or inside a `Domain` project in Clean Architecture / Onion layouts (DbContext usually lives under `Infrastructure/` or `Persistence/`)
  - fluent-API configuration: `OnModelCreating` in the DbContext, and any `IEntityTypeConfiguration<T>` classes under `Configurations/` — this is where non-obvious invariants live (unique indexes, owned types, value conversions, query filters for soft-delete / multi-tenancy)
  - `Migrations/` folder with timestamped classes (`20240315123456_AddUserTable.cs`), plus the `*ModelSnapshot.cs` companion — the snapshot is the current-state reference EF compares against
  - `appsettings*.json` connection strings and provider choice (`UseSqlServer`, `UseNpgsql`, `UseSqlite`, `UseCosmos`) — the provider shapes which invariants are load-bearing (e.g. SQL Server `sysname` limits, Postgres citext)
- Application code that reads/writes the DB — to extract **query patterns** (this is most of the value)

## Detecting logical subsystems ("schemas")

Use the researcher's brief. Heuristics, in order:

- **ORM entity directory structure** — e.g. `models/users/`, `models/billing/` → two subsystems. In Clean Architecture .NET solutions, each top-level `Domain/<Aggregate>/` folder (`Domain/Users/`, `Domain/Billing/`) is typically one subsystem.
- **Multiple DbContexts** (EF Core) — each DbContext is almost always its own subsystem boundary by design; document one subsystem page per DbContext before any other grouping heuristic.
- **Table-name prefixes** — `user_*`, `billing_*`, `content_*` → three subsystems.
- **Foreign-key clusters** — connected components in the FK graph are natural subsystem boundaries.
- **Application module boundaries** — which code modules own which tables. In .NET, a `<Something>.Infrastructure` project that owns persistence for one bounded context is a strong signal.

The researcher should report clusters in its brief. The skill then groups by cluster, not by table.

## Landing page structure

Path: `rosetta-docs/src/content/docs/reference/database/index.mdx`.

- **Overview prose** (1–2 paragraphs) — what the data layer is for, its boundaries, the top-level invariants that span subsystems (multi-tenant scoping, soft-delete policy, etc.).
- **Relationship diagram** — `<Mermaid chart={\`...\`} />` or a fenced ` ```mermaid ` block. Nodes are *subsystems* (or the key entity within each); edges are *conceptual* relationships (*"Organizations own Users"*, *"Users have Subscriptions"*). This is **not** an ER diagram of every table — it's a map of the data model at one zoom level up. Aim for ≤ ~10 nodes.
- **Enumerated subsystems**, each a 1-line description + link:

  ```mdx
  - [Users](./users/) — identity, sessions, auth claims
  - [Billing](./billing/) — subscriptions, invoices, payment records
  ```

- **Pointer to the Migrations child page** with one sentence of context.

No table lists, no column enumerations, no per-entity blocks on the landing.

## Subsystem page structure

Each subsystem has **exactly these four sections, in order**:

1. **Purpose** — what this subsystem is for; when in a request/job lifecycle it's touched; which user-facing features depend on it.
2. **Flow** — narrative prose on data movement: how records are created, mutated, and retired in this subsystem. Cite the application code paths that drive each stage (`src/services/users/signup.ts:40-88`).
3. **Relations and invariants** — the conceptual relationships (*"an Organization has many Members; a Member has exactly one active Role"*) and the rules the schema enforces: uniqueness, ownership, soft-delete semantics, tenancy scoping. An optional small Mermaid subgraph is welcome here if it clarifies — scoped to this subsystem's entities.
4. **Query patterns** — how application code uses this subsystem: ORM idioms, raw SQL locations, stored procedures, read/write hot paths. This is the section that genuinely can't be inferred from the schema file. Cite files and line numbers.

**Do NOT include a "Tables" section listing columns.** If a specific entity's semantics are subtle enough to warrant prose, discuss that entity *inside* the Flow or Relations section — not as a table row, as a paragraph with citations to the schema file.

## Migrations page structure

Path: `rosetta-docs/src/content/docs/reference/database/migrations.mdx` (child of the data-layer landing, not a separate top-level topic).

(Content merged from the former `migrations.md` playbook.)

- **Tool in use** — Alembic / Prisma Migrate / Knex / Rails / Django / **EF Core Migrations (`dotnet ef`)** / custom SQL. Name it, link to its canonical docs, describe only project-specific conventions.
- **How to author a new migration** — naming convention, location, review expectations. For EF Core: the `dotnet ef migrations add <Name>` command (or `Add-Migration` in the Package Manager Console), which project holds the `Migrations/` folder, whether the `*ModelSnapshot.cs` companion is reviewed by hand or trusted, and how `IDesignTimeDbContextFactory` is wired for design-time scaffolding if present.
- **How to apply; how to roll back** — exact commands, environment expectations. For EF Core: `dotnet ef database update [<TargetMigration>]` for forward/backward, `dotnet ef migrations script <From> <To>` for the SQL a DBA will actually run in production, and whether apply happens at app startup (`context.Database.Migrate()`), in a pipeline step, or by hand.
- **Destructive-change policy** — gates, approvals, staging expectations. Use `<Warning type="danger">` for genuinely destructive operations (column drops, data-loss backfills); `<Warning type="caution">` for process gates. For EF Core specifically, call out whether the team reviews the generated `Up`/`Down` C# before applying — EF happily emits a destructive `Down` for a rename, for example.

If the project has no documented rollback playbook or approval flow, **name the gap explicitly** rather than inventing one. *"The team does not currently document a rollback playbook for this migration tool — each migration handles rollback via its own `down` step."*

## Components

- `<Mermaid>` — landing diagram + optional subsystem subgraphs.
- `<Warning type="danger">` — destructive migration operations.
- `<Warning type="caution">` — process gates and load-bearing invariants (*"columns on this table are read by the billing job; dropping one without a backfill will break nightly runs"*).

**Not** `<ApiRef>` — that's for HTTP endpoints, not DB entities.

## Ask the user when ambiguous

- Which subsystems exist at a conceptual level, if the code doesn't make it obvious (small projects; monoliths; projects mid-refactor).
- Which query-pattern hot paths matter to contributors — don't enumerate all read sites if half are one-off admin queries.
- Whether a data-dictionary already exists in a wiki or spreadsheet — if yes, point to it rather than re-deriving.
- Whether any of the migrations policy (rollback, approvals, staging) is written down anywhere — document what exists, name the gaps for the rest.

## Don't

- **Don't enumerate tables or columns. Ever.** Schema files are the reference.
- Don't auto-document framework/library tables (session storage tables, job queues, migration metadata tables) unless the application interacts with them at the code layer.
- Don't build a single monolithic page just because the schema is small. If there's genuinely one subsystem, declare it explicitly and use one page — but don't hedge by cramming two subsystems into one page.
- Don't invent migration process (rollback playbook, approval flow) the project doesn't have. Name the gap.
- Don't document library-ORM behavior from scratch — link to the tool's canonical docs and cover only project-specific conventions.
