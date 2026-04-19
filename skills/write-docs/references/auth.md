# write-docs reference — `auth` playbook

TODO — Phase C3, targeting plugin v0.4.0.

This file will be loaded by `/rosetta:doc-auth` (or by `/rosetta:write-docs` when the topic matches `auth*` / `authentication` / `login` / `session` keywords) and will contain:

- Files and directories to probe first (`auth*`, `middleware*`, `guards*`, `session*`, `login*`, `signup*`, `oauth*`, `*.jwt*`).
- Decorator / annotation patterns to surface (`@login_required`, `@authorize`, `@UseGuards`, `[Authorize]`, `@AuthMiddleware`).
- What Diátaxis section the result usually lands in (typically `explanation/` for flow + `reference/` for the decorator or route protection API).
- Custom-component guidance: when `<Warning type="danger">` earns its place in auth docs (destructive token ops, irreversible permission changes), when it doesn't (describing the flow).
- Questions the agent should ask the user if the code paths are ambiguous (multiple auth schemes, partial migration from one strategy to another).
