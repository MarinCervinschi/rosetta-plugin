---
name: personalize-docs
description: Personalizes a freshly-scaffolded Rosetta docs site with the project's name, tagline, repo URL, and stack. Use right after /rosetta:init-docs, or when the user says "personalize the docs", "customize the docs for this project", "brand the docs with this project's name". One-shot — detects if it has already been run (via the personalized flag in rosetta.config.json) and refuses to re-run. Changes to the landing page later go through /rosetta:write-docs.
argument-hint: ""
allowed-tools: Read Write Edit Glob Grep Task Bash(test *) Bash(ls *) Bash(cat *) Bash(grep *)
---

# personalize-docs

Customizes a freshly-scaffolded Rosetta docs site with the consumer project's identity by editing two files: the metadata JSON that drives the site (`rosetta-docs/src/rosetta.config.json`) and the landing page where the stack and project prose live (`rosetta-docs/src/content/docs/index.mdx`).

The skill is **one-shot**. On second invocation it detects the prior run via `personalized: true` in the JSON and refuses. Updates to the landing page after the first personalization go through `/rosetta:write-docs "update the landing page"` — re-personalization would clobber whatever the user wrote afterwards.

## Why this skill exists

`rosetta-template` keeps the site identity data-driven via a small, essential-only JSON — `rosetta-docs/src/rosetta.config.json` — feeding the site title, tagline, repo URL, and logo. `astro.config.mjs` imports it for Starlight's `title`/`description`/`logo`/`social`; `src/content/docs/index.mdx` uses `{config.name}` and `{config.tagline}` expressions in the hero. Everything else — the stack list, the description prose, the page body — is **plain MDX** on the landing page, edited directly. The config is intentionally narrow; the landing page is the prose surface.

Personalizing a project is therefore two edits:

1. Detect the project's name, tagline, and repo URL from standard metadata and write them into the JSON. Flip `personalized: true`.
2. Detect the stack and rewrite the `## Stack` bullet list on `src/content/docs/index.mdx`. Optionally tighten the opening paragraphs if the README gives you better prose than the template's boilerplate.

The hero (name + tagline + logo + GitHub link) takes care of itself once the JSON is populated. The stack and prose are MDX edits — the skill's real work.

## Path discipline

**All Bash commands in this skill run from the project root** — the directory that *contains* `rosetta-docs/`. The Bash tool's working directory persists between calls; a bare `cd rosetta-docs` would silently break subsequent `test -d rosetta-docs/...` guards.

- For pnpm, use `pnpm -C rosetta-docs <cmd>`.
- For npm, use `npm --prefix rosetta-docs <cmd>`.

All references to the scaffolded folder stay spelled out as `rosetta-docs/...` from the project root.

## Workflow

### Step 1 — Pre-flight: rosetta-docs/ must exist and ship the current config shape

```bash
test -f rosetta-docs/src/rosetta.config.json && echo "ready" || echo "missing"
```

Then spot-check the shape — `stack` and `description` must **not** be in the config (they moved out):

```bash
grep -q '"stack"' rosetta-docs/src/rosetta.config.json && echo "legacy" || echo "current"
```

If `missing` or `legacy`, tell the user:

> I can't personalize this docs site — either it hasn't been scaffolded yet, or it was scaffolded from an older template that still kept the stack in the config. Run `/rosetta:init-docs` to scaffold (or re-scaffold into a fresh directory) against the current template, then re-run `/rosetta:personalize-docs`.

Stop. Don't try to create or migrate the JSON yourself — you'd be patching over a version mismatch that downstream tools rely on.

### Step 2 — Guard: has this skill already run?

```bash
grep -q '"personalized": true' rosetta-docs/src/rosetta.config.json && echo "already-personalized" || echo "fresh"
```

If `already-personalized`, read the JSON's `name` and `personalizedAt` fields for the message, and tell the user:

> `rosetta-docs/` has already been personalized (project: `<name>`, at `<personalizedAt>`). This skill is one-shot on purpose — to update the landing page or rebrand, use `/rosetta:write-docs "update the landing page"` (or edit `rosetta-docs/src/rosetta.config.json` directly for metadata). If you want to re-personalize from scratch, set `"personalized": false` in the JSON and re-run.

Stop. No changes.

### Step 3 — Detect project metadata (via `rosetta-code-researcher`)

Dispatch the `rosetta-code-researcher` subagent to do the detection scan. The researcher reads the project's manifests and returns a 5-section brief; you convert that brief into the preview (Step 4) and the two file writes (Step 5).

Dispatch prompt should include:

- `task_description`: `"Detect project identity for Rosetta docs personalization — project name, tagline, repo URL, language/runtime, framework, database/ORM, deployment targets."`
- `playbook_path`: `${CLAUDE_PLUGIN_ROOT}/skills/write-docs/references/metadata.md` (the researcher follows this playbook — it's the authoritative list of files to read, fields to extract, and what to surface as an ambiguity)
- `scope_hint`: project root only (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `README.md`, `Dockerfile`, etc.). The researcher does **not** scan source files for this task.

The researcher returns a brief with **Citations for drafting** as a flat list of `- <field>: <value> (<source>:<line>)` bullets. Use those verbatim in your preview. The **Edge cases & ambiguities** section lists conflicts (e.g. two framework candidates) that you must surface to the user before writing — do not resolve them silently.

Also Read the current `rosetta-docs/src/rosetta.config.json` yourself — any non-default values the user may have edited by hand should be **preserved** (you'll merge with detected values in Step 4, not overwrite blindly). This read stays in the main thread because the target file is in `rosetta-docs/`, not in the project surface the researcher scans.

Don't guess anything the brief doesn't cite. If a signal is absent, **omit the corresponding stack bullet entirely** — empty rows under `## Stack` are worse than a shorter, honest list.

### Step 4 — Draft the two surfaces and preview

Draft in memory; do **not** write files yet. Present both drafts to the user in a single message, clearly labeled, and ask for confirmation.

Use this template for the preview (adapt to the detected values):

```
Personalization preview — detected from the project:

  Name:      <project-name>
  Tagline:   <one-liner suitable for the site subtitle>
  Repo URL:  <https URL, or "(none found)">

  Stack (will go into the landing page bullet list):
    - <Language>     — <short note on how it's used>
    - <Framework>    — <short note>
    - <Database>     — <short note>
    - <Deploy>       — <short note>
  (only rows with a detected value appear)

I will write:

  1. rosetta-docs/src/rosetta.config.json
     Set name, tagline, repoUrl from the detection above.
     Set personalized=true and personalizedAt=<ISO timestamp>.
     Preserve any existing non-default fields in the JSON
     (I merged with what's already there).

  2. rosetta-docs/src/content/docs/index.mdx
     Replace the ## Stack bullet list with the detected entries
     (each bullet: <StackIcon name="..."/> **Name** — short note).
     No other sections on the landing page are touched.

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
  "repoUrl": "<https URL, or null>",
  "logo": { "light": "./src/assets/favicon.svg", "dark": "./src/assets/favicon-dark.svg" },
  "showTemplateCredit": true,
  "personalized": true,
  "personalizedAt": "<ISO-8601 timestamp, e.g. 2026-04-19T18:50:00Z>"
}
```

Preserve any `logo` value the user already set (the template ships a `{ light, dark }` default — don't blindly overwrite). Use actual JSON nulls (not the string `"null"`) for undetected fields. Keep key order stable (same as the template's default) so diffs stay readable.

**`rosetta-docs/src/content/docs/index.mdx`**: surgical `Edit`, **not** full overwrite. Target the `## Stack` section only. The template ships with three placeholder bullets; replace them with the detected entries. Each bullet has this shape:

```mdx
- <StackIcon name="<stack value>" /> **<Display name>** — <one-sentence note on how it's used in this project>.
```

Rules for the bullet list:

- Use the stack value as the `name=` prop (e.g. `"TypeScript"`, `"Next.js"`, `"Postgres"`). The `StackIcon` component normalizes it via the stack-icon map — unknown entries render a small dot fallback, not an error.
- Bold the display name (can differ from the `name=` prop if the display is prettier — e.g. `name="nextjs"` but **Next.js** bolded).
- One-sentence note after the em dash. Keep it concrete — *"static site generator"* beats *"the web framework powering the app"*.
- Omit entire bullets for undetected values. Don't leave a `- <StackIcon name="null" />` row.
- Preserve every other section of the landing page exactly as-is. The `##` heading, the hero, the four Diátaxis cards, "What this template gives you", "Next steps", and the GitHub CTA are not yours to touch.

If the project's `README.md` has a clearly better opening paragraph than the template's boilerplate (the two paragraphs immediately after `# {config.name}` and before `## Stack`), surface that in the preview and, on `yes`, replace those paragraphs too — still as a surgical `Edit`, still preserving the surrounding structure. Don't invent prose; only substitute when the README actually gives you something.

### Step 6 — Gate: Stop hook runs `astro check`

**You do not run the check.** The plugin's Stop hook runs `pnpm -C rosetta-docs check` (or `npm --prefix rosetta-docs run check` as a fallback) at end-of-turn because Step 5 edited an MDX under `rosetta-docs/src/content/docs/`. A failure surfaces in your next turn's context as stderr — iterate on your edits until the hook is silent.

If the check fails, common culprits in this skill's scope:

- A typo in the `StackIcon` import or JSX on the landing page — the `import StackIcon from '~/components/StackIcon.astro';` line must stay intact at the top.
- An unescaped quote or brace in a stack note breaking MDX parsing.
- JSON syntax error from a control character in the name or tagline. Re-examine the detected values; if one contains a newline or quote, sanitize and re-write.

Don't claim success in Step 7 if the next turn opens with hook stderr — fix and re-iterate.

### Step 7 — Report

Tell the user exactly:

1. The two file paths touched.
2. The detected project name, tagline, repo URL, and stack bullets that you baked in.
3. A note that `astro check` will run via the Stop hook at end-of-turn. Don't claim "0 errors" yourself — you haven't run the check.
4. If a dev server is up: the URL to click (`http://localhost:4321/` — the new branded hero + stack list).
5. A note that the skill is now one-shot-locked — for metadata edits, edit the JSON directly; for landing-page prose edits, use `/rosetta:write-docs "update the landing page"`.

## Constraints

- **Never re-run.** The Step 2 guard is load-bearing; bypassing it risks clobbering user edits to the landing page.
- **Never invent stack details.** If `package.json` lists `react` with no `next` and no `astro`, write the bullet as **React** — not **Next.js**. Detect, don't guess.
- **Never skip the preview.** The preview + user yes/no is the safety net; writing without confirmation defeats the point of an interactive skill.
- **Never touch files outside the two.** If the detected project implies another file should also update (e.g., `Dockerfile` has a stale project name) — surface that in the report as a suggestion, don't auto-edit.
- **Never rewrite the whole landing page.** Surgical `Edit`s on the `## Stack` bullets (and optionally the opening paragraphs) only. The rest of the page is the template's — not yours.
- **Never write `"null"` (string) for an undetected field.** Use JSON `null` in the config, and simply omit absent bullets on the landing page.

## What the user should see at the end

```
Personalized rosetta-docs/ for <project-name>.

  Name:      <project-name>
  Tagline:   <tagline>
  Repo URL:  <https URL or "(none)">
  Stack bullets:
    - <Language>     — <note>
    - <Framework>    — <note>
    - ...

  Wrote:
    rosetta-docs/src/rosetta.config.json         (metadata populated + personalized=true)
    rosetta-docs/src/content/docs/index.mdx      (## Stack bullets replaced)

  Check: Stop hook will run `astro check` at end-of-turn.

  Next: /rosetta:write-docs "<your first real page topic>".
  To edit the landing page later: /rosetta:write-docs "update the landing page".
  To adjust metadata (name/tagline/repoUrl) later: edit rosetta-docs/src/rosetta.config.json directly.
  This skill is now one-shot-locked; re-running will be refused by its guard.
```
