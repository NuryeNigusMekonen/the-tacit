# Contributing

How work moves through this project (Tenacious Development Standard).

## Branch flow (§2)

`feature/* -> dev -> staging -> main` (main is the production branch). One direction only; no skipped
stages; no backward flow except an explicit hotfix reconciliation. Cut feature
branches from `dev`; merge back into `dev` via a pull request.

## Opening a pull request

1. Run locally first: `make lint`, `make test`, `make build`.
2. Run your own self-review (the four questions in `AGENTS.md`).
3. Open the PR using the template - a real "what changed and why" is required.
4. Automated review + required checks (build / test / lint / secret-scan) are
   the merge gate. Address every review comment - fix it or reply why it
   doesn't apply.
5. Keep PRs small and focused; sensitive areas get a human reviewer (CODEOWNERS).

## Definition of done

- Acceptance criteria met
- Tests added and passing; checks green
- No secrets committed; description complete
- Reviewed (automated + human where required) and merged to the right branch

## Releases (§7)

Staging is the release gate: promotion to production needs the Tech Lead and
Project Owner's joint approval and a named rollback plan. Production is
execution only.

## First-time setup

```
bash scripts/install-hooks.sh   # activate the secret-scanning pre-commit hook
make install
```
