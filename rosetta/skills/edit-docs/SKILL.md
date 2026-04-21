---
name: edit-docs
description: Updates an existing MDX page in a Rosetta docs site at rosetta-docs/. Use when the user says "update X", "fix the Y page", "revise Z", "expand the W section", "correct V in the docs", "amend the docs for U", or "add a paragraph/section to A". Locates the page by explicit path, /llms.txt title match, or NL search; refuses if the page is missing (defers to /rosetta:write-docs). Applies a targeted Edit by default; opts into a full-section rewrite only on explicit rewrite phrasing. Dispatches the rosetta-code-researcher subagent only when the requested change asserts code behavior (symbols, endpoints, flows). Stamps `last_updated` to today's date on every patch. Validation runs via the plugin's Stop hook.
argument-hint: "<page ref> <change>"
allowed-tools: Read Edit Glob Grep Task Bash(test *) Bash(ls rosetta-docs/*) Bash(curl -fsS http://localhost:4321/*) Bash(command -v *)
---

# edit-docs

Updates an existing MDX page in a Rosetta-powered docs site. The symmetric counterpart to `write-docs`: that skill creates, this one updates. Locates a page by path / title / NL query, applies a targeted `Edit` by default, stamps `last_updated`, and relies on the plugin's Stop hook to run `astro check` at end-of-turn.

The user asked you to change an existing page — fix a typo, update a section with new behavior, add a paragraph. Your job is to translate that ask into a surgical patch that preserves the page's classification, frontmatter integrity, component usage, and style, without fabricating code behavior that isn't in the source.

## Why this skill exists

`write-docs` and the `doc-*` presets create new pages. Until now, updating a page has fallen through to raw `Edit` tool usage — which bypasses the domain discipline the doc-writing playbooks enforce. Broken frontmatter, deleted imports, drifted `category` values, and marketing-voice rewrites have slipped through.

Four things matter:

1. **Locate correctly.** A page reference like "the JWT middleware page" can match multiple pages. Silent top-1 ranking overwrites the wrong page. The skill asks when ambiguous.
2. **Patch, don't rewrite.** Default is a targeted `Edit` that preserves surrounding structure. Full-section rewrite is opt-in, bounded to a single section.
3. **Preserve invariants.** `category`, slug, imports, `<CopyMarkdownButton/>` placement — none of these move unless the user explicitly asked for a reclassification or rename (neither of which this skill handles).
4. **Stamp the date.** Every patch updates `last_updated` so readers know page recency. Same-day re-edits are idempotent.

## Path discipline

All `Bash` / `Read` / `Edit` paths stay spelled out as `rosetta-docs/...` relative to the project root. The Bash tool's working directory persists between calls; a bare `cd rosetta-docs` silently breaks the next `test -d rosetta-docs/...` guard.

## A note on the frontmatter-guard hook

The plugin ships a `PreToolUse(Write)` hook (`frontmatter-guard.sh`) that warns when a **new** MDX's `category` doesn't match its parent folder. That hook does **not** fire on `Edit` — this skill uses `Edit`, so the guard is bypassed. Step 8's snapshot-diff is the in-skill replacement. Do not rely on the hook here.

## Workflow

Follow these steps in order.

### Step 1 — Pre-flight: `rosetta-docs/` must exist

```bash
test -d rosetta-docs/src/content/docs && echo "docs-ready" || echo "docs-missing"
```

If `docs-missing`, tell the user:

> This project doesn't have a Rosetta docs folder yet. Run `/rosetta:init-docs` first to scaffold `rosetta-docs/`, then re-run `/rosetta:edit-docs` with your topic.

Stop.

### Step 2 — Re-read the rules

Read `rosetta-docs/agent-docs-rules.md` in full. The style rules in §5 and the component rules in §3 apply to edits just as strongly as to new pages — an edit can introduce marketing voice or unsanctioned HTML as easily as a fresh draft can.

You will cite section numbers in the final report for non-obvious choices (e.g. *"§5: converted heading 'Refreshing Tokens' → 'Refresh tokens' (sentence case)"*).

### Step 3 — Locate the target page

Apply precedence in order; stop at the first confident match:

1. **Explicit path.** If the user's input resolves to a file under `rosetta-docs/src/content/docs/**/*.{mdx,md}`, use it.
2. **`/llms.txt` title match.** If `/health` confirms the local docs server is rosetta, fetch `/llms.txt` and score each entry's `title` against the user's page reference. Use token overlap, not substring — titles are sentence-case ("How to use the JWT middleware") while user queries are casual ("JWT middleware page").

    ```bash
    curl -fsS http://localhost:4321/health | grep -q '"service":"rosetta"' && echo "rosetta-up" || echo "rosetta-down-or-other"
    ```

    If `rosetta-up`, fetch:

    ```bash
    curl -fsS http://localhost:4321/llms.txt
    ```

3. **NL disk search.** Glob `rosetta-docs/src/content/docs/**/*.{mdx,md}`, Grep bodies for keywords from the user's page reference. Rank by title-match strength + keyword density.

**Zero matches:**

> No page matches your reference. If this is a new topic, use `/rosetta:write-docs "<your topic>"` to create it.

Stop.

**2+ matches:** list candidates, numbered, one line each with the HTML URL and the frontmatter `title`. Ask the user to pick by number or pass an explicit path:

```
I found multiple pages that could match:

  1. How to use the JWT middleware   — http://localhost:4321/how-to/jwt-middleware/
  2. JWT reference                    — http://localhost:4321/reference/jwt/
  3. Authentication architecture      — http://localhost:4321/explanation/auth/

Which one? (reply with a number, or re-invoke with an explicit path like
/rosetta:edit-docs rosetta-docs/src/content/docs/how-to/jwt-middleware.mdx)
```

Wait for the answer. Never silently top-1.

### Step 4 — Read the current page and snapshot invariants

Read the located file. Prefer the HTTP raw-MD twin when the server is up (same URL-mapping rule as `query-docs`: strip trailing slash, append `.md`; root is `/` → `/index.md`):

```bash
curl -fsS http://localhost:4321/<section>/<slug>.md
```

If the server is down, Read the file from disk: `rosetta-docs/src/content/docs/<section>/<slug>.{mdx,md}`.

When reading via HTTP, **the raw-MD body includes the frontmatter between `---` markers**. Strip it before presenting "current content" to the edit logic — `Edit`'s `old_string` matching will collide with frontmatter lines otherwise.

**Snapshot** these values for Step 8's constraint check:

- frontmatter `category`, `title`, `description`
- `last_updated` (if present) — this one is *expected* to change in Step 7; capture its current value just for the record
- slug (filename stem, e.g. `jwt-middleware`)
- `import` statements at top of file (exact lines, exact order)
- whether `<CopyMarkdownButton/>` appears anywhere (it should not — §3 auto-injects it)

### Step 5 — Gate the researcher

Decide whether to dispatch `rosetta-code-researcher`. **Dispatch** if the requested change asserts code behavior:

- names a symbol, file, endpoint, class, function, module
- uses verbs like "behavior", "returns", "accepts", "fails", "now does X", "has changed"
- mentions a new feature, changed API, new branch of logic, recent refactor

**Skip** for prose-only changes:

- typos, spelling, punctuation
- rephrasing for clarity without changing meaning
- heading case corrections
- sentence tightening

**Ambiguous?** Ask one line:

> Does this change describe code behavior I should verify against the source?

When dispatching, via the Task tool:

- `task_description` — restate the user's ask in concrete terms (e.g. *"confirm how the JWT middleware issues refresh tokens — entrypoint, TTL, storage"*)
- `scope_hint` — paths the current page already cites (extract from the snapshot; e.g. `src/middleware/**`, `src/auth/refresh.ts`). If no citations, omit.
- `playbook_path` — omit. This skill is generic; the editor inherits whatever classification the existing page has.

The researcher returns a 5-section brief. **Draft from its citations only.** If the brief's *Edge cases & ambiguities* flag something you cannot resolve from citations, ask the user before drafting — do not guess.

### Step 6 — Determine mode

Default: **targeted**.

Enter **rewrite mode** only when one of:

- the user uses an explicit rewrite verb: "rewrite the X section", "replace section Y with", "redo the introduction"
- the targeted changeset would replace ≥~40% of a named section (rewriting three of four paragraphs — just rewrite the section)

Announce the chosen mode in one line before editing, e.g.:

> Mode: targeted — two hunks in the "Refresh tokens" section.

Rewrite mode is bounded to **a single section's heading range**. Never the whole file.

### Step 7 — Apply the patch + stamp `last_updated`

**Content patch:**

- **Targeted mode**: `Edit` with `old_string` widened to include unique surrounding context. Repeated phrasing in MDX (e.g. two "Returns 200" lines) will fail `old_string` uniqueness — widen to the unique nearest heading, preceding sentence, or preceding list marker.
- **Rewrite mode**: `old_string` = the entire named section, from the section heading through the next peer heading (exclusive). `new_string` = the rewritten section, preserving the heading exactly.

Never touch `import` statements or `<CopyMarkdownButton/>` (constraint layer).

**Stamp the date** with a second `Edit` targeted at the frontmatter:

- If the frontmatter has `last_updated: <date>`: replace that line with `last_updated: YYYY-MM-DD` (today).
- If the frontmatter has no `last_updated` key: add the line immediately after `description`, preserving the rest of the block.
- Format is date-only (`YYYY-MM-DD`), not datetime — matches the Zod `z.coerce.date()` coercion and keeps diffs small across same-day re-edits.
- Today's date comes from the session's known date.

Same-day re-edits are idempotent (the date equals the current value; `Edit` becomes a no-op on the stamp line).

### Step 8 — Verify invariants

Re-Read the file. Diff against the Step 4 snapshot:

- `category` unchanged (refuse + revert if changed — this skill does not reclassify)
- `title` unchanged, OR changed only if the user explicitly asked
- `description` unchanged unless the body summary materially shifted
- `last_updated` = today's date (confirm the stamp landed; re-stamp if missing)
- `import` statements same lines, same order
- slug (file path) unchanged

If any unexpected drift (other than `last_updated` advancing): `Edit` again to restore, report the attempted mutation to the user.

### Step 9 — Optional: verify render (if dev server is up)

Re-check the server is rosetta (another service may have started on :4321 between Step 3 and now):

```bash
curl -fsS http://localhost:4321/health | grep -q '"service":"rosetta"' && echo "rosetta-up" || echo "no-rosetta"
```

If `rosetta-up`, fetch the page and its raw-MD twin:

```bash
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>/
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:4321/<category>/<slug>.md
```

Both should be `200`.

If `no-rosetta` or the probe fails, skip this step — it's not the editor's job to start the server. Note the skip in the report.

### Step 10 — Report

Short, nothing more:

```
Edited rosetta-docs/src/content/docs/how-to/jwt-middleware.mdx.

  Mode:            targeted  (2 hunks in "Refresh tokens" section)
  Located by:      /llms.txt title match ("How to use the JWT middleware")
  Researcher:      dispatched  (change asserts refresh-token behavior)
  Citations used:  src/middleware/jwt.ts:40-88, src/auth/refresh.ts:12-60
  Stamped:         last_updated: 2026-04-21
  URL:             http://localhost:4321/how-to/jwt-middleware/
  Raw MD:          http://localhost:4321/how-to/jwt-middleware.md
  Check:           Stop hook will run `astro check` at end-of-turn.

Notes:
  - §5: converted heading "Refreshing Tokens" → "Refresh tokens" (sentence case).
  - Preserved <CopyMarkdownButton/>, imports block, category, slug.
```

Never claim `astro check` passed — you didn't run it, the Stop hook did / will. If the next turn opens with hook stderr in context, iterate on the patch.

## Constraints

- **Refuse on missing file.** Mirror of `write-docs`'s "file already exists" guard — flipped. Defer to `/rosetta:write-docs`.
- **Never change** `category`, `slug`, the file path, `import` statements, `<CopyMarkdownButton/>`, or `description` (unless the body summary genuinely shifted).
- **Never delete a section** without explicit user confirmation.
- **Preserve section order** unless the user explicitly asks to reorder.
- **Never reorder imports** — MDX is order-sensitive for some Starlight overrides.
- **Never fabricate code behavior.** The researcher gate exists for this. If ambiguity remains after the brief, ask — don't guess.
- **Never claim the check passed.** The Stop hook is authoritative; its silence is pass, its stderr is fail.
- **Always stamp `last_updated`** to today's date on every patch. Same-day re-edits are idempotent — the stamp stays at today.
- **Support both `.mdx` and `.md`** in Step 3 globs; the template ships sample pages as `.md`.

## What the user should see at the end

A short report, nothing more — no summary of the hunks. The user saw the `Edit` tool calls; they don't need them narrated.
