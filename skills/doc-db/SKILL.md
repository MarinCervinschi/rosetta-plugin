---
name: doc-db
description: Scaffolded for v0.4.0 — will document the database layer (schema, tables, entities, relationships, ORM models). Migrations are covered separately by /rosetta:doc-migrations. Content pending; in v0.3.0 this skill is disabled. Use /rosetta:write-docs "document the database schema" for the generic-engine equivalent in the meantime.
disable-model-invocation: true
---

# doc-db (scaffold — content pending, v0.4.0)

This skill is reserved for **Phase C3** of the roadmap. In v0.3.0 it exists only as a placeholder.

Split rationale: schema/entities/ORM are a *structural* lookup surface (reference material in Diátaxis terms). Migrations are a *procedural* concern (how-to material). Separating the two keeps each page's shape honest — `doc-db` produces reference, `doc-migrations` produces how-to.

When invoked today, tell the user:

> `/rosetta:doc-db` is scaffolded but its content playbook lands in plugin v0.4.0. For now, use `/rosetta:write-docs "document the database schema"` — the generic engine will produce a reference page, just without the db-specific pre-framing (which ORM, where models live, which relationships matter).

## TODO (v0.4.0)

- Load `<plugin>/skills/write-docs/references/db.md` as the topic playbook.
- Pre-frame the topic: "database layer of this project — schema, entities, relationships, the ORM patterns".
- Ask the user at start: "inline (interactive) or background?".
- Default to inline + interactive.
