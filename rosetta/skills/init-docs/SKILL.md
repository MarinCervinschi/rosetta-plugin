---
name: init-docs
description: Scaffolds a Rosetta.md documentation site into the current project at rosetta-docs/. Use when the user wants to set up docs, initialize documentation, bootstrap rosetta-docs, add a docs folder, or says things like "init rosetta", "scaffold starlight docs", "start a docs site for this repo". Clones the latest tagged release of rosetta-template (resolved from the remote at runtime — no manual version pin), installs deps with the user's preferred package manager (pnpm or npm), starts the dev or docker server, and verifies via /health.
argument-hint: "[mode]"
allowed-tools: Bash(git clone:*) Bash(git ls-remote:*) Bash(rm -rf rosetta-docs/.git) Bash(pnpm *) Bash(npm *) Bash(docker compose *) Bash(curl *) Bash(ls *) Bash(test *) Bash(command -v *) Bash(which *)
---

# init-docs

Bootstraps a Rosetta-powered Starlight documentation site into the user's project by cloning the [`rosetta-template`](https://github.com/MarinCervinschi/rosetta-template) at its latest tagged release, installing dependencies, and bringing up a local server that exposes `/health`, `/llms.txt`, and the raw-MD endpoints.

The user asked you to set up docs. Your job is to make that happen reliably, without destroying existing work, to leave the user with a running URL they can open immediately, and then offer to personalize the scaffold with the project's identity in the same session.

## Why this skill exists

Rosetta.md is a two-repo system. The **template** is the physical baseline — an opinionated Starlight app with Diátaxis folders, a Zod frontmatter schema, custom components, and HTTP endpoints (`/health`, `/llms.txt`, `/<slug>.md`) that other Rosetta skills (`write-docs`, `query-docs`) depend on. This skill is the only way to get that baseline into a user project, and every downstream skill assumes it succeeded.

Four things matter:

1. **Scoped directory.** We scaffold into `rosetta-docs/`, not `docs/`. Many projects already have a `docs/` folder with hand-written notes; clobbering it would be unforgivable. `rosetta-docs/` is unambiguous.
2. **Tagged, not bleeding-edge.** Clone the *latest tagged release*, never `main`. A tag gives you a known file-state (schema, endpoints, component surface) — `main` could be mid-refactor the moment you run the skill. The tag is resolved dynamically from the remote at run time so consumers stay current with template releases without a plugin bump; the trade-off is that two runs months apart may scaffold different template versions, which is the cost we pay for not maintaining a version pin in every plugin release.
3. **Safety.** Never silently overwrite an existing `rosetta-docs/` folder either. Ask before destroying anything.
4. **Verifiable success.** "Success" means `curl http://localhost:4321/health` returns HTTP 200 with a JSON body identifying the service as `rosetta`. Anything short of that is a failure the user needs to see.

## Path discipline

**All Bash commands in this skill run from the project root** — the directory that *contains* `rosetta-docs/`, not `rosetta-docs/` itself. The Bash tool's working directory persists between calls, so a `cd rosetta-docs` in one step silently breaks a `test -d rosetta-docs/...` in the next one (the path becomes a sibling to the folder you're now inside).

Work around it:

- For **pnpm**, use `pnpm -C rosetta-docs <cmd>` (the `-C` flag is pnpm's shorthand for "change directory").
- For **npm**, use `npm --prefix rosetta-docs <cmd>`.
- For **docker compose** (which has no clean "run from here" flag), wrap in a subshell: `(cd rosetta-docs && docker compose <cmd>)`. The parentheses make the `cd` effect local to the subshell; the parent shell's cwd doesn't move.

Never emit a bare `cd rosetta-docs` on its own line. Every reference to the scaffolded folder stays spelled out as `rosetta-docs/...` relative to the project root.

## Workflow

Follow these steps in order. Do not skip the guard or the health-check — they're the load-bearing parts.

### Step 1 — Guard against clobbering existing rosetta-docs

```bash
test -d rosetta-docs && echo "rosetta-docs-exists" || echo "rosetta-docs-missing"
```

- If `rosetta-docs-missing`: proceed to Step 2.
- If `rosetta-docs-exists`: **stop and ask the user** whether to overwrite. Do not proceed until they explicitly say yes. Phrase the question so the consequence is clear, e.g.:

  > A `rosetta-docs/` folder already exists in this project. Continuing will delete it and replace it with a fresh rosetta-template clone. Local edits, custom pages, or unrelated content in `rosetta-docs/` will be lost. Proceed anyway? (yes/no)

  Only on an explicit *yes* do you `rm -rf rosetta-docs && ` proceed. If the user hesitates or declines, report that no changes were made and stop.

Note: an existing `docs/` folder (the legacy v0.1.0 name) is not a conflict for this skill — we scaffold alongside it into `rosetta-docs/`.

### Step 2 — Detect the package manager

Prefer pnpm; fall back to npm if pnpm isn't on PATH.

```bash
command -v pnpm >/dev/null 2>&1 && echo "pm=pnpm" || (command -v npm >/dev/null 2>&1 && echo "pm=npm" || echo "pm=none")
```

- If `pm=pnpm`: record and continue. pnpm is the recommended baseline (the template ships `pnpm-lock.yaml`).
- If `pm=npm`: record and continue, and note once in your final report that reproducibility is weaker when resolving from `package.json` without the pnpm lockfile.
- If `pm=none`: stop and tell the user:

  > This skill needs pnpm (preferred) or npm to install dependencies. Install one of them — pnpm via https://pnpm.io/installation, or ship Node.js which bundles npm — then re-run `/rosetta:init-docs`.

### Step 3 — Resolve the latest template tag and clone it

Fetch the highest `v*` tag from the template's remote — no API, no `gh`, just plain `git`:

```bash
LATEST_TAG=$(git ls-remote --tags --sort=-v:refname --refs https://github.com/MarinCervinschi/rosetta-template.git 'v*' | head -n1 | awk '{print $2}' | sed 's|refs/tags/||')
echo "resolved=${LATEST_TAG}"
```

`--sort=-v:refname` sorts tags as versions in descending order, so `head -n1` picks the newest (e.g. `v0.4.0` over `v0.3.1`). Record the tag — you'll surface it in the final report.

If `LATEST_TAG` is empty, the remote has no `v*` tags or the network is unavailable. Surface the error verbatim and stop. **Do not** fall back to `main` — the skill's contract is a tagged release.

Then shallow-clone that tag and shed the template's git history:

```bash
git clone --depth 1 --branch "${LATEST_TAG}" https://github.com/MarinCervinschi/rosetta-template.git rosetta-docs
rm -rf rosetta-docs/.git
```

Why `--depth 1 --branch "${LATEST_TAG}"`: shallow-clone a tagged release, not the mutable `main` branch. The tag was resolved moments ago from the remote, so the template contract (paths, schema, endpoints, `rosetta.config.json` shape) matches whatever that tag ships — no manual version pin in this skill.

Why `rm -rf rosetta-docs/.git`: the user's project owns `rosetta-docs/` now. Leaving the template's git history inside creates a nested repo that breaks `git status` in the parent.

If the clone fails (network, rate limit, tag disappeared between resolve and clone), surface the error verbatim and stop — don't fall back to a different branch.

### Step 4 — Install dependencies

Using the detected package manager, from the project root:

- pnpm: `pnpm -C rosetta-docs install --frozen-lockfile`
- npm:  `npm --prefix rosetta-docs ci` (uses the committed `package-lock.json` if present; otherwise falls back to `npm install` — the template doesn't ship a `package-lock.json`, so npm will regenerate one)

Concretely for npm, if `npm ci` errors about a missing lockfile, retry with `npm --prefix rosetta-docs install` and note the lockfile regeneration in your report.

### Step 5 — Ask which server mode to run

Present the two modes and let the user pick:

- **Dev mode** — hot reload, fastest iteration, dies when the shell exits. Best for an active documentation session.
- **Persistent mode** (`docker compose up -d --build`) — detached container, survives shell exits, rebuilds the image on first run (~60–90s cold). Docker uses pnpm internally regardless of the host package manager.

If the user passed a `mode` argument (`dev` or `docker`), honor it without asking. Otherwise ask the question and wait for an answer.

### Step 6 — Start the server in the background

Run the chosen command from the project root, with a backgrounded shell so you don't block:

- Dev mode with pnpm: `pnpm -C rosetta-docs dev` — use your `Bash` tool's `run_in_background: true` option.
- Dev mode with npm: `npm --prefix rosetta-docs run dev` — same, backgrounded.
- Persistent mode: `(cd rosetta-docs && docker compose up -d --build)` — `-d` already detaches; the subshell keeps your cwd at the project root so later `test -d rosetta-docs/...` calls keep working.

Capture the command's PID / container name so the user can stop it cleanly later.

### Step 7 — Poll the health endpoint

The contract says success = `GET http://localhost:4321/health` returns HTTP 200 with a JSON body whose `service` field is `"rosetta"`. Poll until that's true or a timeout hits.

```bash
# Retry up to 60 times, 1 second apart (dev mode is usually <10s,
# docker cold-build can take 60-90s — give it a full minute either way).
for i in $(seq 1 60); do
  body=$(curl -fsS http://localhost:4321/health 2>/dev/null) || { sleep 1; continue; }
  if echo "$body" | grep -q '"service":"rosetta"'; then
    echo "READY: $body"; break
  fi
  sleep 1
done
```

If the loop exits without `READY`:

- In **dev mode**: re-read the last lines of the background shell's stdout/stderr — usually a port conflict, missing Node version, or Astro build error. Report the actual error, not a generic timeout.
- In **persistent mode**: run `(cd rosetta-docs && docker compose logs --tail=50)` and surface those lines. First-run builds can legitimately exceed 60s; if logs show the build is still progressing, tell the user to wait a bit longer and re-run the health-check manually with `curl http://localhost:4321/health`.

If `/health` returns 200 but `service` is not `"rosetta"`: another service is already bound to port 4321. Tell the user, stop, and let them free the port before retrying.

### Step 8 — Offer to personalize

Before the final report, ask the user whether to personalize the docs with the project's identity now:

> Your docs are live at http://localhost:4321/. Right now they show the template's default identity (title "Rosetta.md", generic lede). I can personalize them now — detect your project's name, tagline, repo URL, and stack from `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `README.md`, preview the changes, and write them only after you confirm. Want me to go ahead? (yes / no)

- If **no**: skip to Step 9. The final report will mention `/rosetta:personalize-docs` as the follow-up.
- If **yes**: load the workflow from the sibling skill at `${CLAUDE_SKILL_DIR}/../personalize-docs/SKILL.md`, and continue execution there from its **Step 3 (Detect project metadata)** onward. Rationale: its Steps 1–2 (pre-flight + guard) are trivially satisfied — you just scaffolded `rosetta-docs/`, and the freshly-written `rosetta.config.json` has `"personalized": false`. So there's no need to re-run those checks; jump straight into detection. Treat the preview + confirmation gate in that skill's Step 4 as authoritative — if the user declines there, stop. On success, fold its Step 7 report into the combined report below.

### Step 9 — Report

On success, tell the user exactly:

1. **The URL.** `http://localhost:4321/` (and mention `http://localhost:4321/llms.txt` as the llmstxt.org index, plus `/health` as the readiness probe).
2. **How to stop it.** Dev mode: kill the backgrounded shell or press Ctrl-C in it. Persistent mode: `(cd rosetta-docs && docker compose down)`.
3. **Whether the docs got personalized** in Step 8, and — if not — a suggestion to run `/rosetta:personalize-docs` later.
4. **Next steps.** `/rosetta:write-docs "<topic>"` to author a page; `/rosetta:query-docs "<question>"` to pull context from existing docs.

Do not claim success if the health-check failed. A half-working install is worse than a clean error, because the user will waste time on the next skill wondering why it's flaking.

## Arguments

Accept one optional positional argument, `mode`:

- `/rosetta:init-docs` — no argument; ask the user at Step 5.
- `/rosetta:init-docs dev` — skip the question, use dev mode.
- `/rosetta:init-docs docker` (or `persistent`) — skip the question, use docker mode.

Treat anything else as unrecognized and fall back to asking.

The personalize offer in Step 8 always asks, regardless of argument — it's the one place the skill needs a real user decision.

## What the user should see at the end

A short report, nothing more. Template:

If the user declined personalize:

```
Rosetta docs are live.

  URL:       http://localhost:4321/
  Health:    http://localhost:4321/health  (ok, service=rosetta, <resolved tag>)
  Index:     http://localhost:4321/llms.txt
  Stop:      <command based on mode>
  Location:  rosetta-docs/
  Template:  <resolved tag>  (latest tagged release at clone time)
  Rules:     rosetta-docs/agent-docs-rules.md  (authoritative; re-read by every rosetta skill)

Identity:  template default (title "Rosetta.md"). Run /rosetta:personalize-docs
           to brand the site with your project's name, tagline, repo URL, and stack.

Next: /rosetta:write-docs "<topic>" or /rosetta:query-docs "<question>".
```

If the user accepted personalize, fold the personalize report in:

```
Rosetta docs are live and personalized.

  URL:       http://localhost:4321/
  Health:    http://localhost:4321/health  (ok, service=rosetta, <resolved tag>)
  Index:     http://localhost:4321/llms.txt
  Stop:      <command based on mode>
  Template:  <resolved tag>

Identity:
  Name:      <project-name>
  Tagline:   <tagline>
  Repo URL:  <https URL or "(none)">
  Stack:     <comma-separated summary of bullet names>

Wrote:
  rosetta-docs/src/rosetta.config.json         (metadata + personalized=true)
  rosetta-docs/src/content/docs/index.mdx      (## Stack bullets replaced)

Next: /rosetta:write-docs "<topic>" or /rosetta:query-docs "<question>".
To edit the landing page later: /rosetta:write-docs "update the landing page".
```

No marketing copy, no summary of everything you did. The user saw the tool calls; they don't need them narrated.
