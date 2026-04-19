# Playbook — `migrations`

Loaded by `/rosetta:doc-migrations` (or `/rosetta:write-docs` when the topic matches migration keywords). For the migration workflow: authoring, applying, rolling back. Schema itself is the `db.md` playbook.

## Where to look

- Migration tool config: `alembic.ini`, `knexfile.*`, `drizzle.config.*`, `prisma/migrations/`, `db/migrate/` (Rails), `migrations/` (Django, generic).
- Run scripts: `package.json` scripts like `db:migrate`, `migrate:up`, `migrate:rollback`. `Makefile` targets. `justfile`.
- CI: grep for migration invocations in `.github/workflows/*`, `.gitlab-ci.yml`, etc. — gate logic lives there.

## Detect the tool

Alembic / Django migrations / Flask-Migrate / Prisma Migrate / Drizzle Kit / Knex / TypeORM migrations / GORM / Diesel / Sequel / Rails / bespoke SQL under `db/`.

## Typical Diátaxis placement

- **`how-to/`** — the action pages: "How to add a new migration", "How to roll back", "How to squash migrations before a release". This is usually the meat.
- **`explanation/`** — the strategy: when we write a data migration vs. a schema migration, why we forbid destructive changes outside maintenance windows, how the team approves a prod migration.

## Components

- `<Warning type="danger">` is appropriate for: dropping columns, irreversible backfills, anything that can lose data. Use it.
- `<Warning type="caution">` for gates like "requires approval from X" or "only in staging first".

## Ask the user when ambiguous

- Is there a staging environment the migration runs against first? Yes/no shapes the how-to.
- Is there a rollback playbook (scripted, documented, or ad-hoc)? If ad-hoc, that's a gap worth naming in the explanation page rather than silently pretending there's a plan.
- Who approves a destructive migration? Named role or "anyone with merge rights"? The answer changes the tone of the how-to.

## Don't

- Don't document the ORM's migration tool from scratch — link to its canonical docs and describe only what's project-specific (conventions, gates, file-naming, review process).
- Don't invent a rollback strategy. If the project doesn't have one, say so. The `explanation/` page is the right place for that honesty.
