# Playbook — `patterns`

Loaded by `/rosetta:doc-patterns` (or `/rosetta:write-docs` when the topic matches patterns/decorators/middleware/filters/conventions). For *transversal* techniques — patterns that recur across the codebase and a new contributor needs to recognize.

## The "pattern = 3+ recurrences" rule

A technique is a pattern only if it shows up at 3 or more call sites. One decorator on one route is a case; the same decorator on many routes is a pattern. If grep returns one hit, it isn't material for this playbook.

## Where to look

- `app/`, `src/`, `controllers/`, `handlers/`, `middleware/`, `filters/`, `pipes/`, `interceptors/`, `guards/`.
- Decorator / annotation declarations — the *definition* sites — usually in a utils module or alongside the framework's bootstrap.
- `shared/`, `common/`, `core/` — naming hint that something general lives here.

## Per-stack common patterns

- **Flask**: blueprints, `@before_request`, decorator-based auth.
- **FastAPI**: `Depends(...)`, Pydantic response models, exception handlers.
- **Django**: class-based views, decorators, middleware stack.
- **Express / Node**: middleware stack, router composition.
- **Nest**: guards, interceptors, pipes, decorators.
- **Rails**: `before_action`, concerns, service objects.
- **Go**: middleware chains (http.Handler wrappers), context-key conventions.
- **Rust**: extractors in Axum, guards in Rocket.

## Typical Diátaxis placement

- **`explanation/`** for the rationale: why a decorator instead of inheritance, why a service layer, why a repository pattern. One page per non-obvious pattern.
- **`how-to/`** only if adding a new instance has a concrete recipe: "how to write a new permission decorator", "how to add a new service to the DI container".

## Components

- `<Warning>` rarely earns its place here — patterns are not hazards. Exception: if the pattern has a trap ("forgetting to call `next()` silently drops the request"), a `caution` callout is warranted.

## Ask the user when ambiguous

- Are any of these patterns *legacy* / being phased out? If so, name the migration direction — otherwise the docs will entrench the deprecated thing.
- When two patterns solve overlapping concerns (e.g., decorator AND middleware for the same auth), which one is the recommended default?

## Don't

- Don't document a pattern that's used exactly once.
- Don't catalogue every framework decorator the project imports — only the ones the team writes and uses idiomatically.
