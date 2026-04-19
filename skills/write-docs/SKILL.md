---
name: write-docs
description: Documents a feature, concept, API, or workflow as an MDX page in a Rosetta docs site. Use when the user says "document X", "write docs for Y", "write a how-to for Z", "explain how A works", "add a reference page for B", or asks to capture knowledge about a code area. Classifies via Diátaxis (tutorials / how-to / reference / explanation), drafts MDX with valid frontmatter, uses rosetta components where they fit, and validates with `pnpm check` before reporting success.
argument-hint: "<topic>"
allowed-tools: Read Write Glob Grep Bash(test *) Bash(ls docs/*) Bash(cd docs && pnpm check) Bash(cd docs && pnpm astro check) Bash(curl -fsS http://localhost:4321/*)
---

# write-docs

Writes a new MDX page into a Rosetta-powered docs site, picks the right Diátaxis section, fills in valid frontmatter, uses custom components where they belong, and gates on `pnpm check` before declaring success.

The user asked you to document something. Your job is to translate their topic into a page that lands in the correct folder, passes the schema, renders cleanly, and doesn't invent code behavior that isn't in the codebase.

## Why this skill exists

Rosetta docs are *opinionated on purpose*. Four Diátaxis folders, a strict Zod frontmatter schema, a small set of sanctioned components, and a list of forbidden patterns are what keep the site navigable and what let `/llms.txt` be a useful index. An agent that freestyles page structure erodes those guarantees one PR at a time.

Three things matter:

1. **Re-read the rules fresh.** The canonical contract lives in `docs/agent-docs-rules.md`. Read it at the start of every invocation. The user may have edited it since install, and the build will reject frontmatter the rules file didn't promise.
2. **Classify before drafting.** Diátaxis isn't a tag you pick at the end — it dictates voice, length, and what's permissible on the page. Deciding first is cheaper than rewriting after.
3. **Gate on the build, not on vibes.** `pnpm check` is the only objective verdict. If it fails, the page isn't done — no matter how good the prose looks.

## Workflow

Follow these steps in order.

### Step 1 — Pre-flight: docs/ must exist

```bash
test -d docs/src/content/docs && echo "docs-ready" || echo "docs-missing"
```

If `docs-missing`, tell the user:

> This project doesn't have a Rosetta docs folder yet. Run `/rosetta:init-docs` first to scaffold `docs/`, then re-run `/rosetta:write-docs` with your topic.

Stop. Do not try to create `docs/` yourself — that's the init skill's job, and it has a guard we'd bypass.

### Step 2 — Re-read the rules

Read `docs/agent-docs-rules.md` in full. Cite sections by number later (e.g. *"per §4 decision tree, this is a how-to"*, *"§6 forbids inline `<script>`, using a component instead"*). This file is authoritative — never paraphrase from memory.

### Step 3 — Re-read the schema

Read `docs/src/content.config.ts`. Confirm the current required/optional fields before drafting frontmatter. The template may have added fields in a minor release; hardcoding from this skill's body would drift.

### Step 4 — Classify via §4 decision tree

Apply the tree in order; the first `yes` wins:

- Beginner, step-by-step, concrete working result by the end → `tutorials/`
- Competent reader with a named goal (deploy X, integrate Y, fix Z) → `how-to/`
- Lookup surface: types, endpoints, field lists, CLI, schemas → `reference/`
- "Why is it this way?" — context, trade-offs, design rationale → `explanation/`

Declare the classification to the user before writing, with a one-line justification. If it's a close call between two sections, say so and proceed with the one you chose — don't ping-pong.

### Step 5 — Explore the user's code

Use `Glob`, `Grep`, and `Read` to gather what the page needs to say. Look at actual implementations, not imagined ones. If the behavior is ambiguous (multiple code paths, unclear branching, undocumented side effect), **ask the user** rather than guessing. Fabricated behavior is worse than a missing page.

### Step 6 — Draft MDX with valid frontmatter

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

### Step 7 — Reach for components where §3 says they fit

Import from `~/components/*.astro`. Only reach for a component when it earns its place:

- `<Warning type="caution|info|danger">` — only for things that will hurt the reader or the system if ignored. Not for friendly tips.
- `<CodeTabs>` with `<TabItem label="...">` from `@astrojs/starlight/components` — only for meaningfully different language variants (Python vs TypeScript). Never for two styles of the same language.
- `<ApiRef method="..." path="..." ...>` — one per endpoint on reference pages.
- `<CopyMarkdownButton />` — **never** place manually. §3 is explicit: Starlight's PageTitle override auto-injects it.

### Step 8 — Write the file

Path: `docs/src/content/docs/<category>/<slug>.mdx`. Slug is kebab-case derived from the topic (`"document the JWT middleware"` → `jwt-middleware.mdx` under `reference/` or `how-to/`). Sub-grouping folders are allowed (e.g. `docs/src/content/docs/how-to/deploy/vercel.mdx`) per §1.

If the file already exists, stop and ask — don't silently overwrite someone else's work.

### Step 9 — Gate: `pnpm check`

```bash
cd docs && pnpm check
```

This runs `astro check` which validates the Zod schema against every page. If it fails, iterate on your draft — do not report success. Common failures and their §:

- Missing required frontmatter → §2.
- `category` doesn't equal parent folder → §2.
- Inline `<script>` or raw `<div>` in MDX → §6.
- Extra top-level folder under `docs/src/content/docs/` → §1 / §6.

### Step 10 — Optional: verify render (if dev server is up)

```bash
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>/
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>.md
```

Both should be `200`. The `.md` twin is part of the contract — if the HTML renders but the raw-MD 404s, something is off with the route setup and the user should know.

If the dev server is down, skip this step — it's not this skill's job to start it, and a missing server is not a write-docs failure. Note the skip in the report.

### Step 11 — Report

Tell the user exactly:

1. The file path written (e.g. `docs/src/content/docs/how-to/jwt-middleware.mdx`).
2. The classification and the one §4 rule that made the call.
3. Any rule sections consulted that shaped non-obvious choices (e.g. *"§3: did not add a `<Warning>` even though the topic touches auth — no destructive action"*).
4. The running URL (if server up) and the raw-MD twin URL.
5. The `pnpm check` status.

## Constraints

- **Never report success with a failing `pnpm check`.** The build is the contract.
- **Never fabricate code behavior.** If the read doesn't resolve a question, ask or leave a clearly marked TODO in the MDX.
- **Never place `<CopyMarkdownButton />` by hand.** §3 is explicit — it's auto-injected.
- **Never create a new top-level folder** under `docs/src/content/docs/` beyond the four Diátaxis sections (§1, §6).
- **Never substitute `npm`/`yarn` for `pnpm`.** The lockfile is pinned; mixing package managers will break the dep graph.
- **Never overwrite a pre-existing MDX at the target path** without explicit user confirmation.

## What the user should see at the end

A short report, nothing more:

```
Wrote docs/src/content/docs/how-to/jwt-middleware.mdx.

  Classification:  how-to  (§4: the user has a named goal — "document the JWT middleware" — and the page is a recipe, not a lookup.)
  URL:             http://localhost:4321/how-to/jwt-middleware/
  Raw MD:          http://localhost:4321/how-to/jwt-middleware.md
  pnpm check:      pass

Notes:
  - §3: chose prose over <Warning> — no destructive hazard.
  - §6: replaced inline <br> with Markdown blank line.
```

No summary of everything you did; the user saw the tool calls.
