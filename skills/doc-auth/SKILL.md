---
name: doc-auth
description: Scaffolded for v0.4.0 — will document the authentication layer of a project (sessions, JWT, middleware/guards, permissions, decorators). Content pending; in v0.3.0 this skill is disabled. Use /rosetta:write-docs "document the authentication layer" for the generic-engine equivalent in the meantime.
disable-model-invocation: true
---

# doc-auth (scaffold — content pending, v0.4.0)

This skill is reserved for **Phase C3** of the roadmap. In v0.3.0 it exists only as a placeholder so the plugin's architecture (thin preset skills on top of a shared `write-docs` engine + `references/` playbooks) is visible and reviewable in the repo.

When invoked today, tell the user:

> `/rosetta:doc-auth` is scaffolded but its content playbook lands in plugin v0.4.0. For now, use `/rosetta:write-docs "document the authentication layer of this project"` — the generic engine will do the work, just without the auth-specific pre-framing (where to look, which components to prefer, common pitfalls).

## TODO (v0.4.0)

- Load `<plugin>/skills/write-docs/references/auth.md` as the topic playbook.
- Pre-frame the topic: "authentication in this project — flow, session handling, middleware/guards, and the permission model".
- Ask the user at start: "inline (I'll pause for clarifications on ambiguous patterns) or background (best-judgment, report when done)?".
- On "background", dispatch the work to a forked subagent with a self-contained prompt.
- Default to inline + interactive.
