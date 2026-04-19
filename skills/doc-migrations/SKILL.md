---
name: doc-migrations
description: Scaffolded for v0.4.0 — will document the migration workflow of a project (how migrations are authored, applied, rolled back; the tool in use; the team process). Schema/entities are covered by /rosetta:doc-db. Content pending; in v0.3.0 this skill is disabled. Use /rosetta:write-docs "document the migration workflow" for the generic-engine equivalent in the meantime.
disable-model-invocation: true
---

# doc-migrations (scaffold — content pending, v0.4.0)

This skill is reserved for **Phase C3** of the roadmap. In v0.3.0 it exists only as a placeholder.

When invoked today, tell the user:

> `/rosetta:doc-migrations` is scaffolded but its content playbook lands in plugin v0.4.0. For now, use `/rosetta:write-docs "document the migration workflow and how to add a new migration"` — the generic engine will produce a how-to page.

## TODO (v0.4.0)

- Load `<plugin>/skills/write-docs/references/migrations.md` as the topic playbook.
- Pre-frame the topic: "migration workflow — how to author a new migration, how to apply/roll back, the team process around destructive changes".
- Ask the user at start: "inline (interactive) or background?".
- Default to inline + interactive.
