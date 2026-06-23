# Project Template - User Guide

A GitHub template repository that gives every new project a secure-by-default,
tested-by-default, governed-by-default starting point. Click **"Use this
template"** on GitHub to create a new repository from it.

This single guide is everything you need to use the template end to end:
what it does, how to set it up, what to run, and the standard formats to follow.

It is multi-language - it auto-detects Python, JavaScript/TypeScript, Go, Rust,
and Java, and runs the right tools for whatever your project uses.

---

## 1. What you get

| Area | What it does |
|------|--------------|
| **Secret scanning** | Blocks credentials (passwords, API keys, tokens) from being committed or pushed - at commit time, push time, and in CI. |
| **Build, lint, and test checks** | Run automatically on every pull request, so broken or unformatted code is caught before it merges. |
| **Security analysis** | Scans code for security vulnerabilities (Semgrep on pull requests; deeper CodeQL analysis on the main branch and weekly). |
| **Dependency scanning** | Flags outdated or vulnerable dependencies and opens pull requests to update them automatically. |
| **Test coverage** | Enforces a minimum test coverage and warns when code changes ship without tests. |
| **Reviewer assignment** | Automatically requests the right human reviewer when sensitive files change (`CODEOWNERS`). |
| **Pull request & issue templates** | Make every pull request explain what changed and why; keep issue reports consistent. |
| **Code-quality checks** | Flag oversized pull requests, dead code, and duplicated code to keep changes reviewable. |
| **PR automation** | Auto-labels pull requests by what they touch, adds review hints (size, security, dependencies), and removes stale branches weekly (never `main`/`dev`/`staging`, never a branch with an open PR). It never merges or releases on its own - humans always decide. |
| **Claude in your editor** (optional) | A ready `.mcp.json` lets Claude Code act on this repo through the GitHub MCP server. Per-person, opt-in, no secret stored in the repo. See Section 8. |
| **Release automation** | Works out the next version, generates a changelog, and tags a release from your commit messages. |
| **Branch-flow enforcement** | Keeps code moving one direction - feature → dev → staging → main - and blocks merges that skip a stage. |

---

## 2. How the branches work

Code flows in one direction, with no skipping. `main` is the production branch.

```
feature/*  →  dev  →  staging  →  main (production)
```

Each protected branch requires a pull request, passing checks, and reviewer
approval before code can merge. `main` requires two approvals.

| Branch | Receives from | Reviews required |
|--------|---------------|------------------|
| `dev` | feature branches | 1 |
| `staging` | `dev` only | 1 |
| `main` | `staging` only | 2 |

---

## 3. The commands (Makefile)

You and the CI pipeline run the **same** commands, so local and pipeline
behaviour match. They auto-detect your language.

| Command | What it does |
|---------|--------------|
| `make install` | Install dependencies and activate the local secret-scanning hooks |
| `make lint` | Check code style and quality |
| `make format` | Auto-format the code |
| `make test` | Run the test suite |
| `make build` | Build the project |
| `make coverage` | Run tests with a coverage check |
| `make secret-scan` | Scan the repository for secrets |

If your project uses a language or layout the defaults don't cover, edit the
matching recipe in the `Makefile` - that is the intended place to adapt the
template to your project.

---

## 4. Set-up checklist (do these once per new repo)

1. **Create the repository** from this template ("Use this template" on GitHub).
2. **Run `make install`** once - installs dependencies and turns on the local
   secret-scanning hooks.
3. **Adjust the `Makefile`** commands for your stack if the defaults don't fit.
4. **Set your reviewers** - open `CODEOWNERS` and replace the example names with
   your real team members or GitHub teams.
5. **Turn on branch protection** so the checks become required before merging -
   see Section 6.
6. **Enable full CI** if this is a longer project - see Section 5.
7. When ready, **make the security and quality checks blocking** instead of
   advisory (they start in advisory mode so you can adopt them gradually).

---

## 5. Turning on continuous integration

The heavier checks (build, lint, test, coverage, code quality, deep security
analysis) are **off by default**, so short projects can rely on `make` and the
local hooks alone. To turn the full pipeline on for a longer-running project:

1. Go to **Settings → Secrets and variables → Actions → Variables**.
2. Add a variable named `CI_ENABLED` with the value `true`.

Secret scanning and branch-flow enforcement always run, on every project,
because they protect any codebase regardless of size.

---

## 6. Turning on branch protection

Branch protection is a GitHub setting (not a file), so it is applied after the
repo exists. Pick one:

**Option A - apply once across the whole organization (recommended):**
In your **organization → Settings → Rules → Rulesets → New branch ruleset**,
target `main`, `dev`, `staging`, and enable: require a pull request, require the
status checks to pass, require review from code owners, block force pushes,
restrict deletions, and require conversation resolution. New repos then inherit
this automatically.

**Option B - apply per repository with the script:**
With the GitHub CLI installed and authenticated as an admin, run:

```
bash scripts/setup-branch-protection.sh OWNER/REPO
```

This creates the `dev` and `staging` branches and protects `main`, `dev`, and
`staging` with the rules above.

---

## 7. How to work with the template (the everyday flow)

1. Cut a `feature/...` branch from `dev`.
2. Make your change; run `make lint` and `make test` locally.
3. Commit - the secret hook checks for credentials automatically.
4. Open a pull request into `dev`, using the pull-request template.
5. The automated checks run; address anything they flag.
6. Get it reviewed and merged.
7. Promote `dev → staging → main` through pull requests as the work matures.

---

## 8. Using Claude in your editor (optional)

This repo ships a `.mcp.json` so that, if you use **Claude Code** (the CLI or
the VS Code / JetBrains extension), Claude can act on this repository through
the **GitHub MCP server** - opening pull requests, reading issues, checking CI,
and so on, from plain-language requests in your editor.

No secret is stored in the repo: `.mcp.json` references a token by name only
(`${GITHUB_FINE_GRAINED_TOKEN}`). Never paste a real token into the file - it
would be committed and the secret scanner will flag it. Each person connects
with their **own** token, kept in their environment. To enable it:

1. Create a **fine-grained** Personal Access Token
   (GitHub - Settings - Developer settings - Fine-grained tokens):
   - **Repository access:** Only select repositories - pick this repo.
   - **Permissions:** Contents = Read and write, Pull requests = Read and write,
     Issues = Read and write, Metadata = Read (required). Add Workflows =
     Read and write only if you want Claude to edit GitHub Actions files.
   - **Expiration:** set one (e.g. 90 days) - do not choose "no expiration".
   - Prefer this over a classic token: a fine-grained token is limited to the
     repos and permissions you grant, so a leak has a small blast radius.
   - If the repo is owned by an organization, an org admin may need to approve
     the token before it can reach the repo.
2. Put the token in your shell environment (not committed to any file). The
   name must match `.mcp.json` exactly - uppercase, no spaces:
   ```
   export GITHUB_FINE_GRAINED_TOKEN=your_token_here
   ```
3. Open the project in Claude Code. The first time, it asks you to **approve**
   the GitHub server defined in `.mcp.json` - approve it.
4. Verify with `claude mcp list` - the `github` server should show connected.

The token only ever grants what you give it: a read-only token lets Claude read
the repo but not push or merge; the write permissions above are what allow it to
open and manage pull requests. It can never exceed your own GitHub access.

This is per-person and entirely optional. Nothing else in the template depends
on it; the workflows and checks run on GitHub regardless of whether you use it.

---

## 9. Standard formats

### Commit / pull-request titles

Titles follow a simple prefix format. This keeps history readable and lets
release versioning work automatically.

```
<type>: short summary

types:
  feat:     a new capability        → minor version bump
  fix:      a bug fix               → patch version bump
  feat!:    a breaking change       → major version bump
  chore:    maintenance, no release
  docs:     documentation only
  refactor: code change, no behaviour change
  test:     tests only
```

Examples:
```
feat: add password reset
fix: correct cart total with discounts
feat!: change the report export format
```

### Pull-request description (from the template)

Every pull request should answer:
- **What changed and why** - in plain language, not a restatement of the diff.
- **Related task / issue** - a link.
- **How it was tested** - what you ran.
- **Risk & scope** - does it touch sensitive areas (auth, data, billing)?

### Bug report

- What happened, and what you expected.
- Steps to reproduce.
- Branch / environment and version.
- Logs or screenshots (never paste secrets).

---

## 10. Good to know

- **Security and quality checks start advisory** - they report problems but
  don't block merges at first, so you can adopt them gradually and tune out
  false positives, then make them blocking when ready.
- **Local hooks activate with `make install`** (once per machine). The CI
  secret scan always runs as a safety net regardless.
- **If a real secret ever reaches the repository, rotate it** (change the
  credential) - removing it from history is not enough.
