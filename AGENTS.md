# AGENTS.md - The Tacit

Project conventions for AI assistants and engineers (per Tenacious Development Standard §1). Read this before making changes.

## What this project is

The Tacit is an AIDLC delivery governance system: it answers "Can this change safely move from pull request to release?" using **deterministic rules for safety** and **AI for assistance only** (summaries, explanations, gap detection). AI never decides readiness or approves a release.

- Agreed design / source of intent: `inception.md` (project root).

## Hard rules

1. **The policy engine has no I/O.** Everything under `backend/app/domain/` is pure Python - no DB, no FastAPI, no network, no AI imports. It is the safety core and is unit-tested in isolation.
2. **AI is never the gate.** `backend/app/domain/` must never import from `backend/app/ai/`. AI output lives in `AiArtifact` and is never read by the engine.
2b. **GitHub feeds facts, not decisions; and acts only when authorized.** PR data is pulled from GitHub (on-demand) behind `SourceControlPort` and handed to the engine as plain facts; the engine never imports the adapter and stays source-agnostic. Read failure degrades to last-known + manual - never crashes the gate. **Governed write (v1):** every GitHub write is authorized by the engine first (`write_gate`), is dry-runnable + idempotent + audited (`GitHubWrite`), and irreversible writes (merge, production, repo scaffold) require a human trigger. No write bypasses the engine. Auth is a least-privilege GitHub App, referenced by pointer.
2c. **CI/CD: govern, don't run.** The Tacit reads pipeline results (gate inputs + risk signals) and triggers pipelines via the governed write path, behind `PipelinePort`. It never runs builds, hosts runners, or replaces GitHub Actions. Triggering a pipeline is a governed write (rule 2b applies); the deploy-authority answer comes from the engine.
2d. **tenai-infra: govern its output, don't rebuild it.** tenai-infra (`Docs/reference/tenai-infra`) is the execution/mesh layer (multi-device, multi-agent coding-from-anywhere). The Tacit interoperates as the governance layer: its skills POST signals via `SkillSignalPort`. **Skill signals are claims to verify, never gate overrides** - the engine still decides; signal-driven writes still go through rule 2b. The Tacit does not rebuild the mesh/remote-access/agent-dispatch.
3. **No secrets in the repo.** No credentials, tokens, or keys in source, config, or seeds - only `*_pointer` location strings. Example config lists variable names with placeholder values only.
3b. **One deliberate exception: the per-tenant Anthropic key** is stored **encrypted at rest** in the DB (teams self-serve via UI). It is AES-encrypted with a master key held only in the server env (`APP_ENCRYPTION_KEY`), never logged, and never returned by any API (write/replace only). Everything else stays pointer-only - the GitHub token included.
4. **Tenant isolation.** Every tenant-scoped query filters by `tenant_id`. Never return cross-tenant data.
5. **Auditable transitions.** Every state change writes an `AuditEvent` (who/what/when/before→after).
6. **Real auth, attributed actions (Capability K).** Users log in with email + password (hashed, never plain, never returned by any API). Roles (`tech_lead/project_owner/engineer/devops`) are enforced on protected routes. Every approval and audit event is attributed to the authenticated user - no shared logins. The auth layer is isolated so SSO/OIDC can replace the credential check later.

## Layout

- `backend/app/domain/` - pure policy engine + versioning (the safety core)
- `backend/app/services/` - orchestration, audit, tenant scoping
- `backend/app/repositories/` - data access (swappable backend)
- `backend/app/ai/` - `AIAssistant` port + Anthropic adapter + deterministic fake
- `backend/app/sourcecontrol/` - `SourceControlPort` + GitHub adapter (read + governed write via GitHub App) + deterministic fake
- `backend/app/scanner/` - `ScannerPort` + tool wrappers (gitleaks/ruff/vulture/jscpd) + fake (Capability F)
- `backend/app/pipeline/` - `PipelinePort` + GitHub Actions adapter (read + trigger) + fake (Capability H); governs CI/CD, never runs it
- `backend/app/bootstrap/` - repo-skeleton templates + secret-scanning kit + standard CI config (Capability E)
- `backend/app/skillsignal/` - `SkillSignalPort` + inbound endpoints for tenai-infra skill signals (Capability I)
- `backend/app/knowledge/` - `KnowledgePort` + ingest/recall, search/embeddings, AI summarization (Capability J)
- `backend/app/api/` - FastAPI routers
- `frontend/` - minimal React SPA

## Commands

The `Makefile` (in `backend/`) is the single command surface for build, run, lint, and test. CI runs the same targets.

## AI provider

Anthropic Claude, model `claude-opus-4-8` (Opus 4.8). **Per-tenant BYO key:** each team supplies its own key via the UI; it is encrypted at rest (see hard rule 3b) and decrypted only at call time. A tenant with no key has AI features disabled - the deterministic gate and records still work. No shared system key.
