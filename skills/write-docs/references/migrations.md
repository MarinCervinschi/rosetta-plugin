# write-docs reference — `migrations` playbook

TODO — Phase C3, targeting plugin v0.4.0.

This file will be loaded by `/rosetta:doc-migrations` (or by `/rosetta:write-docs` when the topic matches `migration*` / `migrate*` / `alembic` / `knex` keywords) and will contain:

- Tool detection: Alembic / Django migrations / Flask-Migrate / Prisma Migrate / Drizzle Kit / Knex / TypeORM migrations / GORM / Diesel / Sequel / Rails.
- What goes in each output page: typically `how-to/` (how to add a new migration, how to roll back) + `explanation/` (why the migration strategy is shaped the way it is, when to write a data migration vs a schema migration).
- Hazards to flag with `<Warning type="danger">`: irreversible operations (dropping a column in production, destructive backfills), team-process gates (who can run `prod` migrations).
- Questions the agent should ask: is there a staging environment? Is there a rollback playbook? Who approves a destructive migration? If the answers are "no / no / nobody", that's material for the `explanation/` page, not a silent fact.
