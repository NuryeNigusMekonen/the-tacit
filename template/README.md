# Tenacious Project Template

A **GitHub template repository** that gives every new Tenacious project a
secure-by-default, tested-by-default, governed-by-default starting point.
Click **"Use this template"** on GitHub to create a new repo from it.

Every file here exists because it enforces a Tenacious standard or prevents a
real problem - nothing decorative.

## What you get (the approved core)

| Item | What it does | Standard / problem it fixes |
|------|--------------|------------------------------|
| Secret scanning (`scripts/` + `.githooks/` + CI) | Blocks credentials in commits/PRs | §3 - no credentials in the repo |
| CI checks (`.github/workflows/ci.yml`) | build / lint / test on every PR | §4 - the required merge checks |
| Dependency scanning (`.github/dependabot.yml`) | Flags & auto-updates vulnerable deps | Security upkeep |
| SAST (`.github/workflows/security.yml` + `codeql.yml`) | Static security analysis - Semgrep on PRs, CodeQL deeper on main + weekly | Code-security depth |
| Coverage gate + test check (`coverage.yml`) | Enforces tests, flags untested changes | Makes testing real, not optional |
| `CODEOWNERS` | Auto-assigns human reviewers on sensitive files | Fixes "no human review" |
| PR + issue templates | Forces "what changed and why" | Fixes "no description" |
| `AGENTS.md`, `CONTRIBUTING.md` | The Tenacious conventions & workflow | §1, §2 |
| `SECURITY.md` | Security policy (secrets, reporting) | §3 |
| `.github/BRANCH_PROTECTION.md` | What branch-protection rules to set (settings can't be a file) | §2 |
| `.gitleaks.toml` + pre-push hook | Fuller secret coverage + last gate before push | §3 |
| `Makefile`, `.gitignore`, `.env.example` | Standard command surface + no-secrets | §3, §4 |

## Production-grade additions

| Item | What it does | Standard / problem it fixes |
|------|--------------|------------------------------|
| CodeQL (`.github/workflows/codeql.yml`) | Deep, GitHub-native data-flow security analysis - runs on `main` + weekly (kept off PRs for speed; Semgrep covers per-PR SAST) | §3 - beyond pattern-based SAST |
| Quality gates (`quality.yml`) | PR-size limit + complexity/dead-code/duplication | §1 - keeps changes reviewable |
| Release automation (`release.yml`) | Auto-version, changelog, tag from Conventional Commits | §7 - semantic versioning |
| Conventional commits (`commitlint.yml`) | Enforces commit/PR-title format | §2 - clean, traceable history |
| Branch protection script (`scripts/setup-branch-protection.sh`) | Applies protection via the GitHub API (settings can't be templated) | §2 - makes checks the real gate |

> Security/quality checks start advisory (won't block on false positives); flip
> them to blocking once tuned for your project. AI-agent readiness (agent skills,
> enriched AGENTS.md) is a planned, optional add-on for agent-using projects.

## Recommended tooling (per category)

The default tool for each check, with the main alternative and where it runs
best. These are recommendations - the workflows call `make` targets, so a
project can swap any tool by editing its Makefile.

| Category | Recommended default | Main alternative | Where it runs best |
|----------|---------------------|------------------|--------------------|
| Secret scanning | GitHub Secret Protection, or Gitleaks (OSS) | TruffleHog for verified / deep nightly scans | GitHub-native; standard hosted runner for Gitleaks |
| SAST | Semgrep | CodeQL for deeper GitHub-native analysis | Standard hosted runner; larger runner for heavy CodeQL |
| Dependency scanning | Dependabot | Renovate (monorepos), Snyk (commercial reachability) | GitHub-native, standard hosted runner |
| Python lint / format | Ruff | Pylint (deep design checks), Black (formatter) | Standard hosted runner + local hook |
| JS/TS lint / format | Biome | ESLint + Prettier when plugin coverage matters | Standard hosted runner + local hook |
| Go lint / format | golangci-lint + gofmt | native `go vet` stack | Standard hosted runner |
| Rust lint / format | Clippy + rustfmt | (already the native standard) | Standard hosted runner |
| Testing / coverage | Native per language (coverage.py, Vitest, go test, cargo-llvm-cov) | Codecov for centralized reporting | Standard hosted runner; larger for heavy integration suites |
| Code quality | jscpd (duplication) | SonarQube (platform), Vulture/Radon (Python extras) | Standard hosted runner; dedicated service for SonarQube |
| Commit / PR conventions | commitlint + semantic PR-title check | PR-title action alone (squash-merge teams) | Local hook + GitHub Actions |
| Release automation | release-please | semantic-release (npm), Changesets (JS monorepos) | GitHub Actions, standard hosted runner |

**Runner note:** a standard GitHub-hosted runner (`ubuntu-latest`) handles
nearly everything. Only heavy CodeQL jobs or a SonarQube service warrant a larger
runner or dedicated host; self-hosted / EC2 runners are worth it only for very
large repos or to control CI minute costs.

**This template applies the recommended defaults directly:** Gitleaks runs as the
primary CI secret scan (with the zero-dep scanner as an always-on hard-gate
fallback, so protection holds even without Gitleaks), and `make lint`/`make
format` use Biome for JS/TS (`biome.json` ships sane defaults; falls back to the
project's `npm run lint` if defined). Ruff, Semgrep, CodeQL, Dependabot, jscpd,
vulture, commitlint, and release-please are all wired in and running.

## CI is opt-in (Standard §4)

The Standard says CI/CD is for engagements expected to **exceed ~3 months**;
shorter ones may run on the Makefile alone. So the heavy CI checks
(`ci`, `coverage`, `quality`, `codeql`, `sast`) are **off by default** and only
run when the repo sets a variable:

```
Settings -> Secrets and variables -> Actions -> Variables ->
  New variable:  name = CI_ENABLED   value = true
```

- **Short project (default):** leave it unset - those checks are skipped; you
  rely on the Makefile + local hooks.
- **Long project:** set `CI_ENABLED=true` - the full pipeline runs.

**Always on regardless** (cheap and critical for any project): **secret scanning**
and **branch-flow** (merge-direction). The branch-protection script requires only
those when CI is off, and adds `ci`/`coverage` as required when CI is enabled -
so a short project's PRs are never blocked waiting on skipped checks.

## First steps in a new repo

1. Create the repo from this template ("Use this template" on GitHub).
2. `bash scripts/install-hooks.sh` - activates the secret-scanning pre-commit hook.
3. Fill in the `Makefile` targets for your stack (Python / JS).
4. Replace `@ORG/...` placeholders in `CODEOWNERS` with real teams.
5. Set up the branch flow. **Recommended for an org:** set protection once for all repos via an org ruleset - see `.github/ORG_RULESET.md` (no per-repo work, no `gh` per engineer). **Per repo:** `bash scripts/setup-branch-protection.sh <owner/repo>` (needs `gh` with admin rights) creates `dev`/`staging` and protects `main`/`dev`/`staging` (main is the production branch), or set it manually per `.github/BRANCH_PROTECTION.md`.
6. Tune the security/quality gates and flip them from advisory to blocking when ready.

## How this relates to The Tacit

This template is the **local enforcement** layer - it runs inside each repo.
The central **Tacit** system (built separately) reads these results, makes the
readiness/release decisions, keeps the audit trail and release records, and
learns across projects. Template = local muscle; The Tacit = central brain.
