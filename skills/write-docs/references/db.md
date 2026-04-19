# write-docs reference — `db` playbook

TODO — Phase C3, targeting plugin v0.4.0.

This file will be loaded by `/rosetta:doc-db` (or by `/rosetta:write-docs` when the topic matches `schema` / `database` / `table` / `entity` / `model` keywords) and will contain:

- Files and directories to probe first (`schema.*`, `*.prisma`, `models/`, `entities/`, `alembic/versions/`, `drizzle/`, `knex/migrations/`).
- ORM detection: SQLAlchemy / Django ORM / Prisma / Drizzle / TypeORM / Sequelize / ActiveRecord / GORM / Diesel — surface which is in use and what the typical model-definition looks like in that project.
- Diátaxis placement: usually `reference/` (table-by-table lookup) + optional `explanation/` for the reasoning behind a non-obvious schema choice.
- Custom-component guidance: `<ApiRef>` is the wrong shape for tables (it's for HTTP endpoints). Markdown tables with column-by-column types are the right primitive.
- What to omit: don't auto-document every table. Ask the user which surfaces are load-bearing; stubbing 40 tables is noise.
