# The Tacit - AIDLC Delivery Governance System

**Inception record (agreed intent).** Working name: *The Tacit* - Tenacious AI Delivery & Control Tool.

- **AIDLC:** SDLC + AI-assisted governance. Deterministic rules decide safety; AI assists (summarize, explain, detect gaps) and is never the gate. Humans own approvals and releases.
- **Reference material (`Docs/`):** Tenacious Development Standard (source of truth), Tools.md, the Modo Yoga tracker, `SECRET_SCANNING_KIT.md`, `pre-build-process` (background only), and `reference/tenai-infra` (the execution/mesh layer The Tacit interoperates with - Capability I).
- **Status:** Inception complete. Decisions below are locked. Next stage: construction.

## How to read this document

This single document bundles three layers - **requirements** (what & why), **planning** (how we'll get there), and **design** (how it works). The map below shows which section is which. Detailed/testable design lives in the companion `elaboration.md` (acceptance criteria, blocker catalog, state machines, API contract).

| Section | Layer |
|---|---|
| §1 Product vision | Requirements (the "why") |
| §2 MVP scope | Requirements (the "what") |
| §3 Non-goals | Requirements (boundaries) |
| §4 User roles | Requirements |
| §5 Core workflows | Requirements |
| §6 Data model | Design |
| §7 Policy rules | Design |
| §7a Two tasks at a glance | Requirements (explained simply) |
| §7b Tools & stack | Planning |
| §8 Architecture | Design |
| §9 Folder structure | Design |
| §10 Future integration | Planning |
| §11 Risks | Planning |
| §12 Build plan | Planning |
| §13 Scalability | Planning (with Design rationale) |

> **Not covered here:** UI/visual design (the React screens are named in §12 but not drawn). It is deliberately deferred to its build-plan phase (the React SPA phase) - designed hands-on against the real API, not in a doc.

---

## Locked decisions (from §11 open questions)

| # | Decision | Choice |
|---|---|---|
| 1 | Tenancy | **Multi-tenant from day one** - org/tenant boundary; multiple Tenacious teams share one instance with isolation. |
| 2 | PR/check data source (v1) | ~~Manual UI entry only~~ **— SUPERSEDED by Decision 6.** Original choice was manual entry with no integration; later revised to GitHub auto-pull. GitHub-pulled facts are now the primary source; manual entry remains only the fallback for fields GitHub can't provide (see Decision 6). |
| 3 | UI flavor | **Minimal React SPA** consuming the REST API. |
| 3a | UI quality bar | **Clean and credible, not elementary, not elaborate.** v1 ships on a component library with a consistent design system (spacing, colors, typography) and clear status states (blocked = red, risky = amber, ready = green). **Deferred to post-MVP:** rich/interactive dashboards, charts (release frequency, blocker trends), drag-drop, theming, animations, real-time updates. Rationale: the value is in the engine + records, not pixels; polish the *right* screens after real use. The React + REST foundation supports a richer UI later **without a rewrite** - so "beautiful later" is cheap by design. |
| 4 | "Risky" PR rule | **Sensitive surface = risky** - all hard rules pass but the change touches Standard §1 risk surfaces (auth, shared utils, migrations, billing, PII, prompts) → `risky`, mergeable with extra scrutiny. |
| 5 | AI provider | **Anthropic Claude** - model `claude-opus-4-8` (Opus 4.8). |
| 5a | AI key ownership | **Per-tenant (BYO key).** Each team uses its **own** Anthropic key - own billing, own usage. A team pastes its key in settings; it is stored **encrypted at rest** in the DB (AES via a master key held in the server env, never in DB/repo). No team key set → **AI features disabled for that team; deterministic gate and records work fully.** No shared fallback key. |
| 6 | GitHub integration | **In v1 (revised).** System auto-pulls PR data from each project's GitHub repo. **On-demand pull** (no polling/webhooks in v1). **GitHub-primary + manual fields:** auto-fill what GitHub provides; humans/AI set what it can't. **GitHub only** (Azure DevOps later). Credential referenced via env/secrets store, never in the repo (Standard §3). |
| 7 | v1 scope (expanded) | **Nine capabilities, comprehensive current version.** A PRs · B releases · C AI assist · D GitHub (read + write) · **E bootstrapper · F scanner (+ historical PR audit) · G write-back · H CI/CD orchestration · I tenai-infra interop · J tacit knowledge · K auth & roles** - all in v1, built as one version, safe-core-first (auth early; I and J later). This is the full vision in one version - a large, multi-month build by deliberate choice, not a minimal MVP. |
| 8 | GitHub write access | **v1 is read + governed write (no longer read-only).** Writes go through the §10c guardrails: **GitHub App** (least-privilege), **engine-gated** (no write without the engine's OK), **human-triggered for irreversible actions** (merge, production, repo scaffold), dry-run + idempotency, audit-on-write, kill switch. |
| 9 | CI/CD posture | **Govern, don't run.** The Tacit orchestrates the pipeline (reads results as gate inputs, triggers on approval, scaffolds standard CI config, is the deploy-approval authority) behind a `PipelinePort`; GitHub Actions runs the actual build/test/deploy. The Tacit never hosts runners or replaces the CI engine (Standard §4). |
| 10 | tenai-infra interop | **Interoperate two-way, don't merge.** tenai-infra is the execution/mesh layer (multi-device, multi-agent coding-from-anywhere); The Tacit is the governance layer. **Govern:** skills POST signals (via `SkillSignalPort`) and The Tacit governs the output. **Launch (Option A):** The Tacit can also be the front door - from the dashboard, supply tenai's inputs + pick the agent (Claude/Codex/Gemini), click start, and The Tacit *asks tenai-infra to launch the session* on the device. **Orchestrate, never reimplement** - The Tacit does not run the mesh/devices/agents; those stay tenai-infra. Needs tenai to expose a launch trigger. **Trust boundary:** signals are claims to verify, never gate overrides - the engine decides. |
| 11 | Tacit knowledge (the namesake) | **Capture project experience → reusable organizational memory.** Capability J ingests lessons in any form (retros, incidents, decision records) + structured signals already flowing in; AI extracts patterns and recalls the right lesson at the right moment (bootstrap, risky PR/release). Knowledge-management, distinct from deterministic governance; AI recalls/summarizes, never decides a gate. **Sequenced last** - depends on real data accumulating. |

> **Note (direction change):** The original plan deferred Git integration to a later version (manual entry in v1). Per a later decision, **GitHub auto-pull is now part of v1**. Sections below reflect the revised scope. Task 2 (releases) remains mostly human-driven - GitHub only confirms what merged; approvals and rollback plans are a Tenacious process, not a GitHub artifact.

---

## 1. Product vision

A single, auditable place that answers, for any Tenacious engagement: **"Can this change safely move from pull request to release?"** - and explains *why* in plain language. The Tacit turns the Tenacious Development Standard into deterministic, enforced rules for branch flow, PR readiness, and release gating, while using AI as an assistant only. It replaces the manual parts of the Modo Yoga tracker (copy-the-Next-row, recompute version, update Environments, write the announcement) with a structured, auditable workflow that keeps the same two-part record the Standard mandates: a per-release log and a current-state environments view, with credentials as pointers only.

**The deeper purpose (the name).** *Tacit* = knowledge that's understood from experience but never written down - the hard-won lessons living in engineers' heads. The Tacit's north star is to make that knowledge **explicit and reusable**: by sitting at the center of every project's lifecycle, it captures what happened *and what was learned*, turning scattered project experience into organizational memory that informs every future project. Governance (A-I) is how it earns its place in the workflow; **tacit-knowledge capture (Capability J)** is what it ultimately becomes - the system living up to its name.

## 2. MVP scope

> **Scope (revised): nine capabilities in v1 - the full vision in one version.** Originally two governance capabilities; expanded by decision to the complete current version: **A** PRs, **B** releases, **C** AI assist, **D** GitHub integration (**read + governed write**), **E** project bootstrapper, **F** code/security scanner, **G** GitHub write-back, **H** CI/CD orchestration, **I** tenai-infra interop (launch + govern), **J** tacit knowledge / organizational memory, and **K** authentication & roles. v1 is **no longer read-only** toward GitHub - it performs governed writes under the §10c guardrails. This is the entire vision delivered as one version - a **large, multi-month build by deliberate choice, not a minimal MVP**. It is still built **safe-core-first** (see §12): the deterministic governance core and auth come first; risky writes, tenai launch, and the knowledge layer come later in the sequence, so a usable product exists early even though the full scope is committed.
>
> **CI/CD principle (H):** The Tacit **governs and orchestrates** the pipeline - it does **not** run builds itself. GitHub Actions (the muscle) runs build/test/deploy; The Tacit (the brain) reads pipeline results as gate inputs, triggers pipelines once the engine + humans approve, scaffolds standard CI config via the bootstrapper, and acts as the deploy-approval authority. It never replaces the CI runner (Standard §4: "automation speeds the mechanics, it does not remove the approval gate").
>
> **tenai-infra interop (I):** The Tacit is the **governance layer** that tenai-infra's **execution layer** (mesh, multi-device/agent coding-from-anywhere) feeds into. Its agent skills POST signals to The Tacit; The Tacit governs the output. The Tacit does **not** rebuild the mesh/remote-coding/agent-dispatch. Interoperate at the seam, don't merge. Sequenced after the governance core.

**A. Branch strategy & pull requests (Standard §2)**
- Project setup: name, **GitHub repository (owner/repo) + access token pointer**, owner, environments, branch policy, versioning conventions.
- Branch policy: `feature/* → dev → staging → production`; one-directional; no skipped stages; protected branches require PRs; explicit hotfix reconciliation path.
- **PR data auto-pulled from GitHub** (on-demand): open PRs, source/target branches, description, check-run status (GitHub Actions), review-comment threads + resolution. Refreshed when a project/PR view is opened.
- **AI-first, human-confirmed fields GitHub can't provide:** `touches_sensitive_surface` and description-quality judgment. When the team has an AI key, **AI goes first** - it reads the changed files and **pre-fills** a suggested value (e.g. "looks sensitive - touches auth"); the **human confirms or overrides**, and the confirmed value is what drives the gate. No AI key → plain human toggle. AI suggests; the human always owns the decision (AI never sets a gate-affecting field unconfirmed).
- PR records with readiness state (`ready | blocked | risky | merged`) computed from GitHub-pulled + manual facts: valid source→target, description present, automated review ran, review comments resolved/answered, required checks pass; plus **sensitive-surface → risky** (decision 4).
- Policy engine returns a list of named blockers, not a boolean. **The engine is unchanged by the data source** - GitHub adapter just supplies the facts a form used to.

**B. Release management (Standard §7)**
- Release records: version, type (`first_release | major | minor | patch`), target environment, changes, staging-validation state, approval state, rollback plan, announcement text.
- Approval chain enforced: staging is the release gate (Tech Lead + Project Owner jointly); production is execution only.
- Two-part record: Release Log + Environments view, auto-updated on release.
- Versioning helper: suggest next version from type; draw next codename from the project's pool on a Major.

**C. AI assistance (assist-only, both areas)**
PR summaries, release-note drafts, missing-info detection, blocker explanations, suggested release type, risk summaries, announcement drafts. Advisory and clearly labeled; never flips a readiness or approval state. **Per-tenant BYO key:** each team supplies its own Anthropic key (stored encrypted at rest); a team with no key configured simply has AI features disabled while the deterministic gate and records keep working.

**The 7 things AI actually does** (AI never decides - the deterministic engine does; AI only writes, explains, and suggests):

| # | AI feature | What it does | For which task |
|---|---|---|---|
| 1 | PR summary | Reads the diff/PR and writes a plain-English "here's what changed" | Task 1 |
| 2 | Missing-info detection | Flags "you forgot a description / rollback plan / etc." | Both |
| 2b | Sensitivity pre-fill | Reads changed files and **pre-fills** the `touches_sensitive_surface` flag (AI-first); human confirms/overrides, confirmed value drives the gate | Task 1 |
| 3 | Blocker explanation | Takes a blocker code like `REVIEW_COMMENTS_UNRESOLVED` and explains it in friendly words | Both |
| 4 | Suggested release type | Looks at the changes and suggests "this looks like a Minor" (human confirms) | Task 2 |
| 5 | Release-note draft | Drafts the release notes from the list of changes | Task 2 |
| 6 | Risk summary | Summarizes what's risky about a change | Both |
| 7 | Announcement draft | Writes the team channel message (the v0.4.0 shipped… post) | Task 2 |

Every AI result is stored separately as an `AiArtifact` - never mixed with decision data, never read by the engine.

**D. GitHub integration (read + governed write)**
- `SourceControlPort` with a **GitHub adapter** and a **deterministic fake** for tests/offline dev.
- **Read (on-demand):** list PRs, fetch a PR's branches/description/checks/review threads.
- **Write (governed, per §10c guardrails):** comment/status on PRs, open PRs/labels/branches, merge on `READY`, execute production promotion - **every write engine-gated; irreversible writes human-triggered.**
- Auth via a **GitHub App** (fine-grained, least-privilege, short-lived tokens); credential referenced from env/secrets store, **never in the repo or DB**.
- Graceful degradation: if GitHub is unreachable or unauthorized, reads fall back to last-known + manual fields; writes fail safe (never partial, never silent). Never crash the gate.

**E. Project bootstrapper + GitHub template repository (Standard §1/§2/§3 setup)**
- **Primary mechanism: a Tacit-specific GitHub *template repository*.** A standing repo marked as a GitHub template; when anyone creates a new repo and clicks **"Use this template,"** GitHub copies the standard structure in automatically - native GitHub, no code, works even before The Tacit runs. This is what the team wants: a template that pops up at repo creation.
- **The template is highly specific to The Tacit** - every file exists because The Tacit governs it or it solves a problem we target:
  - `.github/workflows/ci.yml` - runs build/test/lint + secret-scan; these are the **required checks** The Tacit reads for PR readiness.
  - secret-scanning kit (`Docs/SECRET_SCANNING_KIT.md`) - prevents credential leaks from the first commit (Standard §3).
  - `AGENTS.md` - the Tenacious conventions The Tacit enforces (Standard §1).
  - PR description template - solves merged-without-description.
  - `.gitignore` + `.env.example` - the "no secrets, pointers only" rule.
  - branch-protection guidance + `Makefile` - the branch policy and single command surface (Standard §2, §4).
- **Secondary mechanism: the bootstrapper (write into an existing repo).** For repos not created from the template, or to *apply/update* the standard on an existing repo, the bootstrapper writes the same skeleton in via the governed write path. The repo is created on GitHub by a human first; they onboard the project entering `owner/repo`; The Tacit knows *where* from that address - it never invents a location.
- **The Tacit does not create the repo in v1.** Auto-creating a brand-new repo (choosing org + name, via the GitHub API) is a deliberate **future option** - it needs repo-creation permission on the GitHub App, higher than write-into-existing. v1 keeps it simple: human creates the empty repo, Tacit fills it.
- **Ships the secret-scanning kit (`Docs/SECRET_SCANNING_KIT.md`)** into every new repo as part of the skeleton (its §5 customization + `make install` auto-wiring is designed for this).
- A **write** capability - uses governed write access (D); human-triggered (high-stakes tier). Draws on the `pre-build-process` doc as a template source (background only).

**F. Code-quality & security scanner**
- Analyze a project's repo and produce **professional, actionable findings**: hardcoded credentials/secrets, unused variables/methods/constants/imports, duplicate code & repeated patterns, general defects/inconsistencies, improvement insights.
- **Wraps proven open-source tools** behind a `ScannerPort` (e.g. gitleaks for secrets, ruff/vulture for unused code, jscpd for duplication); AI summarizes findings into actionable guidance. Not a custom static-analysis engine. Mirrors the `Tools.md` Repo Analyzer / PR Reviewer, generalized to the Tenacious standard, multi-language.
- **Secret-detection layer is `Docs/SECRET_SCANNING_KIT.md`.** **Synergy:** secret detection serves Standard §3 and feeds the PR `REQUIRED_CHECKS_FAILING` / secret-scan check. AI explains; deterministic tools + humans decide (assist-only rule holds).
- **Historical PR audit (read-only) - one-click dashboard feature.** Beyond the current code, F can **retrieve and analyze a repo's full PR history** via the GitHub API (all past PRs: title/description, review threads + resolution, approvals or lack thereof, check results, commits, merge info). From the dashboard, a single **"Run audit" button** on a project generates, with no command line: the **PR history**, **most-active contributors** (who opened/merged/reviewed most), **most common issues** (recurring flagged themes), **activity over time** (PRs per month), **most-changed files / hotspots**, and the **flagged-PR list** (no-description, large, merged-without-review). Produces a readable report of the repo's past delivery hygiene. Read-only (uses the read side of D); PR *reviews* come from the API, not just a `git clone`. Naturally seeds the knowledge layer (J). Mind GitHub rate limits when paging full history; cache results.
- **Proven prototype:** this capability has been validated end-to-end by a standalone script (`pr_audit.py`) run against `get10acious/modo-compass` - 71 PRs, 395 review comments, 794 commits analyzed, surfacing a leaked credential, bot-only review, and oversized/undescribed PRs. The dashboard feature is that proven logic refactored behind `ScannerPort` + an API endpoint + a results view - integration, not new design, and no conflict with the rest of F.

**G. GitHub write-back (the actor layer)**
- The staged write path (§10c) implemented in v1: GitHub App + least-privilege perms, **engine-gated** writes, **human-in-the-loop for irreversible actions**, dry-run + idempotency, audit-on-write, rate limits + kill switch.
- Tiered rollout still applies *within* v1's construction (safe machinery → reversible writes → structural → high-stakes → production) - see build plan.

**H. CI/CD orchestration (govern, don't run)**
- The Tacit **governs** the pipeline; GitHub Actions **runs** it. Behind a `PipelinePort` (GitHub Actions adapter + fake).
- **Read pipeline results** - not just pass/fail but failing stage, test counts, coverage, run history; these become richer **gate inputs** (e.g. "can't promote to staging if the last dev pipeline was red") and **risk signals** (e.g. "passed only after 3 retries").
- **Trigger pipelines (governed write, via G)** - once the engine + humans approve, The Tacit *fires* the right pipeline (e.g. trigger the production deploy on the staging gate passing); re-run flaky checks. The approval stays human-owned; The Tacit only triggers after it.
- **Scaffold standard CI config (via the bootstrapper E)** - new repos get a standard `.github/workflows/` running the standard `Makefile` targets + secret-scan + test/lint/build (Standard §4: CI runs the same Makefile targets).
- **Deploy-approval authority** - a pipeline can ask The Tacit "am I allowed to deploy to production?"; the engine answers from approvals + rollback plan + staging-validated. The pipeline cannot deploy past a `no`.
- **Boundary:** The Tacit never runs builds, hosts runners, or replaces GitHub Actions. It is the decision authority *over* the pipeline, not the pipeline.

**I. tenai-infra interop (govern the agents' output, don't rebuild the mesh)**
- **What tenai-infra is** (`Docs/reference/tenai-infra`): a Tailscale-mesh dev infrastructure for **multi-device, multi-agent coding from anywhere (incl. phone)** - agents (Claude/Gemini/Codex) dispatched to isolated git worktrees, a conductor/task-DB/webapp, and cross-CLI **skills** (`register-push`, `proof-of-work`, `verify`, `sync-log`, `register-task`).
- **The seam:** tenai-infra is the **execution layer** (where/how work happens); The Tacit is the **governance layer** (whether the output is safe to ship). They interoperate, they do **not** merge.
- **Integration:** tenai-infra's skills POST signals to The Tacit (they already POST to a webapp API - point them at The Tacit). `register-push` triggers a Tacit PR sync; `proof-of-work` (PROOF.md) becomes a readiness **evidence input**; `sync-log` entries land in the audit trail; `verify` results inform the checks.
- **The Tacit's bootstrapper (E) ships tenai-infra's `.agents/skills/`** into new repos so every Tenacious repo gets the standard agent skills.
- **TWTL** (tenai's token-weighted leverage metric) feeds The Tacit's risk/productivity dashboards (future).
- **Two-way: launch + govern (Option A - orchestrate, don't reimplement).** Beyond receiving signals, The Tacit can be the **front door** for tenai-infra: from the dashboard a user supplies/pre-fills what tenai needs (project, repo, device, task, and which agent - Claude Code / Gemini / Codex) and clicks **"Start coding session"**; The Tacit **calls tenai-infra to launch the session on the chosen device**, then governs the result when it returns (the existing inbound signals). So The Tacit becomes a single pane: **launch the work, then govern it.** The agents (Claude/Codex/Gemini) are **tenai-infra's**, surfaced through The Tacit's UI - The Tacit does not host or run them. (Distinct from Capability C, which is The Tacit's own assist-AI for summaries/explanations, not a coding agent.)
- **Dependencies/boundary for launch:** requires tenai-infra to expose a trigger (API/command) to start a session; The Tacit passes inputs securely (pointer-only, no stored secrets) and shows status. It still does **not** run the mesh, manage devices, host terminals, or dispatch agents - tenai-infra does all of that. Orchestrate, never reimplement.
- **Boundary:** The Tacit does **not** rebuild the mesh / remote-access / agent-dispatch - that stays tenai-infra. **Trust boundary:** skill-posted signals are *claims* (inputs to verify), never gate overrides; the engine still decides; skill writes still flow through governed-write guardrails (G).

**J. Tacit knowledge / organizational memory (the namesake)**
- **Captures project experience in any form** - retrospective notes, incident write-ups, decision records, READMEs, plus the structured signals already flowing in (release logs, PROOF.md, scan findings, audit events). Per-tenant, searchable.
- **AI-powered recall** - extracts patterns and lessons; answers "have we solved this before?"; surfaces the *right* past lesson at the *right* moment (when a new project is bootstrapped, or a PR/release hits a familiar/risky situation - e.g. "last time a change touched billing, here's what went wrong").
- **Turns tacit knowledge explicit** - the hard-won lessons usually trapped in engineers' heads become reusable organizational memory; new projects start informed, not blank.
- **Connects to existing layers:** the audit trail records *what happened* - this adds *what we learned*; the bootstrapper (E) surfaces lessons from similar past projects; AI assist (C) is the recall engine.
- **Honest nature:** this is **knowledge management** (fuzzy, search/recall, likely needs semantic search/embeddings), distinct from the deterministic governance of A-I. Value depends on **recall quality** - the right lesson surfacing at the right time. **Sequenced last** - it benefits from real project data accumulating once the rest is live. AI summarizes/recalls; it never decides a gate (assist-only rule holds).

**K. Authentication & roles (in v1)**
- **Built-in login** - users sign in with email + password (passwords hashed, never stored plain); sessions/tokens for the API and SPA.
- **Per-user roles enforced** - Tech Lead, Project Owner, Engineer, DevOps (optional). The release gate checks the *authenticated* user's role: only a real Tech Lead and a real Project Owner can record the joint staging approval.
- **Approvals are attributable to the logged-in user** - this is what makes the audit trail and the joint-approval gate trustworthy (no shared logins, no "select who you are").
- **Tenant-scoped** - every user belongs to one tenant; login resolves the tenant, and all data stays isolated to it.
- **SSO-ready, not SSO-now** - designed so company SSO/OIDC can be added later without a rewrite (the auth layer sits behind its own boundary). v1 ships email + password.
- **Built early** - because every other capability's actions and approvals are attributed to a user, auth comes near the start of construction, right after the foundations.

**Delivery surface:** FastAPI backend + REST API, SQLite, React SPA (Decision 3a), multi-tenant with **built-in auth + roles**, **GitHub-connected (read + governed write) + CI/CD-orchestrating**. Seeded with Modo Compass data.


## 3. Non-goals for v1

- ~~No Git integration~~ → **GitHub read + governed write is in v1** (on-demand reads; engine-gated writes). Still out: **Azure DevOps** (later), **polling/webhooks** (on-demand only).
- No CI/CD **execution** - The Tacit *orchestrates* the pipeline (reads results, triggers on approval, scaffolds config, is the deploy-approval authority; Capability H) but never **runs** builds, hosts runners, or replaces GitHub Actions. The scanner (F) analyzes code but does not replace the project's own CI.
- No enforcement of Standard §1/§3/§4/§5/§6 beyond pointers/flags PR readiness needs.
- No secret storage - credential-*location* pointers only.
- ~~No real auth~~ → **Authentication & roles are now in v1** (Capability K): built-in email + password login, per-user roles (Tech Lead / Project Owner / Engineer / DevOps) enforced, sessions; designed so company SSO/OIDC can be added later without a rewrite. Approvals are attributed to the authenticated user.
- No PostgreSQL; no notification delivery (generate announcement text only).
- No automated rollback execution - plans recorded and required, not run.

## 4. User roles

Workflow actors (tenant-isolated; not security-enforced principals beyond tenancy in v1):

| Role | Responsibilities |
|---|---|
| Engineer | Creates PR records; addresses automated-review comments; validates dev. |
| Tech Lead | Approves dev→staging; co-approves staging release gate; owns combined gate where no staging. |
| Project Owner | Co-approves staging→production gate jointly with Tech Lead. |
| DevOps (optional) | Co-validates at dev where the role exists; executes production deployment. |
| System/AI assistant | Advisory summaries/drafts/gap detection - never an approver. |

Fold-down rule is first-class: no-staging projects collapse to `dev → production`, Tech Lead owning the combined gate.

## 5. Core workflows

1. **Project onboarding** - a human creates the (empty) GitHub repo first, then creates the Project (under a tenant) with that **GitHub repo (owner/repo) + GitHub-App install pointer**, environments, branch policy, versioning scheme, codename pool; seed current environment versions. The repo address entered here is how The Tacit knows where to read and (later) bootstrap.
2. **PR readiness** - system **pulls open PRs from GitHub on demand** (branches, description, check status, review threads); user sets the GitHub-can't-know fields (sensitive-surface); engine computes state + blockers; AI offers summary and flags missing info.
3. **Merge** - when `ready` and a human merges, mark `merged`.
4. **Promotion / release** - create Release for a target env; engine validates promotion legality, staging-validation, approval state; AI suggests type, drafts notes + risk summary.
5. **Staging gate** - record joint Tech Lead + Project Owner approval; production blocked without it.
6. **Production execution & post-release** - execution only; on success: update Environments view, append Release Log, generate announcement text. With write-back (G): the system can execute the merge on GitHub (human-triggered, engine-gated).
7. **Hotfix reconciliation** - record hotfix branched from production and merged back down into staging and dev (the one sanctioned backward flow).
8. **Project bootstrap (E)** - on project creation, scaffold the standard repo skeleton + secret-scanning kit into the GitHub repo (human-triggered write); surface per-project recommendations.
9. **Repo scan (F)** - run the scanner on a project's repo; produce findings (secrets, unused code, duplication, defects) with AI-summarized, actionable guidance; surface in the UI.
10. **Governed write (G)** - any GitHub write (comment, label, branch, merge, scaffold) is checked by the engine first; reversible writes can be automatic, irreversible ones need a human trigger; every write is dry-runnable and audited.
11. **Pipeline orchestration (H)** - read pipeline results into the gate (red pipeline blocks promotion); on the staging gate passing, trigger the deploy pipeline (governed write); a pipeline may ask The Tacit "may I deploy?" and is refused if the engine says no. The Tacit governs; GitHub Actions runs.

## 6. Data model / entities

- **Tenant** - org boundary; owns projects and users; isolation key on every row. **`anthropic_key_encrypted`** (nullable; team's own Anthropic key, AES-encrypted at rest - never logged, never returned by the API; null → AI disabled for this tenant), `anthropic_key_set_at`.
- **User** (Capability K) - tenant_id, name, **email (unique per tenant)**, **password_hash** (hashed, never plain, never returned by the API), role (`tech_lead | project_owner | engineer | devops`), active (bool), created_at. The authenticated principal; approvals and audit events are attributed to this user. (SSO fields can be added later without changing the rest.)
- **Session/Token** (Capability K) - user_id, token (or session id), issued_at, expires_at. Backs login for the API + SPA; revocable.
- **Project** - tenant_id, name, **github_repo (owner/repo)**, **github_app_install_pointer** (GitHub App installation ref for read + governed write; env/secrets-store reference, never the credential), owner, versioning_scheme, has_staging, credentials_location_pointer, codename_pool (ordered), created_at.
- **Environment** - project_id, name (`dev|staging|production`), url, rank, current_version, current_codename, last_deployed_at, owner, credentials_location_pointer.
- **BranchPolicy** - project_id, ordered promotion path, protected branches, rule flags (no_skip, no_backward, hotfix_allowed, pr_required).
- **PullRequest** - project_id, **github_pr_number**, source_branch, target_branch, title, description, automated_review_ran, review_comments_resolved, required_checks_passed (**pulled from GitHub**), `sensitive_suggested_by_ai` (AI's pre-fill guess, nullable), `touches_sensitive_surface` (**human-confirmed value the gate uses**; defaults to the AI suggestion until confirmed), computed readiness_state, computed blockers (derived), last_synced_at, timestamps.
- **Release** - project_id, environment_id, version, type, codename, changes, staging_validation_state, approval_state, rollback_plan, announcement_text, status, released_at, released_by.
- **Approval** - release_id, role, approver (user), decision, timestamp (captures joint staging gate).
- **ReleaseLogEntry** - append-only per-release record (version, codename, type, date, environment, changes, next_version, next_target) - models the tracker's Release Log sheet.
- **AuditEvent** - append-only; who/what/when/before→after on every transition.
- **AiArtifact** - type (summary/notes/risk/announcement/gap), target ref, content, model, generated_at - kept separate so AI output is never authoritative state.
- **ScanFinding** (Capability F) - project_id, scan_run_id, category (secret/unused/duplicate/defect), severity, file, line, tool (gitleaks/ruff/vulture/jscpd…), message, ai_explanation (nullable), status (open/acknowledged/resolved), found_at.
- **PrHistoryRecord** (Capability F - historical audit) - project_id, github_pr_number, title, author, target_branch, was_reviewed (bool), review_count, comments_resolved (bool), checks_passed (bool), merged (bool), merged_by, opened_at, merged_at, audit_flags (e.g. merged-without-review, secret-in-history). Read-only snapshot of a past PR for the audit report; can seed `KnowledgeEntry` (J).
- **GitHubWrite** (Capability G) - project_id, action (comment/label/branch/merge/scaffold/promote/trigger-pipeline), tier, triggered_by (user, nullable for automatic), engine_decision (the gate result that authorized it), dry_run (bool), idempotency_key, github_response, status, created_at. Append-only - the write audit trail.
- **PipelineRun** (Capability H) - project_id, branch/environment, provider (github-actions), external_run_id, status (queued/running/passed/failed), failing_stage (nullable), test_count, coverage (nullable), retry_count, triggered_by (user or system, nullable), started_at, finished_at. Read from the provider; used as a gate input + risk signal. The Tacit reads/triggers these; it never runs them.
- **SkillSignal** (Capability I) - project_id, source (register-push/proof-of-work/sync-log/verify), payload (e.g. PROOF.md ref, log line, PR/branch), claimed_result, verified (bool - the engine/GitHub cross-check outcome), received_at. A **claim** from a tenai-infra agent skill; an input to verify, never an authoritative gate result.
- **KnowledgeEntry** (Capability J) - tenant_id, project_id (nullable - lessons can be cross-project), kind (retro/incident/decision/lesson/doc), title, content, source_ref (where it came from), tags, embedding (nullable - for semantic recall), ai_summary (nullable), created_at. Organizational memory; per-tenant, searchable; recalled by relevance, never an authoritative gate result.

Notes from the real tracker: store proper datetimes (sheet uses serials like `46143`); model `next_version`/`next_target` so the tool computes the successor instead of a human copying a cell.

## 7. Policy rules (deterministic core)

Pure functions `(state) → (decision, [blockers])`. Each blocker: code, human message, AI-explainable handle.

**Branch / promotion (§2):** path exactly `dev → staging → production` (or folded `dev → production`); no skipped stage; no backward except explicit hotfix reconciliation; protected branches require a PR; `feature/*` may only target `dev`.

**PR readiness (§2 + decision 4):** `ready` only when all hold - source→target valid, description present/non-trivial, automated review ran, all comments resolved or answered, required checks pass. If a hard condition fails → `blocked` (named blockers). If all hard conditions pass **but** `touches_sensitive_surface` → `risky` (mergeable with extra scrutiny). `merged` once merged.

**Release gating (§7):** staging is the true gate. Production blocked unless the staging release for that version carries complete joint approval (Tech Lead + Project Owner). Every release must name a rollback plan or it is blocked. Production carries no new approval - execution only.

**Versioning (§7 + Conventions):** `MAJOR.MINOR.PATCH`; `first_release` once per product; Major draws next codename from pool; Minor/Patch number-only. Engine suggests next version from type; AI may recommend a type, human confirms.

## 7a. The two tasks at a glance - what's checked, how, and the output

The two capabilities share one pattern: **inputs → policy engine → decision + clear reasons.** Task 1 checks if code is *clean enough to merge*; Task 2 checks if it is *approved and safe to ship*, then records it.

### Task 1 - Pull Request readiness
*Moment: an engineer wants to merge code.*

**What's checked (inputs):**

| Check | Question |
|---|---|
| Branch target valid | Is it `feature/* → dev`, `dev → staging`, or `staging → production`? (no skipping/backward) |
| Description exists | Real "what & why," not a restatement of the diff |
| Automated review ran | Did CodeRabbit/Copilot actually run? |
| Comments resolved | Every review comment fixed or answered |
| Required checks pass | Build, lint, tests, secret-scan all green |
| Sensitive surface? | Touches auth, shared utils, migrations, billing, PII, or prompts? |

**How it decides (rule):**
```
Any hard check fails                         → BLOCKED  (+ list of what failed)
All hard checks pass, but sensitive surface  → RISKY    (mergeable, extra scrutiny)
All pass, nothing sensitive                  → READY
After the human merges                       → MERGED
```

**Output:** status (`ready/blocked/risky/merged`) + a list of **named blockers** (never just "no"). *AI (optional):* PR summary, missing-info hints.

### Task 2 - Release management
*Moment: the team wants to ship to production.*

**What's checked (inputs):**

| Check | Question |
|---|---|
| Promotion legal | Is this `staging → production`? (can't jump from dev) |
| Staging validated | Was it actually tested in staging? |
| Approvals present | Did **Tech Lead AND Project Owner** both approve? |
| Rollback plan | Is there a written way to undo it? |
| Version & type | First / major / minor / patch correct? |

**How it decides (rule):**
```
Not coming from staging        → BLOCKED
Staging not approved by BOTH   → BLOCKED
No rollback plan               → BLOCKED
All present                    → RELEASE ALLOWED
Production step itself          = execution only (no new approval)
```

**Output:** release allowed/blocked (+ what's missing); next version + codename computed; **Environments view** updated; **Release Log** entry added (what/when/who). *AI (optional):* release notes, announcement text, risk summary.

### Side by side

| | Task 1: PR | Task 2: Release |
|---|---|---|
| Checks | code quality (review, tests, description) | approval + safety (2 approvers, rollback, from staging) |
| Decided by | policy engine (automatic) | policy engine + **humans approve** |
| Output | status + blockers | release log + env update + announcement |
| AI helps with | PR summary, gap detection | release notes, announcement, risk summary |

**The shared mechanism is the same engine; the purpose differs:** Task 1 gates code *merging* (frequent, technical); Task 2 gates code *shipping to production* (rare, needs human approval, leaves a permanent record).

## 7b. Tools & technology stack (v1)

The complete toolchain, with the reason each is chosen. Versions are pinned in `backend/pyproject.toml` and `frontend/package.json`.

**Language & runtime**
| Tool | Why |
|---|---|
| Python ≥ 3.11 | Main backend language (per the brief); modern typing for the pure domain core. |
| Node 18+ / npm | Build/run the React SPA. |

**Backend**
| Tool | Role | Why |
|---|---|---|
| FastAPI | Web framework / REST API | Simple, async, Pydantic-native; the brief's suggested direction. |
| Uvicorn | ASGI server | Runs FastAPI in dev and prod. |
| Pydantic v2 + pydantic-settings | Schemas + config | Request/response validation; env-based settings with no secrets in code. |
| SQLAlchemy 2.0 | ORM | DB-agnostic; lets SQLite→Postgres be one URL change. |
| Alembic | Migrations | Versioned schema changes (Standard-style discipline). |
| SQLite (v1) → PostgreSQL (later) | Database | Simplest local start; clean upgrade path. |
| **cryptography** | Encrypt per-tenant Anthropic key at rest | AES via Fernet for the BYO-key feature (decision 5a). **(newly pinned)** |

**External integrations (behind ports)**
| Tool | Role | Why |
|---|---|---|
| **httpx** | HTTP client for the GitHub adapter | Async, well-supported; talks to the GitHub REST/GraphQL API. **(moved to main dep)** |
| anthropic | Claude SDK | The AI assist adapter; per-tenant key. Model `claude-opus-4-8`. |
| GitHub API + GitHub App | PR data source + actor | On-demand pull of PRs/checks/reviews/pipelines (read); governed writes via a least-privilege GitHub App (decisions 6, 8, 9). |
| GitHub Actions | CI/CD runner (Capability H) | The Tacit *governs* it (read results, trigger, deploy-authority); GitHub Actions *runs* the build/test/deploy. Behind `PipelinePort`. |

**Scanner tools (Capability F, wrapped behind `ScannerPort`)**
| Tool | Detects |
|---|---|
| gitleaks + secret-scanning kit (`Docs/SECRET_SCANNING_KIT.md`) | hardcoded credentials/secrets |
| ruff / vulture | unused variables, methods, constants, imports; defects |
| jscpd | duplicate code / repeated patterns |
| (AI summarizes findings into actionable guidance) | - |

**Frontend**
| Tool | Why |
|---|---|
| React 18 + Vite | Minimal SPA (decision 3); fast dev server, simple build. |
| React Router | Client-side routing for the few views. |

**Dev / quality (Standard §1, §4)**
| Tool | Why |
|---|---|
| pytest (+ httpx test client) | Tests; domain core tested first with no DB. |
| ruff | Lint + format (single fast tool). |
| Makefile | The local operating contract - single command surface (Standard §4). |
| Secret-scanning kit (`Docs/SECRET_SCANNING_KIT.md`) | Drop-in, zero-dep secret scanner (git hooks + optional gitleaks + CI backstop) for The Tacit's own repo; the `make secret-scan` target wires to it (Standard §3). Also the blueprint for future Capability F + the Bootstrapper. |

**Not dependencies (conceptual only):** AWS `awslabs/aidlc-workflows` (inspiration), the `Tools.md` ADO collectors (blueprint for the future Azure DevOps adapter).

## 8. Suggested Python architecture

- **API layer** - FastAPI routers (`auth`, `tenants`, `projects`, `pull_requests`, `releases`, `policy`, `ai`, `scans`, `pr_history`, `writes`, `pipelines`, `bootstrap`, `signals`, `knowledge`); Pydantic schemas; serves the React SPA via CORS.
- **Auth layer (Capability K)** - built-in email + password login (hashed with bcrypt/argon2), session/token issuance, role enforcement as a dependency on protected routes; resolves the calling tenant + user. Sits behind its own boundary so SSO/OIDC can replace the credential check later without touching the rest.
- **Domain / policy layer** - pure Python policy engine + versioning; zero framework/DB imports; the safety core, unit-tested in isolation.
- **Service layer** - orchestrates domain + persistence + AI; owns transitions; writes AuditEvents; enforces tenant scoping.
- **Persistence layer** - SQLAlchemy 2.0 + Alembic on SQLite now (Postgres later via engine URL); repository pattern; tenant_id filter on all queries.
- **AI adapter** - `AIAssistant` port; Anthropic Claude adapter (`claude-opus-4-8`) + deterministic fake for tests; non-blocking to the gate. **Resolves the calling tenant's own key** (decrypt-on-use from `Tenant.anthropic_key_encrypted` via the env master key); no key → returns "AI unavailable" cleanly, never errors the request.
- **Source-control adapter** - `SourceControlPort`; **GitHub adapter (read + governed write)** via a GitHub App + deterministic fake; credential from env/secrets store via pointer. **Read** side non-blocking (degrade to last-known + manual). **Write** side: every call engine-gated, dry-run-able, idempotent, audited (`GitHubWrite`); irreversible actions require a human trigger; kill switch + rate limit.
- **Scanner adapter** - `ScannerPort` (Capability F); wraps gitleaks/ruff/vulture/jscpd + the secret-scanning kit; deterministic findings, AI summarizes; results stored as `ScanFinding`.
- **Pipeline adapter** - `PipelinePort` (Capability H); GitHub Actions adapter + fake; **reads** pipeline runs (status/stage/coverage/history → gate inputs + risk signals) and **triggers** them via the governed write path (H uses G). Never runs builds - The Tacit governs, GitHub Actions executes.
- **Bootstrapper** - templates the standard repo skeleton + secret-scanning kit + standard CI config (H) + tenai-infra skills (I); writes via the governed write path (E uses G).
- **Skill-signal adapter** - `SkillSignalPort` (Capability I); inbound API endpoints that tenai-infra skills POST to (`register-push`, `proof-of-work`, `sync-log`); signals are persisted as `SkillSignal` and treated as **claims to verify**, fed to the engine as inputs - never as gate overrides.
- **Knowledge layer** - `KnowledgePort` (Capability J); ingests experience (any form) → `KnowledgeEntry`; recall via search (text now, semantic/embeddings later) + AI summarization; surfaced at bootstrap and at risky PR/release moments. Recall is advisory - never a gate result.
- **UI** - React SPA consuming the REST API; clean/credible on a component library + consistent design system (Decision 3a), rich dashboards deferred to post-MVP.

Key principle: **the policy engine has no I/O.** AI/Git/Scanner/DB sit behind ports; the deterministic core stays pure and testable. The GitHub adapter feeds *facts* into the engine and only *acts* when the engine authorizes it; it never makes the decision.

## 9. Suggested folder structure

```
the-tacit/
├── backend/
│   ├── app/
│   │   ├── main.py                 # FastAPI app factory (+ CORS for SPA)
│   │   ├── api/                    # routers: tenants, projects, pull_requests, releases, policy, ai, scans, writes
│   │   ├── domain/                 # PURE: policy engine, versioning, branch rules, blockers, write-authorization
│   │   │   ├── policy/             # pr_readiness.py, promotion.py, release_gate.py, write_gate.py
│   │   │   └── versioning.py
│   │   ├── models/                 # SQLAlchemy ORM (tenant_id on tenant-scoped tables)
│   │   ├── schemas/                # Pydantic request/response
│   │   ├── services/               # orchestration + audit + tenant scoping
│   │   ├── repositories/           # data access (swappable backend)
│   │   ├── auth/                   # built-in login (email+password, hashing), sessions, role enforcement (Capability K)
│   │   ├── ai/                     # AIAssistant port, anthropic adapter, fake adapter
│   │   ├── sourcecontrol/          # SourceControlPort, github adapter (read + governed write via GitHub App), fake
│   │   ├── scanner/                # ScannerPort, gitleaks/ruff/vulture/jscpd wrappers, fake (Capability F)
│   │   ├── pipeline/               # PipelinePort, GitHub Actions adapter (read + trigger), fake (Capability H)
│   │   ├── bootstrap/              # repo-skeleton templates + secret-scanning kit + CI config + tenai-infra skills (E)
│   │   ├── skillsignal/            # SkillSignalPort + inbound endpoints for tenai-infra skill signals (Capability I)
│   │   ├── knowledge/              # KnowledgePort + ingest/recall, search/embeddings, AI summarization (Capability J)
│   │   └── core/                   # config, db session, settings (pointers only, no secrets)
│   ├── alembic/                    # migrations
│   ├── tests/                      # domain tests first (no DB), then API/integration
│   ├── seeds/                      # Modo Compass seed data from the tracker
│   ├── Makefile                    # local operating contract (Standard §4)
│   └── pyproject.toml
├── frontend/                       # React SPA (Decision 3a)
│   ├── src/                        # dashboard, PR readiness, release workflow, env/log, scan-findings, pipeline, knowledge views
│   └── package.json
├── Docs/                           # reference material (gitignored): Standard, Tools.md, tracker, SECRET_SCANNING_KIT, reference/tenai-infra
├── AGENTS.md                       # project conventions (Standard §1)
├── inception.md · elaboration.md · OVERVIEW.md   # the plan
└── README.md
```

Honors the Standard: `AGENTS.md` at root (§1), `Makefile` as the single command surface (§4). All 13 `backend/app/` packages above map 1:1 to the capabilities (A-J) and ports in §8.

## 10. Future integration plan

> **Note:** Capabilities **E** (bootstrapper), **F** (scanner), and **G** (GitHub write-back) were promoted **into v1** (Decision 7) - see §2. They are no longer future items. What remains genuinely future is below; the write-access guardrails (§10c) are retained because v1's write capability is built *following* them.

### 10b. Genuinely future (post-v1)

- **Azure DevOps adapter** behind the same `SourceControlPort` (GitHub ships in v1); the `Tools.md` PR Feedback Collector / PR Reviewer are the ADO-adapter blueprint (unresolved-comment detection maps to our "comments resolved/answered" rule).
- **Real-time sync** - upgrade v1's on-demand pull to background polling and/or GitHub webhooks for always-fresh state.
- **Postgres migration**, **notifications delivery**, **rich dashboards** - listed below / in §13.
- **SSO / OIDC** - v1 ships built-in email + password auth (Capability K); company SSO (Google/GitHub/Microsoft) is the later upgrade, designed so it slots in without a rewrite.

### 10c. Write-access guardrails (followed within v1)

v1 includes governed GitHub write (Capability G). Writes are unforgiving (a bug can merge unreviewed code or spam a repo), so the capability is built **following these guardrails and the tiered order** - earned incrementally during construction, not switched on at once.

**Guardrails (apply to every write):**
- **GitHub App, not a personal token** - fine-grained, per-repo, per-action, short-lived permissions; least privilege per action (a commenter can't merge).
- **Engine-gated** - no write happens unless the deterministic policy engine allows it (merge only on `READY`; production release only on joint approval). Writes are the *consequence* of a passed gate, never independent.
- **Human-in-the-loop for irreversible writes** - system prepares, a human triggers merge / production release / repo scaffold (keeps the "humans own approvals" principle).
- **Dry-run + idempotency** - every write previewable before real; retries never double-act (mirror the `Tools.md` PR Reviewer `--dry-run`).
- **Audit-on-write** - the `GitHubWrite` record: who triggered, payload sent, GitHub response, result.
- **Rollback path, rate limits, kill switch** - define the undo before the write; cap writes/min; instant disable without a deploy.
- **Stay behind `SourceControlPort`** - so Azure DevOps write-back is a sibling adapter, not a rewrite.

**Guardrails (apply to every write):**
- **GitHub App, not a personal token** - fine-grained, per-repo, per-action, short-lived permissions; least privilege per action (a commenter can't merge).
- **Engine-gated** - no write happens unless the deterministic policy engine allows it (merge only on `READY`; production release only on joint approval). Writes are the *consequence* of a passed gate, never independent.
- **Human-in-the-loop for irreversible writes** - system prepares, a human triggers merge / production release / repo scaffold (keeps the "humans own approvals" principle).
- **Dry-run + idempotency** - every write previewable before real; retries never double-act (mirror the `Tools.md` PR Reviewer `--dry-run`).
- **Audit-on-write** - extend `AuditEvent`: who triggered, payload sent, GitHub response, result.
- **Rollback path, rate limits, kill switch** - define the undo before the write; cap writes/min; instant disable without a deploy.
- **Stay behind `SourceControlPort`** - so Azure DevOps write-back is a sibling adapter, not a rewrite.

**Tiered rollout (each tier ships and proves itself before the next):**
| Tier | Writes | Risk | Trigger |
|---|---|---|---|
| **A. Foundation** | *none yet* - GitHub App, least-privilege perms, audit-on-write, dry-run machinery | - | build the safe machinery first |
| **B. Reversible** | post PR comments / status checks | low | engine-gated, can be automatic |
| **C. Structural** | open PRs, apply labels, create branches | medium | engine-gated |
| **D. High-stakes** | merge PRs (on `READY`), scaffold repos (Capability E Bootstrapper) | high | human-triggered |
| **E. Production** | execute production release / promotion | highest | joint-approval-gated + human-triggered |

**The line that must never blur:** a write that can happen without the engine's blessing breaks the entire safety story. Value here is *governed* action, not *autonomous* action.
- **Rich UI / dashboards** - charts and trend views (release frequency, most-hit blockers - the `Tools.md` "Trend Dashboard" idea), filtering, real-time updates. v1 ships a clean functional SPA (Decision 3a); the React + REST foundation grows into this without a rewrite.
- **Notifications delivery** (Telegram/Slack `#MY-release` pattern) - v1 only generates the text.
- **Postgres migration** - isolated to one config value + Alembic.
- **AIDLC inspiration only** - AWS `awslabs/aidlc-workflows` informs concepts, never a dependency.

## 11. Risks & open questions

**Risks**
- AI scope creep into the gate → `AiArtifact` never read by the engine; engine has no AI import.
- **GitHub coupling** → engine stays source-agnostic (takes facts, not a GitHub object); adapter behind `SourceControlPort`; fake adapter keeps tests/offline dev working with no network or token.
- **GitHub failure/rate-limits** → on-demand calls degrade to last-known + manual fields, never crash the gate; `last_synced_at` shown so staleness is visible.
- **GitHub token handling** → token referenced by pointer (env/secrets store), never in repo or DB; same pointer-only test as other credentials.
- **Per-tenant Anthropic key (softened rule, accepted)** → unlike the GitHub token, the team's Anthropic key is stored **encrypted in the DB** (teams self-serve via UI). This is a deliberate exception to "pointer-only." Mitigations: AES-at-rest; the **master encryption key lives only in the server env** (never DB/repo); the key is never logged and never returned by any API (write-only/replace from the client's view); decrypt only at call time. Residual risk: master-key leak exposes all stored team keys - operator must protect it like any production secret.
- **Field gaps GitHub can't fill** → `touches_sensitive_surface`, description-quality, and *all* release approvals/rollback stay human/AI-set. "GitHub-powered," not "fully hands-off."
- **Scope risk (the big one, accepted)** → v1 grew from 2 to **6 capabilities** incl. governed write + CI/CD orchestration (Decisions 7, 9). This is a much larger build and v1 is no longer read-only. Mitigation: build in the §12 order - read-only governance core (+ pipeline-read) proven *first*, governed writes + pipeline-trigger last; each capability behind its own port; ship Part 1 as a usable product even if later parts slip.
- **CI/CD: govern, don't run (boundary risk)** → temptation to creep into running builds/hosting runners. Mitigation: hard boundary - `PipelinePort` only reads + triggers; GitHub Actions executes. **Deploy-authority availability:** once a pipeline can't deploy without The Tacit's OK, The Tacit downtime blocks deploys - so that tier raises the availability bar (fail-safe default + the kill switch must not strand deploys). Flagged for the security/ops review before the deploy-authority tier goes live.
- **Governed write risk** → a write bug can merge unreviewed code or spam a repo. Mitigation: the §10c guardrails are mandatory - GitHub App least-privilege, engine-gated, human-triggered for irreversible actions, dry-run + idempotency + kill switch, `GitHubWrite` audit. No write bypasses the engine.
- **Security profile** → as the company's main tool with write access, v1 warrants a real security review and tighter access control (AuthN/AuthZ) before high-stakes write tiers (D/E) go live.
- **Scanner false positives** → wrap precision-tuned tools (the secret kit is tuned for near-zero FP); AI summarizes, humans triage; findings are advisory, never auto-block beyond the existing secret-scan check.
- Secrets leakage → schema has no raw credential fields, only `*_pointer` strings (GitHub App install) + the one encrypted Anthropic key; a test asserts this.

**Open questions:** none blocking. Implementation-time details: GitHub App permission scopes per write tier, how check-runs map to "required checks," scanner tool versions/config, sensitive-surface flag UX, SPA styling.

## 12. Step-by-step build plan

Each phase independently demonstrable. Tests-first on the domain core (Standard §1). **Order is deliberate, safe-core-first:** foundations + the pure governance engine + **authentication** come first (everything attributes to a user); then the read-only data + adapters; then governed writes (G) and pipeline-trigger (H) tiered per §10c; then the bootstrapper (E), UI, and finally the interop + knowledge layers (I, J). Each phase builds on solid ground below it.

**Part 1 - Governance core + auth (safe foundation)**
1. **Foundations** - scaffold backend/frontend, `pyproject`, `Makefile`, `AGENTS.md`, FastAPI app factory + CORS, config (no secrets), SQLite + Alembic baseline, tenant model. **Wire the `Makefile` `secret-scan` target to the secret-scanning kit (`Docs/SECRET_SCANNING_KIT.md`)** - protect The Tacit's own repo before any token/key code lands.
2. **Auth & roles (Capability K)** - `auth/` package: email + password login (hashed), sessions/tokens, `User` model with role, role-enforcement dependency for protected routes, tenant resolution on login. Built early because every later action and approval is attributed to the authenticated user. SSO-ready boundary, email+password for now.
3. **Domain core (pure, no I/O)** - branch-policy, versioning, PR-readiness (incl. sensitive-surface → risky), promotion, release-gate, **and the write-authorization gate (`write_gate.py`)** that later authorizes every GitHub write; typed blockers. Unit-tested exhaustively before any DB.
3. **Persistence & models** - SQLAlchemy entities (§6, incl. `ScanFinding`, `GitHubWrite`, `PipelineRun`) with tenant scoping, repositories, migrations; seed Modo Compass data.
4. **Tenant, project & PR APIs** - create project (GitHub repo + GitHub-App install pointer)/environments/policy under a tenant; all routes auth-protected (Capability K); expose computed readiness + blockers.
5. **GitHub adapter - READ** - `SourceControlPort` + **fake adapter first** (engine + APIs testable with no credential), then real read side (list PRs, fetch branches/description/checks/review threads); on-demand sync; graceful degradation + `last_synced_at`.
6. **Release APIs** - create release, record staging validation + joint approval (by authenticated Tech Lead + Project Owner), enforce gate, execute production (record only at this stage), auto-update Environments + Release Log, compute next version/codename.
7. **AI adapter (assist-only, per-tenant key)** - `AIAssistant` port + Anthropic adapter + fake; tenant key set/replace (encrypt at rest, never return); resolve/decrypt per call; no key → AI disabled. Wire AI features incl. **AI-first sensitivity pre-fill** (`sensitive_suggested_by_ai` → human confirms `touches_sensitive_surface`); verify none touch gate state.

**Part 2 - Read-only adapters (Scanner F + Pipeline-read H)**
8. **Scanner + historical PR audit** - `ScannerPort` + wrappers (gitleaks/ruff/vulture/jscpd) + secret-scanning kit; run-scan endpoint; persist `ScanFinding`; AI summarizes findings. **Plus historical PR audit** - pull a repo's full PR history via the GitHub API (read), persist `PrHistoryRecord`, flag past hygiene issues (merged-without-review, recurring problems), produce an audit report. Read-only - no GitHub writes; mind rate limits (page + cache).
9. **Pipeline - READ (H)** - `PipelinePort` + GitHub Actions adapter (read) + fake; pull `PipelineRun` status/stage/coverage/history; feed pipeline health into the engine as a **gate input** (red pipeline blocks promotion) + **risk signal** (passed-after-retries). Still read-only.

**Part 3 - Governed write (Capability G + Pipeline-trigger H), tiered per §10c**
10. **Write foundation (Tier A)** - GitHub App auth (least-privilege), `GitHubWrite` audit, **dry-run mode**, idempotency, rate limit + kill switch. No real writes yet - just the safe machinery, fully tested against the fake.
11. **Reversible writes (Tier B/C)** - engine-gated PR comments/status checks, then labels/branches/open-PR. Auto-allowed where reversible.
12. **High-stakes writes (Tier D/E) + pipeline trigger** - merge on `READY` and production promotion - **engine-gated + human-triggered**; **trigger the deploy pipeline on the staging gate passing** and expose the **deploy-approval authority** endpoint (pipeline asks "may I deploy?"); full audit + rollback path.

**Part 4 - Bootstrapper (E) + UI + interop + knowledge**
13. **Project bootstrapper** - `bootstrap/` repo-skeleton templates + secret-scanning kit + **standard CI config (`.github/workflows/` running the standard Makefile targets)**; scaffold into a new repo via the governed write path (human-triggered); surface recommendations.
14. **React SPA (quality bar = Decision 3a)** - component library + consistent design system, color-coded states; **login + role-aware UI (Capability K)**; projects dashboard, PR readiness (GitHub-synced, blockers, AI sensitivity pre-fill + confirm), release workflow, Environments/Release Log, scan-findings view, **pipeline status/history view**, write/dry-run + approval controls, announcement preview. Rich dashboards deferred.
15. **tenai-infra interop (Capability I)** - `SkillSignalPort` + inbound endpoints for `register-push`/`proof-of-work`/`sync-log`; persist `SkillSignal`; **verify claims** against GitHub/the engine (never trust blindly); **plus launch (Option A):** a "start coding session" endpoint that calls tenai-infra's trigger (if exposed). The Tacit governs tenai-infra's agent output and can launch sessions; it does not rebuild the mesh.
16. **Tacit knowledge (Capability J, the namesake)** - `KnowledgePort` + ingest endpoints (retro/incident/decision/doc) + structured-signal capture; `KnowledgeEntry` store; recall (text search now, semantic/embeddings later) + AI summarization; surface relevant lessons at bootstrap and at risky PR/release moments. Recall is advisory, never a gate result.
17. **Audit & polish** - AuditEvent + `GitHubWrite` on every transition/write, end-to-end walkthrough on seeded Modo data + a live GitHub repo (read, scan, pipeline read+trigger, governed write) + a tenai-infra agent signal + a recalled lesson, README + demo script.

## 13. Scalability

How the system grows beyond the first team and small load - the design choices that make it scalable, the known limits, and the explicit trigger for each upgrade. (One of the stated product principles: "scalable beyond one project.")

### Designed-in for scale (built in v1)
| Concern | How it scales | Where |
|---|---|---|
| More teams | Multi-tenant from day one; `tenant_id` isolation on every scoped row | Decision 1, §6 |
| More projects | Data model is tenant -> project -> {envs, PRs, releases}; no single-project assumptions | §6 |
| Bigger database | SQLAlchemy ORM keeps storage DB-agnostic; SQLite -> PostgreSQL is one engine-URL change + Alembic | §7b, §8, §10 |
| New integrations | GitHub/AI sit behind ports (`SourceControlPort`, `AIAssistant`); add Azure DevOps or another provider without touching the core | §8 |
| Growing rules | Pure-function policy engine, isolated and exhaustively tested; extend rules without destabilizing I/O | §8 |
| Stateless API | FastAPI holds no per-request server state; can run multiple instances behind a load balancer once on Postgres | §8 |

### Known limits and the upgrade trigger (the honest part)
| Limit in v1 | Why it's fine for the MVP | Trigger to upgrade | Upgrade |
|---|---|---|---|
| **SQLite** is single-writer | Light, mostly-read load from a few teams is fine | Concurrent write contention / multiple API instances needed | Switch to PostgreSQL (one URL change; already designed for) |
| **On-demand GitHub pull** | Few projects, refreshed when viewed | Many projects refreshing at once hits GitHub rate limits | Add background polling, then webhooks (push) - already the §10 path |
| **No caching / indexes tuned** | Small data volumes | Slow list/log queries as history grows | Add DB indexes on hot columns (`tenant_id`, `project_id`, `last_synced_at`); cache GitHub responses |
| **AI calls are synchronous** | Assist features are occasional | Heavy AI use blocks requests | Move AI calls to background jobs / a queue |
| **Single process** | One instance serves an MVP-sized userbase | Userbase outgrows one node | Horizontal scale: multiple stateless API instances + Postgres + a shared secrets store |

### How to verify it's scaling (signals to watch)
- DB write latency / "database is locked" errors -> time to move off SQLite.
- GitHub `403 rate limit` responses -> time for polling/webhooks + caching.
- p95 API latency on list/log endpoints climbing -> add indexes / caching.
- Single instance CPU-bound -> go horizontal (the API is already stateless to allow this).

**Bottom line:** the v1 *architecture* is scalable - stateless API, ORM, adapter ports, tenant isolation - so growth is a series of well-understood swaps (SQLite->Postgres, on-demand->webhooks, single->multi-instance), not a rewrite. v1 ships the small end of that path on purpose (MVP); the triggers above tell you when to take each next step.
