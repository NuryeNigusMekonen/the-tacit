# Tenacious Project Template

A GitHub template repository that gives every new project a secure-by-default,
tested-by-default, governed-by-default starting point. Click **"Use this
template"** on GitHub to create a new repository from it.

Every file in this template enforces a development standard or prevents a
common, real problem. It is multi-language: it auto-detects Python, JavaScript
or TypeScript, Go, Rust, and Java, and runs the right tools for whatever your
project uses.

## What you get

| Area | What it does |
|------|--------------|
| **Secret scanning** | Blocks credentials (passwords, API keys, tokens) from being committed or pushed — at commit time, push time, and in CI. |
| **Build, lint, and test checks** | Run automatically on every pull request, so broken or unformatted code is caught before it merges. |
| **Security analysis** | Scans your code for security vulnerabilities (Semgrep on pull requests; deeper CodeQL analysis on the main branch and weekly). |
| **Dependency scanning** | Flags outdated or vulnerable dependencies and opens pull requests to update them automatically. |
| **Test coverage** | Enforces a minimum test coverage and warns when code changes ship without tests. |
| **Reviewer assignment (CODEOWNERS)** | Automatically requests the right human reviewer when sensitive files change. |
| **Pull request and issue templates** | Make every pull request explain what changed and why, and keep issue reports consistent. |
| **Code-quality checks** | Flag oversized pull requests, dead code, and duplicated code to keep changes reviewable. |
| **Release automation** | Works out the next version, generates a changelog, and tags a release from your commit messages. |
| **Branch-flow enforcement** | Keeps code moving in one direction — feature branch to dev to staging to main — and blocks merges that skip a stage. |
| **Standard project files** | A `Makefile` (one command surface for build/lint/test), `.gitignore`, `.env.example`, and contributor docs. |

## How the branches work

Code flows in one direction, with no skipping:

```
feature/*  ->  dev  ->  staging  ->  main
```

`main` is the production branch. Each protected branch requires a pull request,
passing checks, and reviewer approval before code can merge (main requires two
approvals).

## The command surface (Makefile)

This template uses a `Makefile` as the single set of commands, so you and the
CI pipeline run exactly the same thing:

```
make install     install dependencies and activate the local secret-scanning hooks
make lint        check code style and quality
make format      auto-format the code
make test        run the test suite
make build       build the project
make coverage    run tests with a coverage check
make secret-scan scan the repository for secrets
```

These auto-detect your language. If your project uses a language or layout the
defaults don't cover, edit the matching recipe in the `Makefile` — that is the
intended place to adapt the template to your project.

## Continuous integration is optional for short projects

The heavier CI checks (build, lint, test, coverage, code quality, and deep
security analysis) are **off by default**. Short projects can rely on the
`Makefile` and the local hooks alone. To turn the full pipeline on for a
longer-running project, add a repository variable:

1. Go to **Settings → Secrets and variables → Actions → Variables**.
2. Add a variable named `CI_ENABLED` with the value `true`.

Secret scanning and branch-flow enforcement always run, on every project,
because they protect any codebase regardless of size.

## First steps in a new repository

1. Create the repository from this template ("Use this template" on GitHub).
2. Run `make install` once — it installs dependencies and turns on the local
   secret-scanning hooks.
3. Fill in the `Makefile` commands for your stack if the defaults don't fit.
4. Open `CODEOWNERS` and replace the example reviewer names with your real
   team members or GitHub teams.
5. Set up branch protection so the checks become required before merging. You
   can apply it across all repositories at once with an organization rule (see
   `.github/ORG_RULESET.md`), or per repository with the setup script:
   `bash scripts/setup-branch-protection.sh OWNER/REPO`.
6. When the project is ready, turn the security and quality checks from advisory
   to blocking so they prevent merges instead of only warning.

## Notes

- Security and quality checks start in **advisory mode** — they report problems
  but don't block merges — so you can adopt them gradually and tune out false
  positives, then make them blocking when you're ready.
- Branch protection is a GitHub setting, not a file, so it can't ship inside the
  template. Use the organization rule or the setup script to apply it.
- The local secret-scanning hooks need to be activated once per machine with
  `make install`. The CI secret scan always runs regardless, as a safety net.
