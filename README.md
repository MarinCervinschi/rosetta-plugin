# rosetta-plugin

The Claude Code plugin that operates [**Rosetta.md**](https://github.com/marincervinschi/rosetta-template) — an AI-native documentation system built on Astro Starlight.

- **Template** ([`rosetta-template`](https://github.com/marincervinschi/rosetta-template)) — the physical baseline: Starlight app, Diátaxis layout, Zod schema, `agent-docs-rules.md`, `/llms.txt` + raw-MD endpoints.
- **Plugin** (this repo) — the agent operator: skills + slash commands that teach Claude Code to scaffold, write, and query docs against the template.

See the [orchestrator overview](https://github.com/marincervinschi/Rosetta.md/blob/main/orchestrator.md) for how the two repos fit together.

## Status

**v0.2.0 — under active development.** All three v0.1 skills shipped in B2–B4 and were adapted in B2.5 to target the scoped `rosetta-docs/` directory and the new `/health` endpoint introduced by [rosetta-template v0.2.0](https://github.com/MarinCervinschi/rosetta-template/releases). Owner-led manual dogfooding precedes the `v0.2.0` tag.

| Skill | Command | Phase | Status |
|---|---|---|---|
| `init-docs` | `/rosetta:init-docs` | B2 | Shipped (v0.2.0 contract) |
| `write-docs` | `/rosetta:write-docs "<topic>"` | B3 | Shipped (v0.2.0 contract) |
| `query-docs` | `/rosetta:query-docs "<question>"` | B4 | Shipped (v0.2.0 contract) |

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

Breaking changes to the [contract surface](https://github.com/MarinCervinschi/Rosetta.md/blob/main/orchestrator.md#contract-surface-the-interface-between-the-two-repos) bump the minor version of both repos together while we're in `0.x`; from `1.0.0` onwards this becomes a major bump. Full release history in [`CHANGELOG.md`](./CHANGELOG.md).

## Quickstart

```
# 1. Install the plugin (once per machine)
/plugin install github.com/MarinCervinschi/rosetta-plugin

# 2. In any project, scaffold rosetta-docs/ and start the dev server
/rosetta:init-docs

# 3. Write a new doc page (Claude classifies via Diátaxis and runs pnpm check)
/rosetta:write-docs "document the JWT auth middleware"

# 4. Ask the docs for cited context (fetches /llms.txt, falls back to disk)
/rosetta:query-docs "how does auth work in this repo?"
```

## Architecture note: skills over commands

Claude Code merges custom slash commands into skills: both `skills/<name>/SKILL.md` and `commands/<name>.md` produce a `/<plugin>:<name>` entry. This plugin uses only `skills/` — it's the recommended path for new plugins and avoids duplicate definitions. The slash command surface is derived from skill names.

## Design principles

- **Skills, not MCP.** Markdown instructions + native Claude tools (`Read`, `Write`, `Bash`, `Grep`, `WebFetch`). Zero runtime dependency, maximum portability.
- **Point to the template's rules; don't duplicate them.** Skills re-read `rosetta-docs/agent-docs-rules.md` at runtime — the rules file is canonical.
- **Fallback-ready.** HTTP fetches against `localhost:4321` degrade to file reads when the server is down. `/health` is used to confirm the server is a rosetta site before fetching content.
- **No deep decision-making.** Diátaxis classification is a small, explicit decision tree encoded in the skill body.
- **Meet the user where they are.** Prefer pnpm but support npm. Clone into `rosetta-docs/` to avoid colliding with an existing `docs/`.

## License

MIT — see [LICENSE](./LICENSE).
