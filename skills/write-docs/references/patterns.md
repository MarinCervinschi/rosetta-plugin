# write-docs reference — `patterns` playbook

TODO — Phase C3, targeting plugin v0.4.0.

This file will be loaded by `/rosetta:doc-patterns` (or by `/rosetta:write-docs` when the topic matches `pattern*` / `decorator*` / `middleware*` / `filter*` / `convention*` keywords) and will contain:

- Signal directories: look for repeated decorator/annotation use in `app/`, `src/`, `controllers/`, `handlers/`, `middleware/`, `filters/`, `pipes/`, `interceptors/`. If the same decorator appears on 3+ call sites, it's a pattern.
- Per-stack common patterns to surface:
  - Python/Flask: blueprints, before_request hooks, decorator-based auth
  - Python/FastAPI: `Depends(...)`, dependency injection, Pydantic response models
  - Python/Django: class-based views, decorators, middleware stack
  - Node/Express: middleware stack, router composition
  - Node/Nest: guards, interceptors, pipes, decorators
  - Go: middleware chains (http.Handler wrappers), context-key conventions
  - Rust: trait-based extractors (axum), guards (rocket)
- Diátaxis placement: usually `explanation/` for the rationale ("why we use a decorator instead of inheritance") + optional `how-to/` for adding one ("how to write a new permission decorator").
- What NOT to document: one-off ad-hoc code. Patterns are, by definition, recurring — if the agent can only find one call site, it isn't a pattern yet.
- Questions the agent should ask: are any of these patterns legacy / in the process of being replaced? If so, note the migration direction — otherwise the docs will encourage contributors to do the deprecated thing.
