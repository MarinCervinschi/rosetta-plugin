---
name: doc-auth
description: Documents the authentication layer of a project — sessions, tokens, middleware, guards, decorators, the permission model. Use when the user says "document auth", "write docs for authentication", "document the login flow", "document how sessions work", or similar. Runs the write-docs engine with an auth-specific playbook, and asks the user at the start whether to run inline (pause for clarifications) or in background (best-judgment, report when done).
argument-hint: "[extra context]"
allowed-tools: Read Write Glob Grep Bash(test *) Bash(ls rosetta-docs/*) Bash(pnpm *) Bash(npm *) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *) Bash(nohup claude *)
---

# doc-auth

Documents the authentication layer of the project — flow, sessions or tokens, middleware / guards, decorators, the permission model. A thin preset on top of `write-docs`, pre-framed for auth topics and loaded with an auth-specific playbook.

Pre-framed topic: "authentication in this project — flow, session or token handling, middleware/guards, and the permission model".

Playbook to read: `${CLAUDE_SKILL_DIR}/../write-docs/references/auth.md`.

## Workflow

### Step 1 — Pre-flight

Run the same `rosetta-docs/` check as `write-docs` Step 1. If `rosetta-docs/src/content/docs` is missing, redirect the user to `/rosetta:init-docs` and stop.

### Step 2 — Ask: inline or background?

Prompt the user once, verbatim:

> Should I run inline or in background?
>
> - **inline** (default): I'll work step-by-step and pause to ask you clarifying questions when the code is ambiguous (multiple auth schemes, a migration in flight, etc.). You'll see the draft before I write anything.
> - **background**: I'll make best-judgment decisions without pausing and write the page unattended. Faster when the codebase is obvious, weaker when there's ambiguity.
>
> (Type `inline` / `background`, or press enter for inline.)

Record the answer. It drives Step 4.

### Step 3 — Read the auth playbook + rules

Read `${CLAUDE_SKILL_DIR}/../write-docs/references/auth.md` for the topic-specific guidance. Then follow `write-docs` Step 2 (detect package manager), Step 3 (read `rosetta-docs/agent-docs-rules.md`), and Step 4 (read `rosetta-docs/src/content.config.ts`).

### Step 4 — Execute

- **inline**: continue with `write-docs` Step 5 (classify via Diátaxis §4) through Step 12 (report). Apply the auth playbook's rules on where to look, which components fit, and which questions to ask when ambiguous. Honor the "interactive" intent: if the code is unclear, stop and ask before drafting.

- **background**: compose a self-contained prompt that embeds (a) this skill's workflow, (b) the auth playbook, (c) the user's pre-framed topic plus `$ARGUMENTS` as extra context, and (d) the instruction to make best-judgment decisions without pausing. Dispatch it — either via a forked subagent if your session exposes one, or via a backgrounded `claude -p --plugin-dir <plugin-path> "..."` through Bash. Return the identifier (subagent ID or PID + log path) so the user can follow along, then stop. Do not run the work yourself.

### Step 5 — Report (inline only)

Use `write-docs`'s Step 12 report format. Cite the `auth.md` playbook sections that shaped non-obvious choices ("per auth.md: declined `<CodeTabs>` since the project is single-language").

## Constraints

- **Never document secrets**, even as examples. Placeholders only.
- **Never invent auth schemes** the code doesn't implement.
- **Never skip the inline/background question** — it's the only place the user steers the run.
- **Background mode doesn't skip the gate.** The subagent still runs `pnpm -C rosetta-docs check` before reporting success.
