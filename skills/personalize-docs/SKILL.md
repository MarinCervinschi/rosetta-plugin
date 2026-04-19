---
name: personalize-docs
description: Personalizes a freshly-scaffolded Rosetta docs site with the project's name, stack, and an overview page. Use right after /rosetta:init-docs, or when the user says "personalize the docs", "customize the docs for this project", "add the project overview", "brand the docs with this project's name". One-shot — detects if it has already been run and refuses to re-run (changes to the overview afterwards go through /rosetta:write-docs instead).
argument-hint: ""
allowed-tools: Read Write Edit Glob Grep Bash(test *) Bash(ls *) Bash(cat *) Bash(grep *) Bash(pnpm *) Bash(npm *)
---

# personalize-docs

Customizes a freshly-scaffolded Rosetta docs site with the consumer project's identity: the title and description in `astro.config.mjs`, a project-aware splash page, and a first overview page under `explanation/`.

This skill is **one-shot**. On second invocation it detects the prior run via a marker in `overview.mdx` and refuses. Updates to the overview later are handled by `/rosetta:write-docs "update the project overview"` — re-personalization would clobber the user's edits.

## Why this skill exists

The scaffold from `/rosetta:init-docs` is generic on purpose — it ships the template's demo content, which is useful reference but not *about* the user's project. For the docs site to feel like the project's own, three surfaces need to carry the project's identity: the site title (in `astro.config.mjs`), the landing page (`index.mdx`), and a "what is this project" explanation (`explanation/overview.mdx`).

Rather than asking the agent to free-style these every time, this skill detects the project's shape from standard metadata files (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `README.md`), drafts all three surfaces, previews them with the user, and writes on confirmation.

## Path discipline

**All Bash commands in this skill run from the project root** — the directory that *contains* `rosetta-docs/`. The Bash tool's working directory persists between calls; a bare `cd rosetta-docs` would silently break subsequent `test -d rosetta-docs/...` guards.

- For pnpm, use `pnpm -C rosetta-docs <cmd>`.
- For npm, use `npm --prefix rosetta-docs <cmd>`.

All references to the scaffolded folder stay spelled out as `rosetta-docs/...` from the project root.

## Workflow

### Step 1 — Pre-flight: rosetta-docs/ must exist

```bash
test -d rosetta-docs/src/content/docs && echo "docs-ready" || echo "docs-missing"
```

If `docs-missing`, tell the user:

> This project doesn't have a Rosetta docs site yet. Run `/rosetta:init-docs` first to scaffold `rosetta-docs/`, then re-run `/rosetta:personalize-docs`.

Stop.

### Step 2 — Guard: has this skill already run?

Check for the personalization marker:

```bash
grep -l 'rosetta:personalized' rosetta-docs/src/content/docs/explanation/overview.mdx 2>/dev/null && echo "already-personalized" || echo "fresh"
```

If `already-personalized`, read the first few lines of the overview file to extract the recorded project name + timestamp, and tell the user:

> `rosetta-docs/` has already been personalized (project: `<name>`, on `<timestamp>`). This skill is one-shot on purpose — to update the overview or rebrand, use `/rosetta:write-docs "update the project overview"` instead. If you want to re-personalize from scratch, delete `rosetta-docs/src/content/docs/explanation/overview.mdx` and re-run.

Stop. No changes.

### Step 3 — Detect project metadata

Read whichever of these exist at the project root, in this order. Stop at the first match for each field; don't merge across files unless the primary source lacks a value.

| Signal | Files to read |
|---|---|
| Project name | `package.json → name` · `pyproject.toml → [project].name` · `go.mod → module` (use the last path segment) · `Cargo.toml → [package].name` · fallback: directory basename |
| Description | `package.json → description` · `pyproject.toml → [project].description` · first paragraph of `README.md` (skip a top-level `# <title>` if it's just the project name) |
| Language / runtime | File presence heuristic: `package.json` → Node.js; `pyproject.toml` or `requirements.txt` → Python; `go.mod` → Go; `Cargo.toml` → Rust; `Gemfile` → Ruby; `composer.json` → PHP; `pom.xml`/`build.gradle` → Java/JVM; `*.csproj` → .NET |
| Framework | From `dependencies` of the language manifest: `next`, `react`, `astro`, `@nestjs/*`, `express`, `vue`, `svelte` (Node); `flask`, `django`, `fastapi`, `starlette` (Python); `gin-gonic/gin`, `labstack/echo`, `gofiber/fiber` (Go); `rails` (Gemfile); `laravel`, `symfony` (composer); `spring-boot` (pom/gradle); `rocket`, `actix-web`, `axum` (Cargo) |
| Database / ORM | `schema.sql` / `*.prisma` / `alembic.ini` / `knexfile.*` / `drizzle.config.*` / presence of `models/` dir with ORM-style classes |
| Deployment hints | `Dockerfile`, `docker-compose.yml`, `compose.yml`, `fly.toml`, `vercel.json`, `netlify.toml`, `railway.json` |

Don't guess anything you can't see. If a signal is absent or ambiguous, omit it from the draft — the user can add it later via `/rosetta:write-docs`.

### Step 4 — Draft the three surfaces and preview

Draft in memory; do **not** write files yet. Present all three drafts to the user in a single message, clearly labeled, and ask for confirmation.

Use this template for the preview (adapt to the detected values):

```
Personalization preview — detected from the project:

  Name:         <project-name>
  Description:  <one-line description, or "(none found)">
  Stack:        <language, framework, DB, container runtime — whichever applied>

I will write:

  1. rosetta-docs/astro.config.mjs
     starlight.title → "<project-name>"
     starlight.description → "<description>"

  2. rosetta-docs/src/content/docs/index.mdx
     Replace the generic Rosetta splash with a project-aware splash
     that names <project-name> in the H1 and links into the four
     Diátaxis sections.

  3. rosetta-docs/src/content/docs/explanation/overview.mdx  (new file)
     A first overview page describing what <project-name> is, the
     stack it uses, and where to start in the docs. Includes a
     <!-- rosetta:personalized ... --> marker so this skill won't
     re-run.

Ok to proceed? (yes / no / adjust)
```

On **yes**: proceed to Step 5.
On **no**: stop, no files written.
On **adjust**: ask the user which field they want to change, update the draft, re-preview. Loop until yes or no.

### Step 5 — Write the three files

Only after the user said yes.

**`rosetta-docs/astro.config.mjs`**: `Edit` the existing file. Replace the `title:` and `description:` values inside the `starlight({ ... })` call. Leave `customCss`, `components`, `sidebar`, and the `checkCategory()` integration untouched — they're load-bearing for the rest of the template.

**`rosetta-docs/src/content/docs/index.mdx`**: `Write` (overwrite). Keep the same Astro/Starlight conventions the original used:
- Same frontmatter shape: `title` (project name), `description` (project description).
- Keep `<p class="rosetta-eyebrow">` / `<div class="rosetta-hairline" />` / `<p class="rosetta-lede">` / `<div class="rosetta-cards">` structure — they're styled by `src/styles/rosetta.css`.
- Replace the copy with project-aware text (one sentence for the eyebrow, one for the lede, four cards that link to the Diátaxis sections).

**`rosetta-docs/src/content/docs/explanation/overview.mdx`**: `Write` (new file). Required frontmatter per §2 of `agent-docs-rules.md`:

```yaml
---
title: <project-name> overview
description: <one-sentence summary of what the project is and what it's for>
category: explanation
---
```

Body: a personalization marker as the first line of the body (inside an HTML comment so it doesn't render), then the overview itself. Structure:

```mdx
<!-- rosetta:personalized at=<ISO timestamp> project-slug=<slug> -->

<opening paragraph naming the project and its purpose>

## Stack

<bullet list of detected language/framework/DB/deploy>

## Where to start

<links to the four Diátaxis sections with one-line hooks each>
```

Everything after the marker is user-editable content — do not touch it on the guard check; only look for the marker string `rosetta:personalized`.

### Step 6 — Gate: `pnpm check` / `npm run check`

Detect which package manager is on PATH and run the schema gate from the project root:

- pnpm: `pnpm -C rosetta-docs check`
- npm: `npm --prefix rosetta-docs run check`

Must report `0 errors`. If it fails, the common culprits are:
- `category: explanation` missing (§2 — required on non-root pages).
- Frontmatter YAML broken by an unescaped quote in the detected description.
- Slug collision with an existing explanation page (unlikely — `overview` is reserved-feeling but not shipped in the template).

Iterate until clean.

### Step 7 — Report

Tell the user exactly:

1. The three file paths touched.
2. The detected project name, description, and stack you baked in.
3. The gate result (`pnpm check` passed).
4. If a dev server is up: the URLs to click (`http://localhost:4321/`, `http://localhost:4321/explanation/overview/`).
5. A note that the skill is now one-shot-locked — for edits, use `/rosetta:write-docs`.

## Constraints

- **Never re-run.** The Step 2 guard is load-bearing; bypassing it risks overwriting user edits to the overview.
- **Never invent stack details.** If `package.json` lists `react` but there's no `next` and no `astro`, don't call the stack "Next.js" — call it "React". Detect-don't-guess.
- **Never skip the preview.** The preview + user yes/no is the safety net; writing without confirmation defeats the point of an interactive skill.
- **Never touch files outside the three.** If the detected project changes imply that a different file should also update (e.g., `Dockerfile` has a stale project name) — surface that in the report as a suggestion, don't auto-edit.

## What the user should see at the end

```
Personalized rosetta-docs/ for <project-name>.

  Name:        <project-name>
  Description: <one-line>
  Stack:       <comma-separated summary>

  Wrote:
    rosetta-docs/astro.config.mjs           (title + description)
    rosetta-docs/src/content/docs/index.mdx (splash)
    rosetta-docs/src/content/docs/explanation/overview.mdx (new)

  Gate: pnpm check → 0 errors.

  Next: /rosetta:write-docs "<your first real page topic>".
  To edit the overview later: /rosetta:write-docs "update the project overview".
  This skill is now one-shot-locked; re-running will be refused by its guard.
```
