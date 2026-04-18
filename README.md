# rosetta-plugin

The Claude Code plugin that operates [**Rosetta.md**](https://github.com/marincervinschi/rosetta-template) — an AI-native documentation system built on Astro Starlight.

- **Template** ([`rosetta-template`](https://github.com/marincervinschi/rosetta-template)) — the physical baseline: Starlight app, Diátaxis layout, Zod schema, `agent-docs-rules.md`, `/llms.txt` + raw-MD endpoints.
- **Plugin** (this repo) — the agent operator: skills + slash commands that teach Claude Code to scaffold, write, and query docs against the template.

See the [orchestrator overview](https://github.com/marincervinschi/Rosetta.md/blob/main/orchestrator.md) for how the two repos fit together.

## Status

**v0.1.0 — under active development.** Phase B1 (skeleton) and B2 (`init-docs` / `/rosetta:init-docs`) are the current focus. Phases B3 (`write-docs`) and B4 (`query-docs`) are stubbed and will be filled in next.

| Skill | Command | Phase | Status |
|---|---|---|---|
| `init-docs` | `/rosetta:init-docs` | B2 | In progress |
| `write-docs` | `/rosetta:write-docs` | B3 | Stub |
| `query-docs` | `/rosetta:query-docs` | B4 | Stub |

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
- **Node.js ≥ 22** and **pnpm ≥ 10** — required by [`rosetta-template`](https://github.com/marincervinschi/rosetta-template). `pnpm` is the package manager of record; `npm` and `yarn` are not supported.
- **Docker** — optional, needed only for the *persistent* mode of the docs server.
- **git** — needed to clone the template on `/rosetta:init-docs`.

## Compatibility

| Plugin version | Requires rosetta-template |
|---|---|
| `v0.1.x` | `≥ v0.1.0` |

Breaking changes to the [contract surface](https://github.com/marincervinschi/Rosetta.md/blob/main/orchestrator.md#contract-surface-the-interface-between-the-two-repos) bump the major version of both repos together.

## Quickstart

```
# 1. Install the plugin (once per machine)
/plugin install github.com/MarinCervinschi/rosetta-plugin

# 2. In any project, scaffold docs/ and start the dev server
/rosetta:init-docs

# 3. (Phase B3, coming) Write a new doc page
/rosetta:write-docs "document the JWT auth middleware"

# 4. (Phase B4, coming) Ask the docs for context
/rosetta:write-docs "how does auth work in this repo?"
```

## Architecture note: skills over commands

Claude Code merges custom slash commands into skills: both `skills/<name>/SKILL.md` and `commands/<name>.md` produce a `/<plugin>:<name>` entry. This plugin uses only `skills/` — it's the recommended path for new plugins and avoids duplicate definitions. The slash command surface is derived from skill names.

## Design principles

- **Skills, not MCP.** Markdown instructions + native Claude tools (`Read`, `Write`, `Bash`, `Grep`, `WebFetch`). Zero runtime dependency, maximum portability.
- **Point to the template's rules; don't duplicate them.** Skills re-read `docs/agent-docs-rules.md` at runtime — the rules file is canonical.
- **Fallback-ready.** HTTP fetches against `localhost:4321` degrade to file reads when the server is down.
- **No deep decision-making.** Diátaxis classification is a small, explicit decision tree encoded in the skill body.

## License

MIT — see [LICENSE](./LICENSE).
