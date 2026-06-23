# AGENTS.md

Conventions for engineers and AI assistants working in this repository
. Read this before making changes.

## How work flows

Branches map to environments and promote one direction only:
`feature/* -> dev -> staging -> main` (main is the production branch). Code never skips a stage or flows
backward (except an explicit hotfix reconciliation). Every merge into a
protected branch goes through a pull request.

## Before you open a PR

1. Does the change match the requirement? (re-read the ticket/acceptance criteria)
2. Does it introduce risk outside its stated scope? (auth, shared utils,
   migrations, billing, PII, prompts get stricter scrutiny)
3. Is it maintainable by someone who has never seen it?
4. Do the tests prove what they claim? (fail when behaviour breaks)

## Hard rules

- **No secrets in the repo.** No credentials, tokens, or keys in source, config,
  diffs, or logs. Use env vars / a secrets store. Example config lists variable
  names with placeholder values only. The pre-commit hook + CI scan enforce this.
- **Every PR has a real description** - what changed and why, not a restatement
  of the diff (use the PR template).
- **Required checks must pass** before merge - build, lint, test, secret-scan.
- **Keep PRs small and focused** - one concern per PR; large PRs are hard to
  review safely.
- **Tests travel with code** - new behaviour carries proportionate tests.

## Commands

The `Makefile` is the single command surface: `make install`, `make lint`,
`make test`, `make build`. CI runs the same targets.

## First-time setup

Run `bash scripts/install-hooks.sh` once after cloning to activate the
secret-scanning pre-commit hook (or it runs via `make install`).
