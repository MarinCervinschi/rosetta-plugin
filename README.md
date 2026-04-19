# rosetta-plugin

Claude Code plugin for AI-native documentation. Scaffolds a docs site, personalizes it to your project, writes Diátaxis-classified pages, and queries live docs with citations.

Pairs with [`rosetta-template`](https://github.com/MarinCervinschi/rosetta-template).

## Install

Add the marketplace (one-time):

```
/plugin marketplace add MarinCervinschi/rosetta-plugin
```

Install the plugin:

```
/plugin install rosetta@rosetta-md
```

Then reload:

```
/reload-plugins
```

## Prerequisites

- Claude Code (plugin support)
- Node.js ≥ 22
- pnpm ≥ 10 or npm
- git
- Docker — optional, only for the persistent docs-server mode

## Quickstart

Scaffold the docs site and start the dev server:

```
/rosetta:init-docs
```

The skill asks whether to personalize immediately. Say yes — it reads your project metadata and writes a branded splash + first overview page.

Write a new page:

```
/rosetta:write-docs "document the JWT auth middleware"
```

Use a topic preset (same engine, pre-framed for a domain):

```
/rosetta:doc-auth
```

```
/rosetta:doc-db
```

```
/rosetta:doc-migrations
```

```
/rosetta:doc-patterns
```

Ask the docs for a cited answer:

```
/rosetta:query-docs "how does auth work in this repo?"
```

## Commands

| Command | Purpose |
|---|---|
| `/rosetta:init-docs [dev\|docker]` | Clone the template, start the server, offer to personalize. |
| `/rosetta:personalize-docs` | One-shot. Brand the site from detected project metadata. |
| `/rosetta:write-docs "<topic>"` | Write an MDX page. Classifies via Diátaxis, gates on `pnpm check`. |
| `/rosetta:doc-auth [context]` | Preset: authentication. |
| `/rosetta:doc-db [context]` | Preset: schema / entities / ORM. |
| `/rosetta:doc-migrations [context]` | Preset: migration workflow. |
| `/rosetta:doc-patterns [context]` | Preset: decorators / middleware / filters. |
| `/rosetta:query-docs "<question>"` | Cited answer from your docs. Auto-invokable. |

Each `doc-*` preset runs inline (interactive) by default and asks at start whether to fork to background instead.

## Release history

See [`CHANGELOG.md`](./CHANGELOG.md).

## License

MIT — see [LICENSE](./LICENSE).
