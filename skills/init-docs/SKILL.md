---
name: init-docs
description: Scaffolds a Rosetta.md documentation site into the current project. Use when the user wants to set up docs, initialize documentation, bootstrap /docs, add a docs folder, or says things like "init rosetta", "scaffold starlight docs", "start a docs site for this repo". Clones rosetta-template, installs pnpm deps, starts the dev or docker server, and verifies /llms.txt responds.
argument-hint: "[mode]"
allowed-tools: Bash(git clone:*) Bash(rm -rf docs/.git) Bash(cd docs && pnpm *) Bash(cd docs && docker compose *) Bash(curl *) Bash(ls *) Bash(test *)
---

# init-docs

Bootstraps a Rosetta-powered Starlight documentation site into the user's project by cloning the [`rosetta-template`](https://github.com/marincervinschi/rosetta-template) at a pinned release, installing dependencies, and bringing up a local server that exposes `/llms.txt` and the raw-MD endpoints.

The user asked you to set up docs. Your job is to make that happen reliably, without destroying existing work, and to leave the user with a running URL they can open immediately.

## Why this skill exists

Rosetta.md is a two-repo system. The **template** is the physical baseline — an opinionated Starlight app with Diátaxis folders, a Zod frontmatter schema, custom components, and HTTP endpoints (`/llms.txt`, `/<slug>.md`) that other Rosetta skills (`write-docs`, `query-docs`) depend on. This skill is the only way to get that baseline into a user project, and every downstream skill assumes it succeeded.

Three things matter:

1. **Reproducibility.** Clone a *tagged release*, never `main`. Users must be able to reinstall the same plugin version against the same template version six months from now.
2. **Safety.** Never silently overwrite an existing `docs/` folder. The user may already have docs there; destroying them would be worse than any error.
3. **Verifiable success.** "Success" means `curl http://localhost:4321/llms.txt` returns `200`. Anything short of that is a failure the user needs to see.

## Workflow

Follow these steps in order. Do not skip the guard or the health-check — they're the load-bearing parts.

### Step 1 — Guard against clobbering existing docs

Run:

```bash
test -d docs && echo "docs-exists" || echo "docs-missing"
```

- If `docs-missing`: proceed to Step 2.
- If `docs-exists`: **stop and ask the user** whether to overwrite. Do not proceed until they explicitly say yes. Phrase the question so the consequence is clear, e.g.:

  > A `docs/` folder already exists in this project. Continuing will delete it and replace it with a fresh rosetta-template clone. Local edits, custom pages, or unrelated content in `docs/` will be lost. Proceed anyway? (yes/no)

  Only on an explicit *yes* do you `rm -rf docs && ` proceed. If the user hesitates or declines, report that no changes were made and stop.

### Step 2 — Clone the pinned template release

```bash
git clone --depth 1 --branch v0.1.0 https://github.com/marincervinschi/rosetta-template.git docs
rm -rf docs/.git
```

Why `--depth 1 --branch v0.1.0`: shallow-clone a tagged release, not the mutable `main` branch. This guarantees the same template contract (paths, schema, endpoints) every time.

Why `rm -rf docs/.git`: the user's project owns `docs/` now. Leaving the template's git history inside creates a nested repo that breaks `git status` in the parent.

If the clone fails (network, rate limit, tag missing), surface the error verbatim and stop — don't fall back to a different branch.

### Step 3 — Install dependencies

```bash
cd docs && pnpm install --frozen-lockfile
```

`pnpm` is mandatory — the template pins its lockfile to pnpm and the user has a project-wide preference for it. Do not substitute `npm` or `yarn`; both will produce a different dependency graph and can break the Starlight build.

`--frozen-lockfile` makes the install deterministic and fails fast if `pnpm-lock.yaml` is out of sync. That's the behavior we want.

If the user doesn't have pnpm, stop and tell them:

> This skill requires pnpm (the template's package manager of record). Install it with `npm install -g pnpm` or follow https://pnpm.io/installation, then run `/rosetta:init-docs` again.

### Step 4 — Ask which server mode to run

Present the two modes and let the user pick:

- **Dev mode** (`pnpm dev`) — hot reload, fastest iteration, dies when the shell exits. Best for an active documentation session.
- **Persistent mode** (`docker compose up -d --build`) — detached container, survives shell exits, rebuilds the image on first run (~60–90s cold). Best when the user wants the docs server always-on.

If the user passed a `mode` argument (`dev` or `docker`), honor it without asking. Otherwise ask the question and wait for an answer.

### Step 5 — Start the server in the background

Run the chosen command with a backgrounded shell so you don't block:

- Dev mode: `cd docs && pnpm dev` — use your `Bash` tool's `run_in_background: true` option.
- Persistent mode: `cd docs && docker compose up -d --build` — `-d` already detaches; no background flag needed.

Capture the command's PID / container name so the user can stop it cleanly later.

### Step 6 — Poll the health endpoint

The contract says success = `GET http://localhost:4321/llms.txt` returns HTTP 200 with content type `text/plain`. Poll until that's true or a timeout hits.

```bash
# Retry up to 60 times, 1 second apart (dev mode is usually <10s,
# docker cold-build can take 60-90s — give it a full minute either way).
for i in $(seq 1 60); do
  if curl -fsS -o /dev/null -w "%{http_code}" http://localhost:4321/llms.txt 2>/dev/null | grep -q "^200$"; then
    echo "READY"; break
  fi
  sleep 1
done
```

If the loop exits without `READY`:

- In **dev mode**: re-read the last lines of the background shell's stdout/stderr — usually a port conflict, missing Node version, or Astro build error. Report the actual error, not a generic timeout.
- In **persistent mode**: run `cd docs && docker compose logs --tail=50` and surface those lines. First-run builds can legitimately exceed 60s; if logs show the build is still progressing, tell the user to wait a bit longer and re-run the health-check manually with `curl http://localhost:4321/llms.txt`.

### Step 7 — Report

On success, tell the user exactly three things:

1. **The URL.** `http://localhost:4321/` (and mention `http://localhost:4321/llms.txt` as the llmstxt.org index).
2. **How to stop it.** Dev mode: kill the backgrounded shell or press Ctrl-C in it. Persistent mode: `cd docs && docker compose down`.
3. **Next steps.** `/rosetta:write-docs "<topic>"` to author a page (when B3 ships); `/rosetta:query-docs "<question>"` to pull context from existing docs (when B4 ships). Until those are implemented, the user can author MDX directly under `docs/src/content/docs/{tutorials,how-to,reference,explanation}/` following the rules in `docs/agent-docs-rules.md`.

Do not claim success if the health-check failed. A half-working install is worse than a clean error, because the user will waste time on the next skill wondering why it's flaking.

## Arguments

Accept one optional positional argument, `mode`:

- `/rosetta:init-docs` — no argument; ask the user at Step 4.
- `/rosetta:init-docs dev` — skip the question, use dev mode.
- `/rosetta:init-docs docker` (or `persistent`) — skip the question, use docker mode.

Treat anything else as unrecognized and fall back to asking.

## What the user should see at the end

A short report, nothing more. Template:

```
Rosetta docs are live.

  URL:      http://localhost:4321/
  Index:    http://localhost:4321/llms.txt
  Stop:     <command based on mode>
  Rules:    docs/agent-docs-rules.md  (authoritative; re-read by every rosetta skill)

Next: /rosetta:write-docs "<topic>" (Phase B3, coming) or author MDX directly under docs/src/content/docs/{tutorials,how-to,reference,explanation}/.
```

No marketing copy, no summary of everything you did. The user saw the tool calls; they don't need them narrated.
