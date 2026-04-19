# Playbook — `db`

Loaded by `/rosetta:doc-db` (or `/rosetta:write-docs` when the topic matches schema/database/entity/model keywords). For the database layer: schema, tables, entities, ORM models. Migrations are the separate `migrations.md` playbook.

## Where to look

- `schema.sql` / `schema.prisma` / `*.sql` under `db/` or `migrations/` (source).
- `models/` or `entities/` (ORM classes).
- ORM config: `alembic.ini`, `drizzle.config.*`, `knexfile.*`, `prisma/schema.prisma`, `ormconfig.*`, `ActiveRecord::Schema` blocks.

## Detect the ORM

SQLAlchemy / Django ORM / Prisma / Drizzle / TypeORM / Sequelize / ActiveRecord (Rails) / GORM / Diesel. The shape of a model definition in the target ORM decides how the reference page should look (column list vs. field list, explicit migrations vs. auto-sync).

## Typical Diátaxis placement

- **`reference/`** for the table-by-table lookup. Markdown tables with columns (name, type, constraints, default, notes) are the right primitive. One page per table is fine when there are a few; otherwise group.
- **`explanation/`** for non-obvious design choices: why denormalize X, why a soft-delete column instead of hard delete, why this specific index. Only if a real choice is worth explaining.

## Components

- **Do NOT use `<ApiRef>`** for tables. It's for HTTP endpoints. Use Markdown tables.
- `<Warning type="caution">` for columns whose semantics are load-bearing and easy to misuse (e.g., a flag that changes billing).

## Ask the user when ambiguous

- Which tables are load-bearing vs. generated / operational? Documenting all forty tables is noise.
- Should indexes and foreign keys be in the reference, or are they an implementation detail for that team?
- Is there a data-dictionary already, in a wiki or a spreadsheet? If yes, point at it rather than duplicating.

## Don't

- Don't document tables that come from a library (framework sessions, job queues, migration version tables) unless the project interacts with them directly.
- Don't auto-enumerate every column on every table — it becomes stale the day schema changes. Scope to what a contributor needs to read.
