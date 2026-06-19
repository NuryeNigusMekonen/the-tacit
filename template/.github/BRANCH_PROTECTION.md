# Branch protection setup (Tenacious Standard §2)

GitHub branch-protection rules cannot be shipped as files - they are repo
settings. After creating a repo from this template, set these in
**Settings -> Branches** for each protected branch (`dev`, `staging`,
`production`, or your project's equivalents). The Tacit bootstrapper can apply
these per project automatically once it has write access.

## Branch flow (one direction only)

`feature/* -> dev -> staging -> production`. No skipped stages, no backward flow
(except an explicit hotfix reconciliation).

## Per branch, require:

**dev** (receives feature branches)
- Require a pull request before merging.
- Require status checks to pass: `ci`, `security` (secret-scan + SAST), `coverage`.
- No direct pushes.

**staging** (receives from dev only)
- All of the above.
- Require the Tech Lead's approval (review from CODEOWNERS).

**production** (receives from staging only)
- All of the above.
- Require joint approval - Tech Lead **and** Project Owner.
- No direct pushes; promotion by merge, not cherry-pick.

## Recommended for all protected branches
- Require branches to be up to date before merging.
- Require conversation resolution before merging.
- Require review from Code Owners (so CODEOWNERS routing is enforced).
- Restrict who can push (no direct pushes; PRs only).

> These settings make the CI + security + coverage checks the real merge gate,
> and ensure sensitive changes get a human reviewer - the rules The Tacit reads
> and governs centrally.
