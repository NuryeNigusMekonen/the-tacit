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
| SAST (`.github/workflows/security.yml`) | Static security analysis (Bandit / Semgrep) | Code-security depth |
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
| CodeQL (`.github/workflows/codeql.yml`) | Deep, GitHub-native security analysis (data-flow) | §3 - beyond pattern-based SAST |
| Quality gates (`quality.yml`) | PR-size limit + complexity/dead-code/duplication | §1 - keeps changes reviewable |
| Release automation (`release.yml`) | Auto-version, changelog, tag from Conventional Commits | §7 - semantic versioning |
| Conventional commits (`commitlint.yml`) | Enforces commit/PR-title format | §2 - clean, traceable history |
| Branch protection script (`scripts/setup-branch-protection.sh`) | Applies protection via the GitHub API (settings can't be templated) | §2 - makes checks the real gate |

> Security/quality checks start advisory (won't block on false positives); flip
> them to blocking once tuned for your project. AI-agent readiness (agent skills,
> enriched AGENTS.md) is a planned, optional add-on for agent-using projects.

## First steps in a new repo

1. Create the repo from this template ("Use this template" on GitHub).
2. `bash scripts/install-hooks.sh` - activates the secret-scanning pre-commit hook.
3. Fill in the `Makefile` targets for your stack (Python / JS).
4. Replace `@ORG/...` placeholders in `CODEOWNERS` with real teams.
5. Set up the branch flow. **Recommended for an org:** set protection once for all repos via an org ruleset - see `.github/ORG_RULESET.md` (no per-repo work, no `gh` per engineer). **Per repo:** `bash scripts/setup-branch-protection.sh <owner/repo>` (needs `gh` with admin rights) creates `dev`/`staging`/`production` and protects each, or set it manually per `.github/BRANCH_PROTECTION.md`.
6. Tune the security/quality gates and flip them from advisory to blocking when ready.

## How this relates to The Tacit

This template is the **local enforcement** layer - it runs inside each repo.
The central **Tacit** system (built separately) reads these results, makes the
readiness/release decisions, keeps the audit trail and release records, and
learns across projects. Template = local muscle; The Tacit = central brain.
