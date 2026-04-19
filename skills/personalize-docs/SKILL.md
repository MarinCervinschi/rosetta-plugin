---
name: personalize-docs
description: Personalizes a freshly-scaffolded Rosetta docs site with the project's name, stack, and an overview page. Use right after /rosetta:init-docs, or when the user says "personalize the docs", "customize the docs for this project", "add the project overview", "brand the docs with this project's name". One-shot — detects if it has already been run (via the personalized flag in rosetta.config.json) and refuses to re-run. Changes to the overview later go through /rosetta:write-docs.
argument-hint: ""
allowed-tools: Read Write Edit Glob Grep Bash(test *) Bash(ls *) Bash(cat *) Bash(grep *) Bash(pnpm *) Bash(npm *)
---

# personalize-docs

Customizes a freshly-scaffolded Rosetta docs site with the consumer project's identity by editing two files: the metadata JSON that drives the site (`rosetta-docs/src/rosetta.config.json`) and the overview page the JSON can't express (`rosetta-docs/src/content/docs/explanation/overview.mdx`).

The skill is **one-shot**. On second invocation it detects the prior run via `personalized: true` in the JSON and refuses. Updates to the overview after the first personalization go through `/rosetta:write-docs "update the project overview"` — re-personalization would clobber whatever the user wrote afterwards.

## Why this skill exists

`rosetta-template v0.3.0` made the site identity data-driven. A single file — `rosetta-docs/src/rosetta.config.json` — feeds the site title, tagline, description, and a small stack summary. `astro.config.mjs` imports it for Starlight's `title`/`description`; `src/content/docs/index.mdx` uses `{config.name}`/`{config.description}` expressions in the hero.

That means personalizing a project is mostly a JSON edit: detect the project's shape from standard metadata (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `README.md`), populate the JSON, flip `personalized: true`. The hero and the title take care of themselves.

The one thing the JSON can't express is *prose*: a couple of paragraphs describing what this project actually is. That's the job of `explanation/overview.mdx`, which the template ships as a placeholder and this skill rewrites with real content on first run.

## Path discipline

**All Bash commands in this skill run from the project root** — the directory that *contains* `rosetta-docs/`. The Bash tool's working directory persists between calls; a bare `cd rosetta-docs` would silently break subsequent `test -d rosetta-docs/...` guards.

- For pnpm, use `pnpm -C rosetta-docs <cmd>`.
- For npm, use `npm --prefix rosetta-docs <cmd>`.

All references to the scaffolded folder stay spelled out as `rosetta-docs/...` from the project root.

## Workflow

### Step 1 — Pre-flight: rosetta-docs/ must exist and be v0.3.0+

```bash
test -f rosetta-docs/src/rosetta.config.json && echo "v03-ready" || echo "v03-missing"
```

If `v03-missing`, either the docs weren't scaffolded or they were scaffolded from an older template (`v0.2.0`) that didn't ship the config JSON. Tell the user:

> I can't personalize this docs site — either it hasn't been scaffolded yet, or it was scaffolded from a pre-v0.3.0 template. Run `/rosetta:init-docs` to scaffold (or re-scaffold into a fresh directory) against the current template, then re-run `/rosetta:personalize-docs`.

Stop. Don't try to create the JSON yourself — you'd be patching over a version mismatch, which would confuse downstream tools.

### Step 2 — Guard: has this skill already run?

```bash
grep -q '"personalized": true' rosetta-docs/src/rosetta.config.json && echo "already-personalized" || echo "fresh"
```

If `already-personalized`, read the JSON's `name` and `personalizedAt` fields for the message, and tell the user:

> `rosetta-docs/` has already been personalized (project: `<name>`, at `<personalizedAt>`). This skill is one-shot on purpose — to update the overview or rebrand, use `/rosetta:write-docs "update the project overview"` (or edit `rosetta-docs/src/rosetta.config.json` directly for metadata). If you want to re-personalize from scratch, set `"personalized": false` in the JSON and re-run.

Stop. No changes.

### Step 3 — Detect project metadata

Read whichever of these exist at the project root, in this order. Stop at the first match for each field; don't merge across files unless the primary source lacks a value.

| Signal | Files to read |
|---|---|
| Project name | `package.json → name` · `pyproject.toml → [project].name` · `go.mod → module` (use the last path segment) · `Cargo.toml → [package].name` · fallback: directory basename |
| Description | `package.json → description` · `pyproject.toml → [project].description` · first paragraph of `README.md` (skip a top-level `# <title>` if it's just the project name) |
| Language / runtime | File presence heuristic: `package.json` → Node.js; `pyproject.toml` or `requirements.txt` → Python; `go.mod` → Go; `Cargo.toml` → Rust; `Gemfile` → Ruby; `composer.json` → PHP; `pom.xml`/`build.gradle` → Java/JVM; `*.csproj` → .NET |
| Framework | From the language manifest's dependencies: `next` / `react` / `astro` / `@nestjs/*` / `express` / `vue` / `svelte` (Node); `flask` / `django` / `fastapi` / `starlette` (Python); `gin-gonic/gin` / `labstack/echo` / `gofiber/fiber` (Go); `rails` (Gemfile); `laravel` / `symfony` (composer); `spring-boot` (pom/gradle); `rocket` / `actix-web` / `axum` (Cargo) |
| Database / ORM | `schema.sql` / `*.prisma` / `alembic.ini` / `knexfile.*` / `drizzle.config.*` / presence of `models/` dir with ORM-style classes |
| Deployment hints | `Dockerfile`, `docker-compose.yml`, `compose.yml`, `fly.toml`, `vercel.json`, `netlify.toml`, `railway.json` |

Don't guess anything you can't see. If a signal is absent or ambiguous, leave the corresponding JSON field `null` — the user can fill it in later.

Also read the current `rosetta-docs/src/rosetta.config.json` — any non-default values the user may have edited by hand should be **preserved** (you'll merge with detected values in Step 4, not overwrite blindly).

### Step 4 — Draft the two surfaces and preview

Draft in memory; do **not** write files yet. Present both drafts to the user in a single message, clearly labeled, and ask for confirmation.

Use this template for the preview (adapt to the detected values):

```
Personalization preview — detected from the project:

  Name:         <project-name>
  Tagline:      <a one-liner suitable for the site subtitle — often
                 shorter than the description>
  Description:  <one-line description, or "(none found)">
  Stack:
    language:   <language, or null>
    framework:  <framework, or null>
    database:   <database, or null>
    orm:        <orm, or null>
    deploy:     <docker / fly / vercel / ..., or null>

I will write:

  1. rosetta-docs/src/rosetta.config.json
     Set name, tagline, description, stack.* from the detection above.
     Set personalized=true and personalizedAt=<ISO timestamp>.
     Preserve any existing non-default fields in the JSON
     (I merged with what's already there).

  2. rosetta-docs/src/content/docs/explanation/overview.mdx
     Replace the template placeholder with project-specific prose:
     a one-paragraph description, a stack summary list, and
     pointers to the four Diátaxis sections.

Ok to proceed? (yes / no / adjust)
```

On **yes**: proceed to Step 5.
On **no**: stop, no files written.
On **adjust**: ask the user which field they want to change, update the draft, re-preview. Loop until yes or no.

### Step 5 — Write the two files

Only after the user said yes.

**`rosetta-docs/src/rosetta.config.json`**: `Write` (full overwrite with the merged object). The target shape is:

```json
{
  "name": "<project-name>",
  "tagline": "<short one-liner>",
  "description": "<longer one-sentence description>",
  "stack": {
    "language": "<language or null>",
    "framework": "<framework or null>",
    "database": "<database or null>",
    "orm": "<orm or null>",
    "deploy": "<deploy target or null>"
  },
  "personalized": true,
  "personalizedAt": "<ISO-8601 timestamp, e.g. 2026-04-19T18:50:00Z>"
}
```

Use actual JSON nulls (not the string `"null"`) when a field wasn't detected. Keep key order stable (same as the template's default) so diffs stay readable.

**`rosetta-docs/src/content/docs/explanation/overview.mdx`**: `Write` (overwrite the placeholder). Required frontmatter per §2 of `agent-docs-rules.md`:

```yaml
---
title: <project-name> overview
description: <one-sentence summary of what the project is and what it's for>
category: explanation
---
```

Body structure (follow §5 writing style — second person for instructions, short declarative sentences, American English, no marketing adjectives):

```mdx
<opening paragraph describing the project: what it is, what problem it
solves, who uses it. Two to four sentences.>

## Stack

- Language: <language>
- Framework: <framework>
- Database: <database or ORM>
- Deploy: <deploy target if detected>

(omit rows where the field is null; don't write "null" in the visible docs.)

## Where to start

- **New to the codebase?** Start with a tutorial in [Tutorials](/tutorials/).
- **Have a specific goal?** See [How-to guides](/how-to/) for recipes.
- **Need to look something up?** The [Reference](/reference/) is a map of the machinery.
- **Want the why?** [Explanation](/explanation/) covers design choices and trade-offs.
```

No guard marker in this file — the JSON's `personalized: true` is the source of truth for the one-shot gate.

### Step 6 — Gate: `pnpm check` / `npm run check`

Detect the package manager on PATH and run the schema gate from the project root:

- pnpm: `pnpm -C rosetta-docs check`
- npm: `npm --prefix rosetta-docs run check`

Must report `0 errors`. If it fails, the common culprits are:

- `category: explanation` missing in the overview frontmatter (§2).
- An unescaped quote in the detected description breaking YAML.
- JSON syntax error from a control character in the name or description. Re-examine the detected values; if one contains a newline or quote, sanitize and re-write.

Iterate until clean. Don't report success with a failing check.

### Step 7 — Report

Tell the user exactly:

1. The two file paths touched.
2. The detected project name, tagline, description, and stack that you baked into the JSON.
3. The gate result (`pnpm check` → 0 errors).
4. If a dev server is up: the URLs to click (`http://localhost:4321/` shows the new branded hero; `http://localhost:4321/explanation/overview/` is the new overview page).
5. A note that the skill is now one-shot-locked — for metadata edits, edit the JSON directly; for overview prose edits, use `/rosetta:write-docs "update the project overview"`.

## Constraints

- **Never re-run.** The Step 2 guard is load-bearing; bypassing it risks clobbering user edits to the overview.
- **Never invent stack details.** If `package.json` lists `react` with no `next` and no `astro`, call the stack "React" — not "Next.js". Detect, don't guess.
- **Never skip the preview.** The preview + user yes/no is the safety net; writing without confirmation defeats the point of an interactive skill.
- **Never touch files outside the two.** If the detected project implies another file should also update (e.g., `Dockerfile` has a stale project name) — surface that in the report as a suggestion, don't auto-edit.
- **Never write `"null"` (string) for an undetected field.** Use JSON `null`, which both the template's expressions and downstream tools can distinguish from a legitimate value of `"null"`.

## What the user should see at the end

```
Personalized rosetta-docs/ for <project-name>.

  Name:        <project-name>
  Tagline:     <tagline>
  Description: <one-line description>
  Stack:       <comma-separated summary of non-null fields>

  Wrote:
    rosetta-docs/src/rosetta.config.json         (metadata populated + personalized=true)
    rosetta-docs/src/content/docs/explanation/overview.mdx  (placeholder replaced with project prose)

  Gate: pnpm check → 0 errors.

  Next: /rosetta:write-docs "<your first real page topic>".
  To edit the overview later: /rosetta:write-docs "update the project overview".
  To adjust metadata (name/tagline/stack) later: edit rosetta-docs/src/rosetta.config.json directly.
  This skill is now one-shot-locked; re-running will be refused by its guard.
```
