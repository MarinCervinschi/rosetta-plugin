---
name: doc-patterns
description: Scaffolded for v0.4.0 — will document the recurring patterns in a codebase (decorators, middleware, filters on controllers, factory patterns, repository/service layers — the cross-cutting techniques a contributor needs to recognize). Content pending; in v0.3.0 this skill is disabled. Use /rosetta:write-docs "document the cross-cutting patterns used in this project" for the generic-engine equivalent in the meantime.
disable-model-invocation: true
---

# doc-patterns (scaffold — content pending, v0.4.0)

This skill is reserved for **Phase C3** of the roadmap. In v0.3.0 it exists only as a placeholder.

Unlike `doc-auth` / `doc-db` / `doc-migrations` — which each target one subsystem — `doc-patterns` is explicitly *transversal*. It asks "what techniques recur across the codebase that a new contributor needs to recognize?" and surfaces them. Output is typically an `explanation/` page ("why we use decorators for X") and sometimes a companion `how-to/` page ("how to add a new one").

When invoked today, tell the user:

> `/rosetta:doc-patterns` is scaffolded but its content playbook lands in plugin v0.4.0. For now, use `/rosetta:write-docs "document the cross-cutting patterns used in this project"` — the generic engine will do the work, just without the patterns-specific pre-framing (what to look for in decorators, middleware, filters, factories).

## TODO (v0.4.0)

- Load `<plugin>/skills/write-docs/references/patterns.md` as the topic playbook.
- Pre-frame the topic: "cross-cutting patterns — decorators, middleware, filters, factory/repository/service conventions — that a new contributor needs to recognize".
- Ask the user at start: "inline (interactive) or background?".
- Default to inline + interactive.
