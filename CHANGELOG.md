# Changelog

All notable changes to `rosetta-plugin` are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the project adheres to [Semver](https://semver.org/) with the `0.x` convention that contract-surface breaks bump the minor version (from `1.0.0` onwards they will bump the major).

The plugin tracks the [`rosetta-template`](https://github.com/MarinCervinschi/rosetta-template) minor version for contract-surface parity. Each release below declares the minimum compatible template version.

## [Unreleased]

## [0.3.0] — 2026-04-19

First release targeting the v0.3 cycle: a personalization skill for freshly-scaffolded docs sites, and the architectural scaffolding for a family of topic presets whose content playbooks land in v0.4.0. Still targets [rosetta-template `v0.2.0`](https://github.com/MarinCervinschi/rosetta-template/releases/tag/v0.2.0) — no template changes needed for this release.

### Added

- **`/rosetta:personalize-docs`** — one-shot customization of a freshly-scaffolded `rosetta-docs/`. Detects the project's name, description, and stack from standard metadata (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `README.md`, plus Dockerfile/compose/ORM/migration-tool heuristics), previews three file changes (`astro.config.mjs` title/description, `index.mdx` splash, new `explanation/overview.mdx`), and writes only after the user confirms. Guards itself: on a second invocation it detects the `<!-- rosetta:personalized ... -->` marker in `overview.mdx` and refuses — edits after the first personalization go through `/rosetta:write-docs "update the project overview"`.
- **Layer 2 scaffolding** — four topic-preset skills are now present in the plugin tree with `disable-model-invocation: true`: `/rosetta:doc-auth`, `/rosetta:doc-db`, `/rosetta:doc-migrations`, `/rosetta:doc-patterns`. Each points users at `/rosetta:write-docs "..."` for the generic-engine equivalent until their playbook content arrives. A parallel scaffold lives at `skills/write-docs/references/` with `auth.md`, `db.md`, `migrations.md`, `patterns.md` placeholders. This is architecture made visible: shipping the empty shells now means the content work in v0.4.0 is a content-fill, not a redesign.

### Versioning

- Plugin manifest bumped `0.2.0 → 0.3.0`.
- No changes to the contract with `rosetta-template`; `v0.3.x` plugin still targets `rosetta-template ≥ v0.2.0`.

## [0.2.0] — 2026-04-19

First public release. Targets [rosetta-template `v0.2.0`](https://github.com/MarinCervinschi/rosetta-template/releases/tag/v0.2.0).

### Added

- **`rosetta:init-docs`** (slash: `/rosetta:init-docs [dev|docker]`) — scaffolds a Rosetta docs site into the current project. Guards against clobbering an existing `rosetta-docs/`, detects the user's package manager (prefers `pnpm`, falls back to `npm`), clones the template at a pinned release, installs deps, starts the dev or docker server, and verifies readiness by polling `GET /health` until the response body's `service` field equals `"rosetta"`.
- **`rosetta:write-docs <topic>`** — documents a feature, concept, or code area as an MDX page. Re-reads `rosetta-docs/agent-docs-rules.md` and `rosetta-docs/src/content.config.ts` fresh on every invocation, classifies the topic via the Diátaxis §4 decision tree (tutorials / how-to / reference / explanation), drafts valid frontmatter against the current Zod schema, reaches for the rosetta custom components only where §3 says they earn their place, and gates on `pnpm -C rosetta-docs check` (or `npm --prefix rosetta-docs run check`) before reporting success. Cites the rule sections (`§N`) that shaped the page in the final report for auditability.
- **`rosetta:query-docs <question>`** — retrieves context from an existing Rosetta docs site and synthesizes a cited answer. Probes `GET /health` first to confirm the server on `:4321` is actually a rosetta site (not a collision with some other service), then fetches `/llms.txt`, ranks the top 1–3 pages, pulls their raw-Markdown twins via the URL mapping rule (`/<section>/<slug>/` → `/<section>/<slug>.md`), and cites each claim by HTML URL. Degrades to reading `rosetta-docs/src/content/docs/**` directly when the server is unreachable, and explicitly declines to answer (suggesting `/rosetta:write-docs` instead) when top matches don't cover the question. `disable-model-invocation` is **off**, so Claude can auto-trigger the skill when it needs doc context for an unrelated task.
- **Plugin manifest** (`.claude-plugin/plugin.json`) with name `rosetta`, version `0.2.0`, MIT license, and a triggery description for skill discovery.

### Versioning discipline

- **Path discipline built into the skills.** All Bash commands run from the project root, using `pnpm -C rosetta-docs <cmd>` / `npm --prefix rosetta-docs <cmd>` / `(cd rosetta-docs && docker compose <cmd>)` — never a bare `cd rosetta-docs`, because the Bash tool's working directory persists across tool calls and a loose `cd` silently breaks subsequent `test -d rosetta-docs/...` guards. Each skill opens with an explicit "Path discipline" section explaining the why so the agent extrapolates rather than mimics.

### Notes

- v0.1.0 was committed during development (commits `a6eb491` and `2904010`) but never tagged or published; all features from that pre-release era are folded into v0.2.0 above. The contract surface moved from `docs/` to `rosetta-docs/` between internal v0.1 and v0.2 — consumers who cloned `main` before the v0.2.0 tag and want to upgrade should re-run `/rosetta:init-docs` on a fresh workdir, or `mv docs rosetta-docs` their existing install.

[Unreleased]: https://github.com/MarinCervinschi/rosetta-plugin/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/MarinCervinschi/rosetta-plugin/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/MarinCervinschi/rosetta-plugin/releases/tag/v0.2.0
