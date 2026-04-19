---
name: query-docs
description: Retrieves context from an existing Rosetta docs site to answer a question with citations. Use when the user asks "how does X work in this project", "what do the docs say about Y", "find docs for Z", "is this documented anywhere", or whenever Claude needs documentation context to perform another task (e.g. fixing a bug in a documented area). Fetches /llms.txt, ranks pages by relevance, pulls the raw-MD twins of the top matches, and synthesizes a cited answer. Degrades to local file reads when the docs server is down.
argument-hint: "<question>"
allowed-tools: Read Glob Grep Bash(test *) Bash(ls docs/*) Bash(curl -fsS http://localhost:4321/*) Bash(curl -fsS -w * http://localhost:4321/*)
---

# query-docs

Answers a question by pulling real content from a Rosetta docs site — `/llms.txt` for the index, `/<slug>.md` for each page — and synthesizes a response with citations. If the HTTP server is down, degrades cleanly to reading MDX files from `docs/src/content/docs/`.

The user asked a question (or Claude needs doc context for another task). Your job is to find the right pages, pull them, cite them, and answer — without making up content that isn't in the pages you read.

## Why this skill exists

Rosetta docs are *the* context store for a project that uses them. When Claude is working on an unrelated task — fixing a bug, adding a feature — the docs may already explain the invariants it needs to respect. Skipping them and reasoning from first principles wastes effort and risks contradicting what's written.

Three things matter:

1. **HTTP-first, disk-fallback.** The dev server, when up, is the canonical source: it reflects the *current* file state plus any frontmatter coercion the schema applies. File reads are the backup when the server is down or the user hasn't started it.
2. **Cite by HTML URL.** Every claim you attribute to the docs gets the browser URL (`http://localhost:4321/how-to/deploy/`). The user can click it; the raw-MD twin is for you, not them.
3. **Don't invent.** If the top-ranked pages don't cover what the user asked, say so and propose `/rosetta:write-docs "<topic>"`. A confidently wrong answer is worse than "not documented here."

## Workflow

Follow these steps in order.

### Step 1 — HTTP-first: fetch the index

```bash
curl -fsS http://localhost:4321/llms.txt
```

The response is `text/plain`, llmstxt.org-format. Expect:

```
# <Site title>

> <One-line site description>

## Home
- [<title>](<url>): <description>

## Tutorials
- [<title>](<url>): <description>
...

## How-to guides
- [<title>](<url>): <description>
...

## Reference
- [<title>](<url>): <description>
...

## Explanation
- [<title>](<url>): <description>
...
```

Parse into a list of `{section, title, url, description}`. Keep the raw text around — you'll cite by the HTML URL verbatim.

If the `curl` fails (connection refused, timeout, non-200), skip to **Step 4 — disk fallback**. Don't retry for minutes; two quick attempts and move on.

### Step 2 — Rank by relevance

Score each entry against the user's question using three signals, in order of weight:

1. **Title match** — keywords from the question appearing in the entry title.
2. **Description match** — keywords in the one-line description.
3. **Section match** — "how do I..." questions lean `how-to`; "what is...", "why..." lean `explanation` / `reference`.

Pick the top 1–3 entries. Going wider than 3 dilutes citations and wastes tokens; narrower than 1 means you shouldn't be answering at all.

If nothing scores plausibly, tell the user the docs don't cover this and offer `/rosetta:write-docs "<their topic>"`. Stop.

### Step 3 — Fetch the raw-MD twin of each top entry

Apply the URL mapping rule to convert an HTML URL from `/llms.txt` into the raw-MD URL:

| HTML URL | Raw-MD URL |
|---|---|
| `/` | `/index.md` |
| `/tutorials/` | `/tutorials.md` |
| `/how-to/deploy/` | `/how-to/deploy.md` |
| `/reference/schemas/user/` | `/reference/schemas/user.md` |

General rule: strip the trailing slash, append `.md`. The root splash (`/` → `/index.md`) is the only special case.

Then:

```bash
curl -fsS http://localhost:4321/<section>/<slug>.md
```

The response body includes the YAML frontmatter (between `---` markers) *inside* the body — use `title` and `description` from frontmatter as canonical citation metadata.

If a specific fetch fails (404, 500, timeout), fall back to disk for *that* page: `docs/src/content/docs/<section>/<slug>.mdx` (or `.md`). Don't let one bad fetch abort the whole query.

### Step 4 — Disk fallback (when HTTP is unavailable)

If Step 1's `curl` failed, you're in fallback mode. Locate docs locally:

```bash
test -d docs/src/content/docs && ls docs/src/content/docs/
```

If the directory is missing, skip to **Step 5 — both failed**.

Otherwise, use `Glob` to enumerate `.md` and `.mdx` files, then `Read` the candidates matching the question's topic. The file content is identical to what the HTTP endpoint would return (frontmatter + body). Use `Grep` to narrow when the set is large.

Without `/llms.txt`'s curated summaries, ranking is coarser — fall back to filename + frontmatter `title` + frontmatter `description` as your signal. Still pick top 1–3.

### Step 5 — Both sources unavailable

If the dev server is down AND `docs/src/content/docs/` doesn't exist, the user has no docs to query. Tell them:

> I can't answer this from docs — the dev server isn't responding on `localhost:4321` and I don't see a local `docs/` folder either. Start the docs with `/rosetta:init-docs`, or if docs exist in this repo, `cd docs && pnpm dev` to bring the server up.

Stop. Don't speculate an answer from training data — the whole point of this skill is grounding.

### Step 6 — Synthesize with citations

Write the answer in the user's voice: short, direct, no preamble. Cite each claim inline by HTML URL:

> To deploy on Vercel, push to the `main` branch and Vercel's build will invoke `pnpm build` in `docs/`. See [Deploy to Vercel](http://localhost:4321/how-to/deploy/vercel/) for the full walkthrough.

Rules:

- **Cite every load-bearing fact** with the HTML URL (not the `.md` twin — that's for machines).
- **If two pages disagree**, surface the contradiction; don't paper over it.
- **If the pages cover only part of the question**, answer the documented part and explicitly name the gap. Suggest `/rosetta:write-docs` for the gap if the user asks how to fill it.

## Constraints

- **Never fabricate a citation.** A URL that isn't in the fetched content is worse than "no citation." If unsure whether a URL exists, re-fetch `/llms.txt` and check.
- **Never skip the disk fallback.** The server may be rebuilding; a connection-refused is not a "no docs" verdict.
- **Never invent page content.** If the answer requires information not in the fetched raw-MD, say so and propose `/rosetta:write-docs`.
- **Never cite the `.md` twin URL to the user.** Cite the HTML URL — the `.md` is an implementation detail.
- **Don't fetch more than ~5 pages per query.** If 3 top matches aren't enough, the question is too broad or the docs don't cover it.

## What the user should see at the end

A direct answer with citations, no scaffolding:

```
To configure the frontmatter schema, extend the Zod object in
`docs/src/content.config.ts`. The required fields are `title` and
`description`; `category` is an enum that must match the parent
folder. See [Frontmatter schema](http://localhost:4321/reference/frontmatter-schema/)
for the full field list.

The `category` value is validated at build time against the folder
name — a mismatch fails `pnpm check`. See [Agent rules §2](http://localhost:4321/reference/agent-rules/) for the exact rule.
```

No "based on the docs I read…" opener. Just the answer.
