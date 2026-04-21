---
name: write-docs
description: Documents a feature, concept, API, or workflow as an MDX page in a Rosetta docs site at rosetta-docs/. Use when the user says "document X", "write docs for Y", "write a how-to for Z", "explain how A works", "add a reference page for B", or asks to capture knowledge about a code area. Delegates code exploration to the rosetta-code-researcher subagent, classifies via Diátaxis (tutorials / how-to / reference / explanation), drafts MDX with valid frontmatter, uses rosetta components where they fit, and relies on the plugin's Stop hook to auto-run `astro check` at end-of-turn.
argument-hint: "<topic>"
allowed-tools: Read Write Glob Grep Task Bash(test *) Bash(ls rosetta-docs/*) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *)
---

# write-docs

Writes a new MDX page into a Rosetta-powered docs site, picks the right Diátaxis section, fills in valid frontmatter, and uses custom components where they belong. Code exploration is delegated to the `rosetta-code-researcher` subagent so drafting starts with a clean context. The end-of-turn `astro check` is enforced by the plugin's Stop hook — you don't run it yourself.

The user asked you to document something. Your job is to translate their topic into a page that lands in the correct folder, passes the schema, renders cleanly, and doesn't invent code behavior that isn't in the codebase.

## Why this skill exists

Rosetta docs are *opinionated on purpose*. Four Diátaxis folders, a strict Zod frontmatter schema, a small set of sanctioned components, and a list of forbidden patterns are what keep the site navigable and what let `/llms.txt` be a useful index. An agent that freestyles page structure erodes those guarantees one PR at a time.

Three things matter:

1. **Re-read the rules fresh.** The canonical contract lives in `rosetta-docs/agent-docs-rules.md`. Read it at the start of every invocation. The user may have edited it since install, and the build will reject frontmatter the rules file didn't promise.
2. **Classify before drafting.** Diátaxis isn't a tag you pick at the end — it dictates voice, length, and what's permissible on the page. Deciding first is cheaper than rewriting after.
3. **Gate on the build, not on vibes.** `astro check` is the only objective verdict. If it fails, the page isn't done — no matter how good the prose looks. The plugin's Stop hook runs the check automatically whenever you edit MDX under `rosetta-docs/src/content/docs/`; failures surface as stderr in your next turn.

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

### Step 2 — Re-read the rules

Read `rosetta-docs/agent-docs-rules.md` in full. Cite sections by number later (e.g. *"per §4 decision tree, this is a how-to"*, *"§6 forbids inline `<script>`, using a component instead"*). This file is authoritative — never paraphrase from memory.

### Step 3 — Re-read the schema

Read `rosetta-docs/src/content.config.ts`. Confirm the current required/optional fields before drafting frontmatter. The template may have added fields in a minor release; hardcoding from this skill's body would drift.

### Step 4 — Classify via §4 decision tree

Apply the tree in order; the first `yes` wins:

- Beginner, step-by-step, concrete working result by the end → `tutorials/`
- Competent reader with a named goal (deploy X, integrate Y, fix Z) → `how-to/`
- Lookup surface: types, endpoints, field lists, CLI, schemas → `reference/`
- "Why is it this way?" — context, trade-offs, design rationale → `explanation/`

Declare the classification to the user before writing, with a one-line justification. If it's a close call between two sections, say so and proceed with the one you chose — don't ping-pong.

### Step 5 — Delegate code exploration to `rosetta-code-researcher`

Dispatch the `rosetta-code-researcher` subagent via the Agent/Task tool to survey the code area. Exploring here in the main thread pollutes the drafting context — the subagent runs in its own window and returns a structured brief.

Dispatch prompt should include:

- `task_description` — what you're documenting (restate the user's topic in concrete terms)
- `playbook_path` — omit for generic topics (this skill), or pass the absolute path to a topic-specific playbook (used by the `doc-*` presets that wrap this skill)
- `scope_hint` — optional: paths/globs you have a prior reason to prioritize (e.g. if the user mentioned a specific module)

The subagent returns a five-section brief:

```
## Files explored
## Key symbols
## Relationships / flow
## Edge cases & ambiguities
## Citations for drafting
```

**Draft from the brief. Do not re-explore.** Every code claim in the MDX must trace back to a `path:line` citation in the returned brief — if the brief doesn't cite it, don't claim it in the page.

If the brief's *Edge cases & ambiguities* section flags a question you cannot answer from citations, **ask the user** before drafting. Fabricated behavior is worse than a missing page.

### Step 6 — Draft MDX with valid frontmatter

Required fields per §2:

- `title` — string. Sentence-case, per §5 ("How to roll back a deploy", not "Rolling Back Deploys").
- `description` — one sentence, non-empty, `<meta description>` + `/llms.txt` entry.
- `category` — exactly the parent folder name (`tutorials` | `how-to` | `reference` | `explanation`). Mismatch = build failure.
- `last_updated` — today's ISO date, `YYYY-MM-DD` format. Every page carries a stamp at creation time so `/rosetta:edit-docs` has a baseline to refresh. Date-only (no time, no timezone) matches the template's `z.coerce.date()` coercion and keeps diffs small across same-day edits.

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

Path: `rosetta-docs/src/content/docs/<category>/<slug>.mdx`. Slug is kebab-case derived from the topic (`"document the JWT middleware"` → `jwt-middleware.mdx` under `reference/` or `how-to/`). Sub-grouping folders are allowed (e.g. `rosetta-docs/src/content/docs/how-to/deploy/vercel.mdx`) per §1.

If the file already exists, stop and ask — don't silently overwrite someone else's work.

### Step 9 — Gate: Stop hook runs `astro check`

**You do not run the check.** The plugin ships a Stop hook that runs `pnpm -C rosetta-docs check` (or `npm --prefix rosetta-docs run check` as a fallback) at the end of every turn where any MDX under `rosetta-docs/src/content/docs/` was written or edited. A failure surfaces the `astro check` output as stderr in your next turn — fix and the next turn's Stop re-runs the check.

If the next turn opens with check output in context, that is your signal. Iterate on the draft until clean. Common failures and their §:

- Missing required frontmatter → §2.
- `category` doesn't equal parent folder → §2.
- Inline `<script>` or raw `<div>` in MDX → §6.
- Extra top-level folder under `rosetta-docs/src/content/docs/` → §1 / §6.

### Step 10 — Optional: verify render (if dev server is up)

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

### Step 11 — Report

Tell the user exactly:

1. The file path written (e.g. `rosetta-docs/src/content/docs/how-to/jwt-middleware.mdx`).
2. The classification and the one §4 rule that made the call.
3. Any rule sections consulted that shaped non-obvious choices (e.g. *"§3: did not add a `<Warning>` even though the topic touches auth — no destructive action"*).
4. The running URL (if server up) and the raw-MD twin URL.
5. A short note that `astro check` will be enforced by the Stop hook at end-of-turn. Do not claim "check passed" yourself — you haven't run it; the hook will.

## Constraints

- **Never claim the check passed yourself.** You don't run it — the Stop hook does. If the next turn opens with check output, iterate; otherwise the hook was silent (pass).
- **Never fabricate code behavior.** If the researcher's brief doesn't cite it, don't claim it. If ambiguity persists, ask the user or leave a clearly marked TODO in the MDX.
- **Never re-explore in the main thread.** Dispatch `rosetta-code-researcher` once; draft from its brief. If the brief is insufficient, dispatch a narrower second query rather than Globbing/Grepping yourself.
- **Never place `<CopyMarkdownButton />` by hand.** §3 is explicit — it's auto-injected.
- **Never create a new top-level folder** under `rosetta-docs/src/content/docs/` beyond the four Diátaxis sections (§1, §6).
- **Never overwrite a pre-existing MDX at the target path** without explicit user confirmation.

## What the user should see at the end

A short report, nothing more:

```
Wrote rosetta-docs/src/content/docs/how-to/jwt-middleware.mdx.

  Classification:  how-to  (§4: the user has a named goal — "document the JWT middleware" — and the page is a recipe, not a lookup.)
  URL:             http://localhost:4321/how-to/jwt-middleware/
  Raw MD:          http://localhost:4321/how-to/jwt-middleware.md
  Check:           Stop hook will run `astro check` at end-of-turn.

Notes:
  - §3: chose prose over <Warning> — no destructive hazard.
  - §6: replaced inline <br> with Markdown blank line.
  - Researcher brief cited 4 files under src/middleware/; draft used those citations only.
```

No summary of everything you did; the user saw the tool calls.
