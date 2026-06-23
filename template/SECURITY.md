# Security Policy

This project follows the Tenacious Development Standard for security (§3).

## Secrets

- No credentials, tokens, or keys in source, config, diffs, or logs.
- Secrets come from environment variables / a secrets store, injected at
  deploy time. `*.env.example` lists variable names with placeholder values only.
- A pre-commit hook and a CI scan block secrets from entering the repository.
- If a real secret ever reaches git, **rotate it immediately** - removing it
  from history is not enough.

## Automated security checks (in CI)

- **Secret scanning** - on every push and pull request.
- **Dependency scanning** - Dependabot flags and updates vulnerable dependencies.
- **Static analysis (SAST)** - Semgrep scans every PR; CodeQL runs deeper on the default branch and weekly.

## Reporting a vulnerability

Report suspected vulnerabilities privately to the project's Tech Lead / Project
Owner (do not open a public issue). Include steps to reproduce and impact.
