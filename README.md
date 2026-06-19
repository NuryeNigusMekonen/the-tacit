# The Tacit

**AIDLC delivery governance for Tenacious projects.** Answers one question for any engagement - *"Can this change safely move from pull request to release?"* - and explains why, in plain language.

The Tacit turns the [Tenacious Development Standard](Docs/Tenacious_Development_Standard.docx.md) into **deterministic, enforced rules** for branch flow, PR readiness, and release gating, while using **AI for assistance only** (summaries, release notes, gap detection, blocker explanations). Deterministic rules decide readiness; humans own approvals and releases.

## Status

Inception complete. See [`inception.md`](inception.md) for the agreed design, scope, data model, policy rules, and build plan. Construction has not started - this is the project scaffold (folder structure + starter config), no application code yet.

## Layout

```
backend/    FastAPI + SQLAlchemy + SQLite; pure policy engine in app/domain/
frontend/   Minimal React SPA (Vite)
Docs/       Source-of-truth standard and reference material
inception.md  Agreed design / construction reference
AGENTS.md   Conventions for engineers and AI assistants
```

## MVP scope

Nine capabilities in v1 - the full vision in one version (expanded by decision from the original two): **(A)** branch strategy & pull requests, **(B)** release management, **(C)** AI assistance, **(D)** GitHub integration (read + governed write), **(E)** project bootstrapper, **(F)** code-quality & security scanner, **(G)** GitHub write-back, **(H)** CI/CD orchestration (governs the pipeline; GitHub Actions runs it), **(I)** tenai-infra interop (launch + govern; does not rebuild the mesh), **(J)** tacit knowledge / organizational memory (the namesake), **(K)** authentication & roles (built-in email+password login, roles enforced, SSO-ready). Built safe-core-first: foundations + governance engine + auth come first; governed writes (G), pipeline-trigger/bootstrapper (E, H), interop (I), and knowledge (J) follow. Multi-tenant from day one. This is a large, multi-month build by deliberate choice. See `inception.md` §2–§3 for scope and §10c for the write-access guardrails.

## Getting started (backend)

```bash
cd backend
make install      # install deps
cp .env.example .env   # fill in env values locally; never commit .env
make test         # run the suite
make run          # start the API on :8000
```

## Getting started (frontend)

```bash
cd frontend
npm install
npm run dev       # Vite dev server on :5173
```

## Principles

- The policy engine has no I/O and never imports AI - the safety core stays pure (see `AGENTS.md`).
- No credentials in the repo - pointers only (Standard §3).
- Every state transition is auditable.
