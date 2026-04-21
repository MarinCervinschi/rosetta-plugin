# Playbook — `metadata`

Loaded by `/rosetta:personalize-docs` Step 3 when it dispatches `rosetta-code-researcher` to detect project identity (name, tagline, repo URL, stack) from standard manifests. Unlike the other playbooks this one drives a **detection task**, not a documentation task — the caller converts your brief into JSON + an MDX stack list, it doesn't draft a page from it.

## What to detect (in order)

1. **Project name** — exactly one value.
2. **Tagline / short description** — one sentence suitable for a subtitle.
3. **Repo URL** — canonical HTTPS URL, or absent.
4. **Language / runtime** — one primary language; secondary languages only if they're substantial.
5. **Framework** — one entry per distinct framework layer (web framework, UI framework, etc.).
6. **Database / ORM** — one entry if detectable from config files.
7. **Deployment hints** — one entry per deployment target detected.

Everything else (build tools, test runners, linters) is **out of scope**. Don't clutter the brief.

## Where to look — file priority

Read these in order. Stop at the first match for each field. Do not merge across files unless the primary source lacks a value for a specific field.

### Project name

- `package.json` → `name`
- `pyproject.toml` → `[project].name`
- `go.mod` → `module` (use the last path segment)
- `Cargo.toml` → `[package].name`
- Fallback: the project root's directory basename

### Tagline / description

- `package.json` → `description`
- `pyproject.toml` → `[project].description`
- First paragraph of `README.md` (skip a leading `# <title>` heading if it's just the project name repeated)

Compress to a one-liner.

### Repo URL

- `package.json` → `repository.url` (strip `git+` prefix and trailing `.git`)
- `pyproject.toml` → `[project.urls]` (prefer a `Repository` or `Source` entry over `Homepage`)
- `Cargo.toml` → `[package].repository`
- `.git/config` remote origin URL — **only if** it resolves to an HTTPS GitHub / GitLab / Bitbucket URL (skip git@ or internal hosts)

### Language / runtime

Infer from file presence:

| Signal | Language label |
|---|---|
| `package.json` | Node.js (inspect `engines`, `type: module`, `tsconfig.json` for a TS label) |
| `pyproject.toml` or `requirements.txt` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `Gemfile` | Ruby |
| `composer.json` | PHP |
| `pom.xml` or `build.gradle` | Java / JVM |
| `*.csproj` or `*.sln` | .NET |

### Framework

From dependencies (or imports if the manifest has no deps list):

- Node: `next` / `react` / `vue` / `svelte` / `astro` / `@nestjs/*` / `express` / `fastify`
- Python: `flask` / `django` / `fastapi` / `starlette`
- Go: `gin-gonic/gin` / `labstack/echo` / `gofiber/fiber`
- Ruby: `rails` (in Gemfile)
- PHP: `laravel` / `symfony` (in composer.json)
- JVM: `spring-boot` (in pom.xml / build.gradle)
- Rust: `rocket` / `actix-web` / `axum`

### Database / ORM

- `schema.sql` / `*.prisma` / `alembic.ini` / `knexfile.*` / `drizzle.config.*`
- Presence of a `models/` or `entities/` directory with ORM-style class definitions

### Deployment hints

- `Dockerfile`, `docker-compose.yml`, `compose.yml` → Docker
- `fly.toml` → Fly.io
- `vercel.json` → Vercel
- `netlify.toml` → Netlify
- `railway.json` → Railway
- `.github/workflows/*` that target a deployment service (deploy job) — note the target

## Output — map to the 5-section brief

Your standard 5-section brief, applied to detection:

- **Files explored** — every manifest/README line you actually Read, with citations.
- **Key symbols** — each detected value as its own bullet, citing the source file and line:
  - `- Project name: "rosetta-md" (package.json:3) — from package.json name field`
  - `- Framework: Next.js (package.json:28) — dependency "next": "^14.2.0"`
- **Relationships / flow** — `- (none)` unless the project layout reveals something unusual (monorepo root vs workspace package, frontend + backend split, etc.).
- **Edge cases & ambiguities** — ambiguities the caller needs to resolve:
  - conflicting names across manifests (npm name vs Cargo name)
  - tagline absent or unusable (README opens with badges/TOC)
  - two frameworks at the same layer (`express` AND `fastify` — which is primary?)
  - language mix above "minor tooling" threshold
- **Citations for drafting** — restate every value with its citation, flat, so the caller can splice directly into the preview:
  - `- Name: "rosetta-md" (package.json:3)`
  - `- Tagline: "An AI-native documentation baseline" (README.md:3)`
  - `- Repo URL: https://github.com/MarinCervinschi/rosetta-md (package.json:14)`
  - `- Language: TypeScript (tsconfig.json:1, package.json:4 "type": "module")`
  - ...

## Do

- Only cite what you Read. If a field is absent, **omit it entirely** — do not emit `- Tagline: (none) (n/a)`.
- Surface conflicts rather than resolving them silently. The user picks.
- Stay within the file list above. A repo-wide Grep for framework imports is out of budget for this task.

## Don't

- Don't read the project's source code. Metadata detection is manifest-only. If you can't identify the framework from dependencies, it goes into *Edge cases*, not a speculative symbol.
- Don't read `.env`, `.env.local`, or any file under `.secrets/` / `credentials/`. Those are never metadata sources.
- Don't invent a tagline if the README doesn't provide one. Leave it for the caller to ask the user.
- Don't enumerate dev-dependencies, formatters, linters, or test runners. They're noise in the stack list.
