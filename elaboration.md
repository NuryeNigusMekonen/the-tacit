# The Tacit - Elaboration (detailed functional requirements)

Companion to `inception.md`. Where `inception.md` is the agreed intent, this document is the buildable spec: acceptance criteria, the blocker catalog, state machines, and the API contract. It is the reference for construction. All rules trace to the Tenacious Development Standard (cited as §n).
---

## 1. Acceptance criteria per capability

Written as testable statements. Each becomes one or more domain unit tests.

### 1.1 Project setup
- AC-P1: A project can be created with name, GitHub repo (`owner/repo`), GitHub token pointer, owner, versioning scheme, `has_staging`, and an ordered codename pool.
- AC-P2: A project belongs to exactly one tenant; all reads/writes are tenant-scoped.
- AC-P3: Creating a project provisions its environments per `has_staging`: `dev, staging, production` (or `dev, production` when false).
- AC-P4: The GitHub token is never stored - only a pointer (env var name). Storing a raw token is rejected.

### 1.2 Branch policy (§2)
- AC-B1: `feature/*` may only target `dev`.
- AC-B2: Allowed promotions are exactly `dev→staging` and `staging→production` (or `dev→production` when `has_staging=false`).
- AC-B3: Any skipped stage (e.g. `dev→production` when staging exists) is rejected with `PROMOTION_SKIPS_STAGE`.
- AC-B4: Any backward promotion is rejected with `PROMOTION_BACKWARD`, **except** a hotfix reconciliation (production→staging and production→dev), which is allowed.
- AC-B5: A merge into a protected branch without a PR is rejected with `PROTECTED_BRANCH_REQUIRES_PR`.

### 1.3 PR readiness (§2 + decision 4)
- AC-R1: A PR is `READY` iff all hard checks pass AND it does not touch a sensitive surface.
- AC-R2: A PR is `RISKY` iff all hard checks pass AND `touches_sensitive_surface = true`.
- AC-R3: A PR is `BLOCKED` iff any hard check fails; the response lists every failing blocker (not just the first).
- AC-R4: A PR is `MERGED` only after a human merge action; the engine never auto-merges.
- AC-R5: Hard checks: valid source→target, description present & non-trivial, automated review ran, all review comments resolved/answered, required checks passed.
- AC-R6: GitHub-pulled fields (branches, description, checks, review threads) and manual fields (`touches_sensitive_surface`) combine into one readiness evaluation; the engine is identical regardless of data source.
- AC-R7: If GitHub data is stale or unavailable, evaluation still runs on last-known + manual fields and surfaces `last_synced_at`; it never errors.

### 1.4 Release management (§7)
- AC-L1: A release targets one environment and carries version, type, changes, rollback plan.
- AC-L2: A production release is `BLOCKED` unless the corresponding staging release carries complete joint approval (Tech Lead AND Project Owner).
- AC-L3: Any release missing a rollback plan is `BLOCKED` with `MISSING_ROLLBACK_PLAN`.
- AC-L4: A production release whose source is not staging (when staging exists) is `BLOCKED` with `RELEASE_NOT_FROM_STAGING`.
- AC-L5: Production carries no new approval - it is execution only; approval is recorded at staging.
- AC-L6: On successful release, the system (a) updates the Environments view, (b) appends a Release Log entry, (c) generates announcement text.
- AC-L7: `first_release` type is accepted at most once per product; a second is rejected with `FIRST_RELEASE_ALREADY_USED`.

### 1.5 Versioning (§7 + Conventions sheet)
- AC-V1: Given current version + type, the engine returns the next version: Major bumps major & resets minor/patch; Minor bumps minor & resets patch; Patch bumps patch.
- AC-V2: A Major release consumes the next unused codename from the project's pool; Minor/Patch carry no codename.
- AC-V3: If the codename pool is exhausted on a Major, the release is flagged `CODENAME_POOL_EXHAUSTED` (warning, not a hard block - human decides).

### 1.6 AI assistance (assist-only)
- AC-A1: No AI output ever changes a readiness or approval state (verified by the engine having no AI import).
- AC-A2: A tenant with no Anthropic key configured has AI features disabled; all deterministic features still work.
- AC-A3: A tenant's Anthropic key is stored encrypted; the API never returns it (write/replace only).
- AC-A4: An AI call failure degrades gracefully ("AI unavailable") and never errors the underlying request.
- AC-A5: For sensitivity, AI goes first: it pre-fills a suggested `touches_sensitive_surface` (stored in `sensitive_suggested_by_ai`). The gate uses the **human-confirmed** value, not the AI suggestion. Until a human confirms, the suggestion is shown as unconfirmed and the human-confirmed field defaults to the suggestion. No AI key → no suggestion; human sets it directly. The engine cannot read the AI suggestion field (AC-A1 still holds).

### 1.7 GitHub governed write (Capability G)
- AC-W1: No GitHub write executes unless the policy engine (`write_gate`) authorizes it for that action + state (e.g. merge only when the PR is `READY`; production promotion only when the staging release is `JOINTLY_APPROVED`).
- AC-W2: Irreversible writes (merge, production promotion, repo scaffold) require an explicit human trigger; reversible writes (comment, label) may be automatic.
- AC-W3: Every write is dry-runnable - a preview returns exactly what *would* be sent without performing it.
- AC-W4: Writes are idempotent by `idempotency_key`; a retry never double-acts.
- AC-W5: Every write records a `GitHubWrite` (action, tier, triggered_by, engine_decision, dry_run, github_response, status).
- AC-W6: A kill switch disables all writes instantly (config flag, no deploy); rate limit caps writes/min.
- AC-W7: Auth is a least-privilege GitHub App referenced by pointer; the credential is never stored in repo or DB.

### 1.8 Code-quality & security scanner (Capability F)
- AC-F1: A scan produces `ScanFinding` rows categorized as secret / unused / duplicate / defect, each with file, line, tool, severity, message.
- AC-F2: Findings are advisory: they do not change PR readiness except the existing secret-scan path (a confirmed secret feeds `REQUIRED_CHECKS_FAILING`).
- AC-F3: Each scanner runs behind `ScannerPort`; a fake scanner lets the feature be tested with no external tools installed.
- AC-F4: AI may add an `ai_explanation` to a finding; the deterministic tool's finding is the authoritative record.
- AC-F5 (historical PR audit): The scanner can retrieve a repo's full PR history via the GitHub API (read-only) and persist a `PrHistoryRecord` per past PR (title, author, was_reviewed, comments_resolved, checks_passed, merged, dates).
- AC-F6: The audit flags past hygiene issues (e.g. merged-without-review, secret-in-history, recurring problem patterns) and produces a report.
- AC-F7: The audit reads only (PR reviews come from the API, not just a clone); it never writes to GitHub. Full-history pulls page and cache to respect rate limits.
- AC-F8: Audit results can seed `KnowledgeEntry` (J) as lessons.

### 1.9 Project bootstrapper (Capability E)
- AC-E1: Bootstrapping scaffolds the standard skeleton (folders, `.gitignore`, `AGENTS.md`, `Makefile`, `.env.example`, branch protections) into the target repo via the governed write path (AC-W*).
- AC-E2: Bootstrapping ships the secret-scanning kit into the new repo.
- AC-E3: Bootstrapping is human-triggered (high-stakes write tier) and fully audited.
- AC-E4: The bootstrapper surfaces per-project recommendations (what else to add) without forcing them.
- AC-E5: The bootstrapper includes a standard CI config (`.github/workflows/`) that runs the standard Makefile targets (Capability H).

### 1.10 CI/CD orchestration (Capability H)
- AC-H1: The Tacit reads pipeline runs from the provider (`PipelineRun`: status, failing stage, test count, coverage, retry count); it never executes builds.
- AC-H2: Pipeline health is a gate input - a red latest pipeline on the source environment blocks promotion (a named blocker); passed-after-retries is surfaced as a risk signal.
- AC-H3: Triggering a pipeline is a governed write (AC-W*): engine-gated, audited, dry-runnable; the deploy pipeline is triggered when the staging gate passes.
- AC-H4: Deploy-authority - a pipeline may query "may I deploy to <env>?"; the engine answers from approvals + rollback plan + staging-validated; a `no` is authoritative.
- AC-H5: `PipelinePort` has a fake so the feature is testable with no real CI provider; the engine never imports the pipeline adapter.

### 1.11 tenai-infra interop (Capability I)
- AC-I1: tenai-infra skills (`register-push`, `proof-of-work`, `sync-log`) POST to inbound endpoints behind `SkillSignalPort`; each is persisted as a `SkillSignal`.
- AC-I2: A skill signal is a **claim**, not an authoritative result - the engine treats it as an input to verify (cross-check against GitHub where possible); `verified` records the outcome. A signal alone never sets a readiness/approval state.
- AC-I3: `register-push` triggers a PR sync; `proof-of-work` (PROOF.md) is surfaced as readiness evidence; `sync-log` entries land in the audit trail.
- AC-I4: Any write driven by a skill signal goes through the governed-write guardrails (AC-W*).
- AC-I5: The bootstrapper (E) can install the tenai-infra `.agents/skills/` set into a new repo.
- AC-I6: The Tacit does not implement mesh/remote-access/agent-dispatch - it orchestrates, never reimplements tenai-infra.
- AC-I7 (launch, Option A): The Tacit can request tenai-infra to start a coding session - the user supplies/pre-fills inputs (project, repo, device, task, chosen agent: Claude Code / Gemini / Codex) and triggers it; The Tacit calls a tenai-infra launch trigger and shows status. The agents are tenai-infra's; The Tacit does not host or run them.
- AC-I8: Launch requires tenai-infra to expose a trigger (API/command); inputs are passed securely (pointer-only, no stored secrets). If no trigger is available, launch is disabled and only the inbound/govern direction (AC-I1..I4) operates.

### 1.12 Tacit knowledge / organizational memory (Capability J)
- AC-J1: Experience can be ingested in multiple forms (retro, incident, decision, doc, lesson) and from structured signals already in the system (release logs, PROOF.md, scan findings, audit events), stored as `KnowledgeEntry` (per tenant).
- AC-J2: Recall returns relevant past entries for a query/context (text search in v1; semantic/embeddings later); AI may summarize and extract patterns.
- AC-J3: Knowledge recall is **advisory** - it informs humans/AI; it never sets or overrides a readiness/approval/gate result (assist-only rule, AC-A1 analogue).
- AC-J4: Relevant lessons are surfaced at the right moment - at project bootstrap (E) and at risky PR/release situations.
- AC-J5: Knowledge is tenant-isolated; cross-project recall stays within a tenant.

### 1.13 Authentication & roles (Capability K)
- AC-K1: A user signs in with email + password; passwords are stored only as a secure hash (bcrypt/argon2), never plain, and never returned by any API.
- AC-K2: A successful login resolves the user's tenant and role and issues a session/token used for the API and SPA.
- AC-K3: Every user has a role (`tech_lead | project_owner | engineer | devops`); protected routes enforce the role.
- AC-K4: The staging release gate checks the **authenticated user's** role - only a real Tech Lead and a real Project Owner can record the joint approval (AC-L2); a user cannot approve in a role they don't hold.
- AC-K5: Approvals and `AuditEvent`s are attributed to the authenticated user id - no shared logins, no "select who you are."
- AC-K6: Users are tenant-scoped; a login can only access its own tenant's data (tenant isolation, rule 4).
- AC-K7: The auth layer is isolated so SSO/OIDC can replace the credential check later without changing the rest (email + password in v1).

---

## 2. Blocker catalog (the heart of the deterministic core)

Every blocker has a stable `code`, a human `message`, and a `surface` (pr | release). The engine returns a list; AI may *explain* a code but never invents one.

| Code | Surface | Human message |
|---|---|---|
| `INVALID_BRANCH_TARGET` | pr | Source branch may not target this branch under the project's policy. |
| `PROTECTED_BRANCH_REQUIRES_PR` | pr | This branch is protected; changes require a pull request. |
| `MISSING_DESCRIPTION` | pr | The PR has no description of what changed and why. |
| `TRIVIAL_DESCRIPTION` | pr | The description restates the diff; explain what & why. |
| `AUTOMATED_REVIEW_NOT_RUN` | pr | Automated review (CodeRabbit/Copilot) has not run on this PR. |
| `REVIEW_COMMENTS_UNRESOLVED` | pr | One or more automated-review comments are neither fixed nor answered. |
| `REQUIRED_CHECKS_FAILING` | pr | One or more required checks (build/lint/test/secret-scan) are not passing. |
| `PROMOTION_SKIPS_STAGE` | release | This promotion skips a required stage. |
| `PROMOTION_BACKWARD` | release | Promotion flows backward and is not a hotfix reconciliation. |
| `RELEASE_NOT_FROM_STAGING` | release | Production may only receive what was validated in staging. |
| `STAGING_NOT_VALIDATED` | release | Staging validation is not complete for this version. |
| `APPROVAL_TECH_LEAD_MISSING` | release | Tech Lead approval is missing at the staging gate. |
| `APPROVAL_PROJECT_OWNER_MISSING` | release | Project Owner approval is missing at the staging gate. |
| `MISSING_ROLLBACK_PLAN` | release | This release does not name a rollback plan. |
| `FIRST_RELEASE_ALREADY_USED` | release | A First Release already exists for this product. |
| `PIPELINE_NOT_GREEN` | release | The latest CI pipeline on the source environment is not passing (Capability H). |

Warnings (non-blocking, surfaced but do not stop the gate): `CODENAME_POOL_EXHAUSTED`, `GITHUB_DATA_STALE`, `TOUCHES_SENSITIVE_SURFACE` (drives RISKY, not BLOCKED), `PIPELINE_PASSED_AFTER_RETRIES` (risk signal).

---

## 3. State machines

### 3.1 PullRequest.readiness_state
States: `BLOCKED`, `RISKY`, `READY`, `MERGED`.

| From | Event | To |
|---|---|---|
| (new) | evaluate, hard check fails | BLOCKED |
| (new) | evaluate, all hard pass + sensitive | RISKY |
| (new) | evaluate, all hard pass + not sensitive | READY |
| BLOCKED | re-evaluate, now all pass (not sensitive) | READY |
| BLOCKED | re-evaluate, now all pass (sensitive) | RISKY |
| READY / RISKY | re-evaluate, a check regresses | BLOCKED |
| READY / RISKY | human merges | MERGED |
| MERGED | - (terminal) | - |

Rule: only `READY` or `RISKY` are mergeable; the engine never transitions to `MERGED` on its own (AC-R4).

### 3.2 Release.status
States: `DRAFT`, `BLOCKED`, `READY`, `RELEASED`, `ROLLED_BACK`.

| From | Event | To |
|---|---|---|
| (new) | create | DRAFT |
| DRAFT / BLOCKED | evaluate, a blocker present | BLOCKED |
| DRAFT / BLOCKED | evaluate, no blockers | READY |
| READY | execute (human) | RELEASED |
| RELEASED | rollback invoked (plan executed by humans) | ROLLED_BACK |
| RELEASED | - otherwise terminal | - |

On entering `RELEASED`: update Environments view, append Release Log, generate announcement (AC-L6). Every transition writes an `AuditEvent`.

### 3.3 Staging approval (sub-state of a staging release)
`approval_state`: `PENDING` → `TECH_LEAD_APPROVED` / `OWNER_APPROVED` (either order) → `JOINTLY_APPROVED` (both). Only `JOINTLY_APPROVED` unblocks the downstream production release (AC-L2).

---

## 4. API contract (v1, REST/JSON)

Base path `/api`. All endpoints tenant-scoped via the authenticated tenant context. Errors use a consistent shape: `{ "error": { "code", "message", "blockers"? } }`. Readiness endpoints return `200` with the computed state + blockers (a blocked PR is not an HTTP error - it is a valid evaluated state).

**Auth & users (Capability K)**
- `POST /api/auth/login` - email + password → session/token. → `200 {token}` / `401`
- `POST /api/auth/logout` - revoke the session. → `204`
- `GET /api/auth/me` - the current authenticated user (id, role, tenant). → `200`
- `POST /api/tenants/{id}/users` - create a user with a role (admin/setup). → `201` (password set securely; never echoed)
- (all other routes below require a valid session; the user's role is enforced per route)

**Tenants & settings**
- `POST /api/tenants` - create tenant. → `201 {id, name}`
- `PUT /api/tenants/{id}/anthropic-key` - set/replace the team's Anthropic key (write-only; encrypted at rest). → `204`
- `DELETE /api/tenants/{id}/anthropic-key` - remove the key (disables AI). → `204`

**Projects & environments**
- `POST /api/projects` - create project (+ provisions environments). → `201 {project}`
- `GET /api/projects/{id}` - project detail. → `200`
- `GET /api/projects/{id}/environments` - current versions view (the Environments sheet). → `200 [{name, current_version, codename, last_deployed_at}]`

**Pull requests**
- `POST /api/projects/{id}/pull-requests/sync` - on-demand pull from GitHub; upserts PR records. → `200 {synced, last_synced_at}`
- `GET /api/projects/{id}/pull-requests` - list with computed readiness + blockers. → `200`
- `GET /api/pull-requests/{id}` - detail incl. blockers + `last_synced_at`. → `200`
- `PATCH /api/pull-requests/{id}` - set manual fields (`touches_sensitive_surface`). → `200` (re-evaluates)
- `POST /api/pull-requests/{id}/merge` - record human merge → `MERGED`. → `200`
- `GET /api/pull-requests/{id}/ai/summary` - AI PR summary (or `AI unavailable`). → `200`

**Releases**
- `POST /api/projects/{id}/releases` - create draft release. → `201`
- `POST /api/releases/{id}/evaluate` - compute status + blockers. → `200`
- `POST /api/releases/{id}/approvals` - record an approval `{role, approver}`. → `200`
- `POST /api/releases/{id}/execute` - execute (READY only); updates env view + log + announcement. → `200`
- `GET /api/projects/{id}/release-log` - the Release Log. → `200`
- `GET /api/releases/{id}/ai/notes` - AI release-note draft. → `200`
- `GET /api/releases/{id}/ai/announcement` - AI announcement draft. → `200`

**Policy (read-only introspection)**
- `POST /api/policy/pr/preview` - evaluate hypothetical PR facts without persisting. → `200 {state, blockers}`
- `POST /api/policy/release/preview` - evaluate hypothetical release facts. → `200 {status, blockers}`

**Scanner (Capability F)**
- `POST /api/projects/{id}/scans` - run a scan; persist findings. → `202 {scan_run_id}`
- `GET /api/projects/{id}/scans/{run}/findings` - list `ScanFinding` (filter by category/severity/status). → `200`
- `PATCH /api/findings/{id}` - acknowledge/resolve a finding. → `200`
- `POST /api/projects/{id}/pr-history/audit` - pull + analyze the repo's PR history (read-only). → `202 {audit_run_id}`
- `GET /api/projects/{id}/pr-history` - list `PrHistoryRecord` + audit flags. → `200`

**GitHub governed write (Capability G)**
- `POST /api/pull-requests/{id}/writes/comment` - engine-gated PR comment (supports `?dry_run=true`). → `200`
- `POST /api/pull-requests/{id}/writes/merge` - merge on `READY`; human-triggered, engine-gated, dry-runnable. → `200`
- `POST /api/releases/{id}/writes/promote` - execute production promotion; joint-approval-gated, human-triggered. → `200`
- `GET /api/projects/{id}/writes` - the `GitHubWrite` audit trail. → `200`
- `POST /api/admin/writes/kill-switch` - disable/enable all writes instantly. → `204`

**Bootstrapper (Capability E)**
- `POST /api/projects/{id}/bootstrap` - scaffold the standard skeleton + secret-scanning kit + standard CI config into the repo (human-triggered, dry-runnable). → `200 {written, recommendations}`

**CI/CD orchestration (Capability H)**
- `GET /api/projects/{id}/pipelines` - list `PipelineRun` (status, stage, coverage, history). → `200`
- `POST /api/projects/{id}/pipelines/sync` - pull latest pipeline runs from the provider. → `200`
- `POST /api/releases/{id}/pipelines/trigger` - trigger the deploy pipeline (engine-gated, human-triggered, dry-runnable). → `200`
- `POST /api/projects/{id}/deploy-authority` - pipeline asks "may I deploy to <env>?"; engine answers. → `200 {allowed, blockers}`

**tenai-infra interop (Capability I)**
- `POST /api/signals/register-push` - tenai-infra `register-push` skill posts a push/PR event → triggers a sync. → `202`
- `POST /api/signals/proof-of-work` - posts a PROOF.md reference as readiness evidence. → `202`
- `POST /api/signals/log` - `sync-log` entries → audit trail. → `202`
- `GET /api/projects/{id}/signals` - list received `SkillSignal` (with verified status). → `200`
- `POST /api/projects/{id}/sessions` - launch a tenai-infra coding session (Option A): body = device, task, agent (claude/gemini/codex); The Tacit calls tenai's launch trigger. → `202 {session_ref}` (or `501` if tenai exposes no trigger)

**Tacit knowledge (Capability J)**
- `POST /api/knowledge` - ingest an experience entry (retro/incident/decision/doc/lesson). → `201`
- `GET /api/knowledge/recall?q=...&project=...` - recall relevant entries for a query/context. → `200`
- `GET /api/projects/{id}/knowledge` - list knowledge for a project (+ cross-project tenant lessons). → `200`

---

## 5. Open implementation-time details (non-blocking)

- GitHub auth: start with a personal access token (pointer); GitHub App later.
- Exact mapping of GitHub check-runs → the project's "required checks" set.
- Sensitive-surface UX (v1): **AI pre-fills the suggestion, human confirms** (AI-first). Plain human toggle when no AI key. AI suggestion is stored separately and never read by the engine.
- "Non-trivial description" heuristic: minimum length + not equal to the branch/diff name; refine during build.
