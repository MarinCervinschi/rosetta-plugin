---
name: write-docs
description: Documents a feature, concept, API, or workflow as an MDX page in a Rosetta docs site at rosetta-docs/. Use when the user says "document X", "write docs for Y", "write a how-to for Z", "explain how A works", "add a reference page for B", or asks to capture knowledge about a code area. Classifies via Diátaxis (tutorials / how-to / reference / explanation), drafts MDX with valid frontmatter, uses rosetta components where they fit, and validates with `pnpm check` (or `npm run check`) before reporting success.
argument-hint: "<topic>"
allowed-tools: Read Write Glob Grep Bash(test *) Bash(ls rosetta-docs/*) Bash(pnpm *) Bash(npm *) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *)
---

# write-docs

Writes a new MDX page into a Rosetta-powered docs site, picks the right Diátaxis section, fills in valid frontmatter, uses custom components where they belong, and gates on `pnpm check` / `npm run check` before declaring success.

The user asked you to document something. Your job is to translate their topic into a page that lands in the correct folder, passes the schema, renders cleanly, and doesn't invent code behavior that isn't in the codebase.

## Why this skill exists

Rosetta docs are *opinionated on purpose*. Four Diátaxis folders, a strict Zod frontmatter schema, a small set of sanctioned components, and a list of forbidden patterns are what keep the site navigable and what let `/llms.txt` be a useful index. An agent that freestyles page structure erodes those guarantees one PR at a time.

Three things matter:

1. **Re-read the rules fresh.** The canonical contract lives in `rosetta-docs/agent-docs-rules.md`. Read it at the start of every invocation. The user may have edited it since install, and the build will reject frontmatter the rules file didn't promise.
2. **Classify before drafting.** Diátaxis isn't a tag you pick at the end — it dictates voice, length, and what's permissible on the page. Deciding first is cheaper than rewriting after.
3. **Gate on the build, not on vibes.** `astro check` (via `pnpm check` or `npm run check`) is the only objective verdict. If it fails, the page isn't done — no matter how good the prose looks.

## Path discipline

**All Bash commands in this skill run from the project root** — the directory that *contains* `rosetta-docs/`. The Bash tool's working directory persists between calls, so a `cd rosetta-docs` silently breaks the next `test -d rosetta-docs/...` guard.

- For **pnpm**, use `pnpm -C rosetta-docs <cmd>` (the `-C` flag is pnpm's shorthand for "change directory").
- For **npm**, use `npm --prefix rosetta-docs <cmd>`.

Never emit a bare `cd rosetta-docs`. All references to the scaffolded folder stay spelled out as `rosetta-docs/...` relative to the project root.

## Workflow

Follow these steps in order.

### Step 1 — Pre-flight: rosetta-docs/ must exist

```bash
test -d rosetta-docs/src/content/docs && echo "docs-ready" || echo "docs-missing"
```

If `docs-missing`, tell the user:

> This project doesn't have a Rosetta docs folder yet. Run `/rosetta:init-docs` first to scaffold `rosetta-docs/`, then re-run `/rosetta:write-docs` with your topic.

Stop. Do not try to create `rosetta-docs/` yourself — that's the init skill's job, and it has a guard we'd bypass.

Note: an unrelated `docs/` at the project root is fine to leave alone. This skill only operates on `rosetta-docs/`.

### Step 2 — Detect the package manager

The gate in Step 9 runs `astro check`. Pick the launcher:

```bash
command -v pnpm >/dev/null 2>&1 && echo "pm=pnpm" || (command -v npm >/dev/null 2>&1 && echo "pm=npm" || echo "pm=none")
```

- `pm=pnpm` → use `pnpm check`.
- `pm=npm` → use `npm run check`.
- `pm=none` → stop and tell the user to install pnpm or npm. (Unlikely if init-docs already ran.)

### Step 3 — Re-read the rules

Read `rosetta-docs/agent-docs-rules.md` in full. Cite sections by number later (e.g. *"per §4 decision tree, this is a how-to"*, *"§6 forbids inline `<script>`, using a component instead"*). This file is authoritative — never paraphrase from memory.

### Step 4 — Re-read the schema

Read `rosetta-docs/src/content.config.ts`. Confirm the current required/optional fields before drafting frontmatter. The template may have added fields in a minor release; hardcoding from this skill's body would drift.

### Step 5 — Classify via §4 decision tree

Apply the tree in order; the first `yes` wins:

- Beginner, step-by-step, concrete working result by the end → `tutorials/`
- Competent reader with a named goal (deploy X, integrate Y, fix Z) → `how-to/`
- Lookup surface: types, endpoints, field lists, CLI, schemas → `reference/`
- "Why is it this way?" — context, trade-offs, design rationale → `explanation/`

Declare the classification to the user before writing, with a one-line justification. If it's a close call between two sections, say so and proceed with the one you chose — don't ping-pong.

### Step 6 — Explore the user's code

Use `Glob`, `Grep`, and `Read` to gather what the page needs to say. Look at actual implementations, not imagined ones. If the behavior is ambiguous (multiple code paths, unclear branching, undocumented side effect), **ask the user** rather than guessing. Fabricated behavior is worse than a missing page.

### Step 7 — Draft MDX with valid frontmatter

Required fields per §2:

- `title` — string. Sentence-case, per §5 ("How to roll back a deploy", not "Rolling Back Deploys").
- `description` — one sentence, non-empty, `<meta description>` + `/llms.txt` entry.
- `category` — exactly the parent folder name (`tutorials` | `how-to` | `reference` | `explanation`). Mismatch = build failure.

Optional:

- `last_updated` — ISO 8601 date, only when the page's truth has a recency that matters.

Body voice per §5:

- Second person for instructions, third person for reference, never first-person plural.
- Short declarative sentences. No marketing adjectives.
- Every code fence gets a language tag (` ```ts `, not ` ``` `) — the raw-MD endpoint and highlighter both rely on it.
- American English.

### Step 8 — Reach for components where §3 says they fit

Import from `~/components/*.astro`. Only reach for a component when it earns its place:

- `<Warning type="caution|info|danger">` — only for things that will hurt the reader or the system if ignored. Not for friendly tips.
- `<CodeTabs>` with `<TabItem label="...">` from `@astrojs/starlight/components` — only for meaningfully different language variants (Python vs TypeScript). Never for two styles of the same language.
- `<ApiRef method="..." path="..." ...>` — one per endpoint on reference pages.
- `<CopyMarkdownButton />` — **never** place manually. §3 is explicit: Starlight's PageTitle override auto-injects it.

### Step 9 — Write the file

Path: `rosetta-docs/src/content/docs/<category>/<slug>.mdx`. Slug is kebab-case derived from the topic (`"document the JWT middleware"` → `jwt-middleware.mdx` under `reference/` or `how-to/`). Sub-grouping folders are allowed (e.g. `rosetta-docs/src/content/docs/how-to/deploy/vercel.mdx`) per §1.

If the file already exists, stop and ask — don't silently overwrite someone else's work.

### Step 10 — Gate: `check`

Using the package manager picked in Step 2, from the project root:

- pnpm: `pnpm -C rosetta-docs check`
- npm:  `npm --prefix rosetta-docs run check`

Both run `astro check` which validates the Zod schema against every page. If it fails, iterate on your draft — do not report success. Common failures and their §:

- Missing required frontmatter → §2.
- `category` doesn't equal parent folder → §2.
- Inline `<script>` or raw `<div>` in MDX → §6.
- Extra top-level folder under `rosetta-docs/src/content/docs/` → §1 / §6.

### Step 11 — Optional: verify render (if dev server is up)

First confirm the server is a rosetta site (not some other service bound to :4321):

```bash
curl -fsS http://localhost:4321/health | grep -q '"service":"rosetta"' && echo "rosetta-up" || echo "no-rosetta"
```

If `rosetta-up`, fetch the new page and its raw-MD twin:

```bash
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>/
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>.md
```

Both should be `200`. The `.md` twin is part of the contract — if the HTML renders but the raw-MD 404s, something is off with the route setup and the user should know.

If `no-rosetta` or the health check fails, skip the render verification — it's not this skill's job to start the server, and a missing server is not a write-docs failure. Note the skip in the report.

### Step 12 — Report

Tell the user exactly:

1. The file path written (e.g. `rosetta-docs/src/content/docs/how-to/jwt-middleware.mdx`).
2. The classification and the one §4 rule that made the call.
3. Any rule sections consulted that shaped non-obvious choices (e.g. *"§3: did not add a `<Warning>` even though the topic touches auth — no destructive action"*).
4. The running URL (if server up) and the raw-MD twin URL.
5. The `check` status.

## Constraints

- **Never report success with a failing `check`.** The build is the contract.
- **Never fabricate code behavior.** If the read doesn't resolve a question, ask or leave a clearly marked TODO in the MDX.
- **Never place `<CopyMarkdownButton />` by hand.** §3 is explicit — it's auto-injected.
- **Never create a new top-level folder** under `rosetta-docs/src/content/docs/` beyond the four Diátaxis sections (§1, §6).
- **Never silently switch the user's package manager.** Use whichever init-docs installed; don't run `pnpm` if the user is on npm or vice versa — you'll desync lockfiles.
- **Never overwrite a pre-existing MDX at the target path** without explicit user confirmation.

## What the user should see at the end

A short report, nothing more:

```
Wrote rosetta-docs/src/content/docs/how-to/jwt-middleware.mdx.

  Classification:  how-to  (§4: the user has a named goal — "document the JWT middleware" — and the page is a recipe, not a lookup.)
  URL:             http://localhost:4321/how-to/jwt-middleware/
  Raw MD:          http://localhost:4321/how-to/jwt-middleware.md
  Check:           pass (pnpm check)

Notes:
  - §3: chose prose over <Warning> — no destructive hazard.
  - §6: replaced inline <br> with Markdown blank line.
```

No summary of everything you did; the user saw the tool calls.
