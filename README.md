# rosetta-plugin

The Claude Code plugin that operates **Rosetta.md** — an AI-native documentation system built on Astro Starlight.

Rosetta.md is a two-repo system:

- **Template** ([`MarinCervinschi/rosetta-template`](https://github.com/MarinCervinschi/rosetta-template)) — the physical baseline: Starlight app, Diátaxis layout, Zod schema, `agent-docs-rules.md`, `/health` + `/llms.txt` + raw-MD endpoints.
- **Plugin** ([`MarinCervinschi/rosetta-plugin`](https://github.com/MarinCervinschi/rosetta-plugin), this repo) — the agent operator: skills that teach Claude Code to scaffold, personalize, write, and query docs against the template.

## Status

**v0.3.0 — active development.** `v0.2.0` is tagged and public; `v0.3.0` adds `/rosetta:personalize-docs` for project-aware customization of the scaffold, plus the scaffolded directory structure for four topic presets (`doc-auth`, `doc-db`, `doc-migrations`, `doc-patterns`). The presets themselves are disabled in `v0.3.0` — their content playbooks land in `v0.4.0`.

| Skill | Command | Phase | Status |
|---|---|---|---|
| `init-docs` | `/rosetta:init-docs` | B2 | Shipped |
| `write-docs` | `/rosetta:write-docs "<topic>"` | B3 | Shipped |
| `query-docs` | `/rosetta:query-docs "<question>"` | B4 | Shipped |
| `personalize-docs` | `/rosetta:personalize-docs` | C1 | Shipped in v0.3.0 |
| `doc-auth` | `/rosetta:doc-auth` | C2 | Scaffolded in v0.3.0, content in v0.4.0 |
| `doc-db` | `/rosetta:doc-db` | C2 | Scaffolded in v0.3.0, content in v0.4.0 |
| `doc-migrations` | `/rosetta:doc-migrations` | C2 | Scaffolded in v0.3.0, content in v0.4.0 |
| `doc-patterns` | `/rosetta:doc-patterns` | C2 | Scaffolded in v0.3.0, content in v0.4.0 |

## Install

```
/plugin install github.com/MarinCervinschi/rosetta-plugin
```

During development, load directly from disk:

```bash
claude --plugin-dir /path/to/rosetta-plugin
```

## Prerequisites

- **Claude Code** (any recent version with plugin support).
- **Node.js ≥ 22** — required by [`rosetta-template`](https://github.com/MarinCervinschi/rosetta-template).
- **A package manager** — `pnpm ≥ 10` (recommended; what the template's lockfile targets) or `npm`. The `init-docs` skill prefers pnpm and falls back to npm if pnpm isn't on PATH.
- **Docker** — optional, needed only for the *persistent* mode of the docs server.
- **git** — needed to clone the template on `/rosetta:init-docs`.

## Compatibility

| Plugin version | Requires rosetta-template | Clones into |
|---|---|---|
| `v0.2.x` | `≥ v0.2.0` | `rosetta-docs/` |
| `v0.3.x` | `≥ v0.2.0` | `rosetta-docs/` |

`v0.3.0` is backward-compatible with `rosetta-template v0.2.0` — `/rosetta:personalize-docs` edits files inside the scaffolded `rosetta-docs/` but doesn't rely on any new template surface. Breaking changes to the contract surface (paths under `rosetta-docs/`, Zod frontmatter schema, HTTP endpoint shapes, `agent-docs-rules.md` sections) bump the minor version of both repos together while we're in `0.x`; from `1.0.0` onwards this becomes a major bump. Full release history in [`CHANGELOG.md`](./CHANGELOG.md).

## Quickstart

```
# 1. Install the plugin (once per machine)
/plugin install github.com/MarinCervinschi/rosetta-plugin

# 2. In any project, scaffold rosetta-docs/ and start the dev server
/rosetta:init-docs

# 2b. (optional, recommended) personalize the scaffold with your project's
#     name, stack, and a starting overview page. One-shot.
/rosetta:personalize-docs

# 3. Write a new doc page (Claude classifies via Diátaxis and runs pnpm check)
/rosetta:write-docs "document the JWT auth middleware"

# 4. Ask the docs for cited context (fetches /llms.txt, falls back to disk)
/rosetta:query-docs "how does auth work in this repo?"
```

## Design principles

- **Skills, not MCP.** Markdown instructions + native Claude tools (`Read`, `Write`, `Bash`, `Grep`, `WebFetch`). Zero runtime dependency, maximum portability.
- **Point to the template's rules; don't duplicate them.** Skills re-read `rosetta-docs/agent-docs-rules.md` at runtime — the rules file is canonical.
- **Fallback-ready.** HTTP fetches against `localhost:4321` degrade to file reads when the server is down. `/health` is used to confirm the server is a rosetta site before fetching content.
- **No deep decision-making.** Diátaxis classification is a small, explicit decision tree encoded in the skill body.
- **Meet the user where they are.** Prefer pnpm but support npm. Clone into `rosetta-docs/` to avoid colliding with an existing `docs/`.

## License

MIT — see [LICENSE](./LICENSE).
