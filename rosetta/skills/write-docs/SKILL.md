---
name: write-docs
description: Documents a feature, concept, API, or workflow in a Rosetta docs site at rosetta-docs/. Use when the user says "document X", "write docs for Y", "write a how-to for Z", "explain how A works", "add a reference page for B", or asks to capture knowledge about a code area. Delegates code exploration to the rosetta-code-researcher subagent, classifies via Diátaxis (tutorials / how-to / reference / explanation), and drafts EITHER a single page OR a landing + children split when the topic has orthogonal subsystems. Relies on the plugin's Stop hook to auto-run `astro check` at end-of-turn.
argument-hint: "<topic>"
allowed-tools: Read Write Glob Grep Task Bash(test *) Bash(ls rosetta-docs/*) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *)
---

# write-docs

Writes new documentation into a Rosetta-powered docs site. The output shape depends on the topic: a **single page** for a focused subject, or a **landing page + children** when the topic has orthogonal subsystems (the data layer, the auth surface, the cross-cutting patterns). Code exploration is delegated to the `rosetta-code-researcher` subagent so drafting starts with a clean context. The end-of-turn `astro check` is enforced by the plugin's Stop hook — you don't run it yourself.

The user asked you to document something. Your job is to translate their topic into pages that land in the correct folder, pass the schema, render cleanly in the Starlight sidebar, and don't invent code behavior that isn't in the codebase.

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

### Step 6 — Decide: single page or landing + children?

Long topics deserve multiple pages; the Starlight sidebar renders folder hierarchy as nested groups. Use the researcher's brief to pick one of two shapes:

- **Single page** — the topic maps to one subject. Examples: "document the JWT middleware", "how to deploy to Vercel", "why we chose Prisma over TypeORM". The brief's *Key symbols* cluster around one area. No relationship diagram would add clarity.

- **Landing + children** — the topic has a parent concept with orthogonal sub-topics. The researcher surfaces ≥3 logical subsystems/clusters that can stand alone as pages. Examples: "document the database" → users / billing / content / migrations; "document auth" → sessions / tokens / guards / permissions; "document the patterns" → decorators / middleware / repositories. A relationship/flow diagram clarifies how the children connect.

Declare the choice to the user in one line before drafting, e.g.:

> Split: landing at `reference/database/` + 4 children (users, billing, content, migrations).
> or
> Single page at `how-to/jwt-middleware.mdx` — the topic maps to one middleware unit.

If a topic playbook was passed to the researcher (the `doc-*` presets), its guidance overrides this heuristic — some playbooks (`db.md`) prescribe multi-page output by default.

**Landing-page shape** (when splitting):

- Path: `rosetta-docs/src/content/docs/<category>/<slug>/index.mdx` — the folder's index becomes the group's landing.
- Frontmatter: same schema as any page. `title` = the parent concept ("Database"). `category` = the Diátaxis folder.
- Body: 1–2 paragraphs of overview prose (what this area is, boundaries, top-level invariants).
- **Relationship / flow diagram** via `<Mermaid chart={\`...\`} />` or a fenced ` ```mermaid ` block — both render per rules §3. Nodes are *subsystems* (or their key entities); edges are conceptual connections. Not an exhaustive diagram of every file — one zoom level up.
- Linked list of children with 1-line descriptions: `- [Users](./users/) — identity, sessions, auth claims`.
- Optional "Further reading" pointing to related pages in other categories.

**Child pages** — regular write-docs pages. Each lives at `rosetta-docs/src/content/docs/<category>/<slug>/<child>.mdx`. Same frontmatter schema. `category` equals the landing's `category` (all children of `reference/database/` carry `category: reference`). Same body voice and component rules.

Starlight's `autogenerate: { directory: <category> }` nests the folder automatically — no sidebar config changes needed. The landing renders as the group parent; children sort alphabetically by filename underneath.

### Step 7 — Draft MDX with valid frontmatter

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

### Step 8 — Reach for components where §3 says they fit

Import from `~/components/*.astro`. Only reach for a component when it earns its place:

- `<Warning type="caution|info|danger">` — only for things that will hurt the reader or the system if ignored. Not for friendly tips.
- `<CodeTabs>` with `<TabItem label="...">` from `@astrojs/starlight/components` — only for meaningfully different language variants (Python vs TypeScript). Never for two styles of the same language.
- `<ApiRef method="..." path="..." ...>` — one per endpoint on reference pages.
- `<CopyMarkdownButton />` — **never** place manually. §3 is explicit: Starlight's PageTitle override auto-injects it.

### Step 9 — Write the file(s)

**Single-page mode:** path is `rosetta-docs/src/content/docs/<category>/<slug>.mdx`. Slug is kebab-case derived from the topic (`"document the JWT middleware"` → `jwt-middleware.mdx` under `reference/` or `how-to/`). Sub-grouping folders are allowed (e.g. `rosetta-docs/src/content/docs/how-to/deploy/vercel.mdx`) per §1.

**Landing + children mode:** write `rosetta-docs/src/content/docs/<category>/<slug>/index.mdx` (landing) and one `rosetta-docs/src/content/docs/<category>/<slug>/<child>.mdx` per child page. Write the landing first so Starlight's sidebar picks up the group name immediately. Write children in a stable order (the order you'll list them on the landing).

**Existence guard — refuse in all of these cases:**

- Single-page mode: the target `<slug>.mdx` already exists.
- Landing + children mode: the target `<slug>/index.mdx` already exists **OR** a flat-page `<slug>.mdx` already exists at the same location (the landing would collide with an existing page).

On collision, stop and tell the user:

> A page already exists at `<path>`. Use `/rosetta:edit-docs` to update it, or re-invoke me with a different topic.

Do not silently overwrite, merge, or restructure existing work.

### Step 10 — Gate: Stop hook runs `astro check`

**You do not run the check.** The plugin ships a Stop hook that runs `pnpm -C rosetta-docs check` (or `npm --prefix rosetta-docs run check` as a fallback) at the end of every turn where any MDX under `rosetta-docs/src/content/docs/` was written or edited. A failure surfaces the `astro check` output as stderr in your next turn — fix and the next turn's Stop re-runs the check.

If the next turn opens with check output in context, that is your signal. Iterate on the draft until clean. Common failures and their §:

- Missing required frontmatter → §2.
- `category` doesn't equal parent folder → §2.
- Inline `<script>` or raw `<div>` in MDX → §6.
- Extra top-level folder under `rosetta-docs/src/content/docs/` → §1 / §6.

### Step 11 — Optional: verify render (if dev server is up)

First confirm the server is a rosetta site (not some other service bound to :4321):

```bash
curl -fsS http://localhost:4321/health | grep -q '"service":"rosetta"' && echo "rosetta-up" || echo "no-rosetta"
```

If `rosetta-up`, fetch every page that was written and its raw-MD twin:

```bash
# Single-page
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>/
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>.md

# Landing + children — probe landing plus each child
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>/
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>/<child>/
```

All should be `200`. The `.md` twin is part of the contract — if the HTML renders but the raw-MD 404s, something is off with the route setup and the user should know.

If `no-rosetta` or the health check fails, skip the render verification — it's not this skill's job to start the server, and a missing server is not a write-docs failure. Note the skip in the report.

### Step 12 — Report

Tell the user exactly:

1. The file(s) written. For single-page mode, one path. For landing + children mode, list the landing + each child.
2. The split mode explicitly (`Shape: single page` or `Shape: landing + N children`).
3. The classification and the one §4 rule that made the call.
4. Any rule sections consulted that shaped non-obvious choices (e.g. *"§3: did not add a `<Warning>` even though the topic touches auth — no destructive action"*).
5. The running URL (if server up) and the raw-MD twin URL(s).
6. A short note that `astro check` will be enforced by the Stop hook at end-of-turn. Do not claim "check passed" yourself — you haven't run it; the hook will.

## Constraints

- **Never claim the check passed yourself.** You don't run it — the Stop hook does. If the next turn opens with check output, iterate; otherwise the hook was silent (pass).
- **Never fabricate code behavior.** If the researcher's brief doesn't cite it, don't claim it. If ambiguity persists, ask the user or leave a clearly marked TODO in the MDX.
- **Never re-explore in the main thread.** Dispatch `rosetta-code-researcher` once; draft from its brief. If the brief is insufficient, dispatch a narrower second query rather than Globbing/Grepping yourself.
- **Never place `<CopyMarkdownButton />` by hand.** §3 is explicit — it's auto-injected.
- **Never create a new top-level folder** under `rosetta-docs/src/content/docs/` beyond the four Diátaxis sections (§1, §6).
- **Never overwrite a pre-existing MDX at the target path** without explicit user confirmation.

## What the user should see at the end

A short report, nothing more:

Single-page example:

```
Wrote rosetta-docs/src/content/docs/how-to/jwt-middleware.mdx.

  Shape:           single page
  Classification:  how-to  (§4: the user has a named goal — "document the JWT middleware" — and the page is a recipe, not a lookup.)
  URL:             http://localhost:4321/how-to/jwt-middleware/
  Raw MD:          http://localhost:4321/how-to/jwt-middleware.md
  Check:           Stop hook will run `astro check` at end-of-turn.

Notes:
  - §3: chose prose over <Warning> — no destructive hazard.
  - §6: replaced inline <br> with Markdown blank line.
  - Researcher brief cited 4 files under src/middleware/; draft used those citations only.
```

Landing + children example:

```
Wrote 5 pages under rosetta-docs/src/content/docs/reference/database/.

  Shape:           landing + 4 children
  Classification:  reference  (§4: lookup surface for the data layer.)
  Landing:         reference/database/index.mdx        → /reference/database/
  Children:        reference/database/users.mdx        → /reference/database/users/
                   reference/database/billing.mdx      → /reference/database/billing/
                   reference/database/content.mdx      → /reference/database/content/
                   reference/database/migrations.mdx   → /reference/database/migrations/
  Check:           Stop hook will run `astro check` at end-of-turn.

Notes:
  - per db.md: scoped to 4 subsystems from FK clustering; no per-table enumeration.
  - Landing uses a <Mermaid> relationship diagram across the 4 subsystems.
  - Migrations rendered as its own child page, per db.md.
```

No summary of everything you did; the user saw the tool calls.
