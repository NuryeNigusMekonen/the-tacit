# Branch protection setup (Tenacious Standard §2)

GitHub branch-protection rules cannot be shipped as files - they are repo
settings. After creating a repo from this template, set these in
**Settings -> Branches** for each protected branch (`main`, `dev`, `staging`,
or your project's equivalents - `main` is the production branch). The Tacit
bootstrapper can apply these per project automatically once it has write access.

## Branch flow (one direction only)

`feature/* -> dev -> staging -> main` (main is the production branch). No skipped
stages, no backward flow (except an explicit hotfix reconciliation).

## Directional rule - which branch accepts merges FROM which

This is the heart of the flow. Each protected branch should only ever receive
code from the stage directly below it. **`main` is production.**

| Target branch | Accepts merges FROM | Never from |
|---------------|---------------------|-----------|
| `feature/*`   | cut from `dev`      | -          |
| `dev`         | `feature/*`         | staging, main |
| `staging`     | `dev` only          | feature/*, main |
| `main` (prod) | `staging` only      | feature/*, dev (no skipping) |

- **No skipping:** a feature branch may not merge straight into staging or
  main; dev may not merge into main.
- **No backward flow:** main never merges back into staging/dev, except a
  deliberate **hotfix reconciliation** (a fix made on main is merged back
  down so it isn't lost).
- **Promotion is by merge, not cherry-pick** - what runs in production (main) is
  exactly what was validated in staging.

### How the direction is enforced (and its limits)

GitHub branch protection by itself enforces *who can merge* and *that checks
pass*, but does **not** natively block a "wrong-source" merge by branch name.
This template closes that gap with a CI check:

- **`branch-flow` workflow** (`.github/workflows/branch-flow.yml`) runs on every
  PR and **fails** if the merge skips a stage - e.g. `dev -> main` or
  `feature/* -> main`. Allowed: `feature|bugfix|hotfix -> dev`, `dev -> staging`,
  `staging -> main`, and `hotfix/* -> ` any stage (the sanctioned exception).
- The `setup-branch-protection.sh` script makes **`branch-flow` a required
  status check**, so a PR that fails the direction check **cannot merge**.

So the directional rule (`feature -> dev -> staging -> main`, no skipping) **is
enforced** at the template level today.

**Honest limit:** like all CI checks, `branch-flow` can be overridden by a
repo admin who bypasses checks. It reliably stops the common *accidental* skip,
but truly un-bypassable directional enforcement (and the role-exact joint
approval) is **The Tacit's policy engine** - the template is the strong
groundwork; the central system is the final authority.

## Per branch, require:

**dev** (receives feature branches)
- Require a pull request before merging.
- Require status checks to pass: `ci`, `security` (secret-scan + SAST), `coverage`.
- No direct pushes.

**staging** (receives from dev only)
- All of the above.
- Require the Tech Lead's approval (review from CODEOWNERS).

**main** (production - receives from staging only)
- All of the above.
- Require joint approval - Tech Lead **and** Project Owner (2 approvals).
- No direct pushes; promotion by merge, not cherry-pick.

## Recommended for all protected branches
- Require branches to be up to date before merging.
- Require conversation resolution before merging.
- Require review from Code Owners (so CODEOWNERS routing is enforced).
- Restrict who can push (no direct pushes; PRs only).

> These settings make the CI + security + coverage checks the real merge gate,
> and ensure sensitive changes get a human reviewer - the rules The Tacit reads
> and governs centrally.
