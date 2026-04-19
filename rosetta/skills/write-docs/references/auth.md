# Playbook — `auth`

Loaded by `/rosetta:doc-auth` (or `/rosetta:write-docs` when the topic matches auth keywords). Guidance for the agent when documenting a project's authentication layer.

## Where to look

- File / dir names: `auth*`, `authentication*`, `login*`, `signup*`, `logout*`, `session*`, `token*`, `jwt*`, `oauth*`, `guards*`, `middleware*`, `permissions*`, `roles*`.
- Decorator / annotation call sites: `@login_required`, `@authorize`, `@UseGuards`, `@RoleRequired`, `[Authorize]`, `middleware.authenticate()`, `passport.authenticate(...)`.
- Config keys that hint at strategy: `SECRET_KEY`, `JWT_SECRET`, `SESSION_*`, `OAUTH_*`.

## Typical Diátaxis placement

- **`explanation/`** for the flow (how auth is shaped: what's a session, how tokens are issued, where the identity comes from). First page to write.
- **`reference/`** for the decorator / guard / middleware API if it's a surface users apply on their own routes.
- **`how-to/`** only if the project has a concrete recipe like "add a new protected route" or "rotate the JWT secret".

## Components

- `<Warning type="danger">` earns its place for destructive / irreversible operations (rotating a secret, invalidating all sessions, deleting permissions). Not for reassurance.
- `<CodeTabs>` if the project speaks more than one language in the auth boundary (e.g., Python backend + TypeScript client). Otherwise skip.
- `<ApiRef>` once per endpoint if the reference page lists `/login`, `/logout`, `/refresh`, etc.

## Ask the user when ambiguous

- Multiple auth schemes coexisting (session cookies AND JWT, OAuth for some routes + local for others)? Which is the happy path to document first?
- A partial migration from one strategy to another in flight? Document the target state or the current transitional state?
- Role/permission model with data (e.g., roles in a DB table)? Enumerate roles or link to the schema reference?

## Don't

- Don't copy secrets into the docs, even in examples. Placeholder values only.
- Don't document a theoretical "if we had OAuth" — document what exists.
