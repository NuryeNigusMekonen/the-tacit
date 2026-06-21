# Org-level branch protection (apply once, to every repo)

The per-repo `scripts/setup-branch-protection.sh` works, but it must be run once
per repo by someone with `gh` and admin rights. For an organization, there is a
better way: a **GitHub organization ruleset** applies the same protection to
**all repositories automatically** - no per-repo script, no per-engineer tooling,
nothing for individual engineers to install.

This is the recommended way to make branch protection universal.

## Who does this

An **org owner / admin** sets it up **once** for the whole organization. After
that, every new repo (including ones made from this template) inherits the rules
automatically. Engineers do nothing.

## Steps (one-time, in the GitHub UI)

1. Go to the **organization** (not a repo) -> **Settings**.
2. In the left sidebar: **Repository** -> **Rulesets** -> **New ruleset** ->
   **New branch ruleset**.
3. **Name:** `tenacious-protected-branches`
4. **Enforcement status:** Active
5. **Target repositories:** All repositories (or select by property/pattern).
6. **Target branches:** add the protected branch names as patterns -
   `main`, `dev`, `staging`. (`main` is the production branch.)
7. **Rules** - enable:
   - **Require a pull request before merging** (set required approvals: 1 for
     dev/staging; for `main` use the stricter rule below).
   - **Require status checks to pass** -> add: `ci`, `security`, `coverage`.
   - **Require review from Code Owners** (so CODEOWNERS routing is enforced).
   - **Block force pushes.**
   - **Restrict deletions.**
   - **Require conversation resolution before merging.**
8. **Create** the ruleset.

Done - every repo in the org now enforces these rules with no per-repo work.

## main (production) needs stricter approval

A single org ruleset can't easily require *2* approvals only on `main`.
Two clean options:
- Create a **second ruleset** targeting only the `main` branch with
  **2 required approvals** (Tech Lead + Project Owner).
- Or let **The Tacit's bootstrapper** set the main-specific rule per
  project when it onboards the repo.

## What this does NOT do (honest limits)

- **It doesn't create the `dev`/`staging` branches** (`main` already exists) -
  it only protects branches once they exist. Branch creation is still done by
  the per-repo script, by the team, or by The Tacit's bootstrapper.
- **It can't enforce the directional flow** (e.g. reject a `dev -> main`
  merge that skips staging). GitHub rulesets gate *who/what*, not *source
  direction*. Full directional enforcement is The Tacit's policy engine.

## How the options compare

| Approach | Per-repo work? | Needs `gh`/admin per repo? | Creates branches? | Best for |
|----------|----------------|----------------------------|-------------------|----------|
| Org ruleset (this doc) | none | no | no | making protection universal |
| `setup-branch-protection.sh` | run once/repo | yes (one admin) | yes | a single repo, or branch creation |
| The Tacit bootstrapper | none (auto) | no (uses App) | yes | full per-project automation (later) |

**Recommended:** use the **org ruleset** for protection across all repos, and
let branch creation be handled by the per-repo script or The Tacit. No engineer
needs to install anything; their only local step is `make install` (secret hooks).
