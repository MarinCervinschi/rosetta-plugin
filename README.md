# rosetta-plugin

A Claude Code plugin that turns an AI agent into a competent documentation writer for your project. It scaffolds a docs site, personalizes it with your project's identity, and writes Diátaxis-classified pages with schema-validated frontmatter that your build can't silently break.

The plugin pairs with [`rosetta-template`](https://github.com/MarinCervinschi/rosetta-template) — an opinionated Astro Starlight baseline with a JSON-driven site identity, a Zod frontmatter schema, raw-markdown twins at `/<slug>.md`, an `/llms.txt` index, and a `/health` readiness probe. You can use the template without the plugin, but the plugin is what makes Claude Code *good* at maintaining it.

## Install

```
/plugin install github.com/MarinCervinschi/rosetta-plugin
```

During development of the plugin itself: `claude --plugin-dir /path/to/rosetta-plugin` (changes pick up on `/reload-plugins`).

## Prerequisites

- **Claude Code** with plugin support.
- **Node.js ≥ 22**.
- **pnpm ≥ 10** (recommended) or **npm**. The skills prefer pnpm and fall back to npm if pnpm isn't on `PATH`.
- **Docker** — optional, only for the persistent "always-on" mode of the docs server.
- **git** — the init skill clones the template.

## Quickstart

```
# Install once per machine
/plugin install github.com/MarinCervinschi/rosetta-plugin

# In your project repo, scaffold rosetta-docs/ and start the dev server
/rosetta:init-docs

# After init, the skill asks if you want to personalize immediately.
# Say yes — it detects your project name, description, and stack from
# package.json / pyproject.toml / go.mod / Cargo.toml / README and
# populates rosetta-docs/src/rosetta.config.json plus a first
# overview page, after showing you the preview.

# Write new pages (Claude classifies the topic via Diátaxis and runs pnpm check)
/rosetta:write-docs "document the JWT auth middleware"

# Or use a topic preset — same engine, pre-framed for a common domain
/rosetta:doc-auth
/rosetta:doc-db
/rosetta:doc-migrations
/rosetta:doc-patterns

# Ask the docs for cited context — works during any conversation
/rosetta:query-docs "how does auth work in this repo?"
```

## Commands

| Command | What it does |
|---|---|
| `/rosetta:init-docs [dev\|docker]` | Clones the template into `rosetta-docs/`, installs deps, starts the server, waits until `/health` returns `service=rosetta`, and offers to personalize right after. |
| `/rosetta:personalize-docs` | One-shot. Detects project name/description/stack from standard metadata files, previews the changes, and writes `rosetta.config.json` + a new `explanation/overview.mdx`. Re-running is refused — edit the JSON directly or use `/rosetta:write-docs` for prose. |
| `/rosetta:write-docs "<topic>"` | Writes an MDX page for any topic. Re-reads `agent-docs-rules.md` + the Zod schema fresh, classifies via the Diátaxis decision tree, drafts with valid frontmatter, uses custom components where they fit, and gates on `pnpm check` before reporting success. |
| `/rosetta:doc-auth [context]` | Preset for the authentication layer. Same engine as `write-docs`, pre-framed with an auth-specific playbook. |
| `/rosetta:doc-db [context]` | Preset for schema / tables / entities / ORM models. |
| `/rosetta:doc-migrations [context]` | Preset for the migration workflow (authoring, applying, rolling back). |
| `/rosetta:doc-patterns [context]` | Preset for cross-cutting patterns — decorators, middleware, filters, factories, services. |
| `/rosetta:query-docs "<question>"` | Answers a question from your existing docs. Fetches `/llms.txt`, ranks pages, pulls the raw-markdown twins of the top matches, and cites each claim by HTML URL. Falls back to disk reads if the dev server is down. Auto-invokable so Claude pulls doc context during unrelated tasks. |

The four `doc-*` presets each ask at the start whether to run **inline** (interactive, pausing for clarifications when the code is ambiguous) or **in background** (best-judgment, unattended). Default is inline — the skill decides to be verbose in your terminal rather than silent.

## What "good output" looks like

Every page the plugin writes satisfies:

1. **Required frontmatter** — `title`, `description`, and a `category` that equals the parent folder name. Nothing else, unless the template extends the schema.
2. **Diátaxis placement** — the page is in `tutorials/`, `how-to/`, `reference/`, or `explanation/`, picked by the first-yes-wins decision tree in `rosetta-docs/agent-docs-rules.md` (re-read fresh on every invocation).
3. **Build passes** — `pnpm -C rosetta-docs check` reports zero errors before the skill reports success. No "mostly works" pages ship.
4. **Real content** — Claude reads your code before it writes prose. If something is ambiguous, it asks instead of inventing.

Contract-surface changes (paths under `rosetta-docs/`, the Zod schema, HTTP endpoint shapes, the rules file's section numbering) are versioned — see [`CHANGELOG.md`](./CHANGELOG.md). The plugin's `CHANGELOG.md` declares the minimum template version each plugin release targets.

## License

MIT — see [LICENSE](./LICENSE).
