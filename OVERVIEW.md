# The Tacit - One-Page Overview

**Tenacious AI Delivery & Control Tool** - the internal platform that governs how code moves from a developer's branch to a production release, end to end.

## The problem

Today, every Tenacious team ships code on tribal knowledge and a manual spreadsheet. Rules for "is this safe to ship?" live in people's heads - so steps get skipped, approvals forgotten, secrets occasionally leak, every project is set up differently, and there's no audit trail when something breaks. This doesn't scale as we grow.

## What it is (one line)

**The Tacit answers one question for any project - "Can this change safely move from pull request to release?" - and enforces the answer, with a full audit trail, while AI does the busywork.** It turns our development standard from a document people forget into enforced software.

## The end-to-end flow

```
1. SET UP   A team registers a project → The Tacit scaffolds the standard repo
            skeleton + secret-scanning kit + standard CI/CD config into GitHub
            (bootstrapper) - so the pipeline exists and follows the standard
2. READ     It reads their pull requests from GitHub automatically
3. SCAN     It scans the code for secrets, dead code, duplication, defects
4. CI/CD    It reads the pipeline results (build/test/lint) as a gate input -
            a red pipeline blocks promotion; passed-after-retries is a risk signal
5. JUDGE    The rule engine decides: READY / BLOCKED / RISKY - with exact reasons
            (AI pre-fills the sensitivity flag; a human confirms)
6. MERGE    Once READY, it can merge the PR on GitHub - safely, engine-gated
7. PROMOTE  Code moves dev → staging → production (no skipping, no backward)
8. GATE     Production requires Tech Lead + Project Owner approval + a rollback plan;
            a pipeline can ask "may I deploy?" and is refused if the engine says no
9. SHIP     It triggers the deploy pipeline (GitHub Actions runs it), updates the
            release log + environment versions, and drafts the team announcement
10. AUDIT   Every step and every action is logged - who, what, when

CI/CD note: The Tacit GOVERNS the pipeline (scaffolds it, reads it, gates on it,
triggers it, is the deploy-approval authority) - GitHub Actions RUNS it. It never
runs builds itself.
```

## The nine capabilities (v1)

| | Capability | Value |
|---|---|---|
| A | Pull request governance | Clean, reviewed code before merge |
| B | Release management | No unsafe production releases; replaces the spreadsheet |
| C | AI assistance | Auto-writes summaries, release notes, announcements |
| D | GitHub integration | Reads real PRs automatically (read + governed write) |
| E | Project bootstrapper | Every new project starts standard-compliant in one click |
| F | Code & security scanner | Catches secrets, dead code, defects automatically |
| G | Governed write-back | Safely acts on GitHub (comment, merge) when rules pass |
| H | CI/CD orchestration | Governs the deploy pipeline; blocks unsafe deploys |
| I | tenai-infra interop | Governs the output of agents coding from anywhere (mesh/multi-device); does not rebuild that layer |
| J | Tacit knowledge | Captures project experience as reusable organizational memory - the system living up to its name |
| K | Authentication & roles | Built-in login (email + password), per-user roles enforced, so every approval is attributed to a real person; SSO-ready |

## The principle that makes it trustworthy

**Deterministic rules decide; AI only assists; humans own every irreversible action.**
- The rule engine - never AI - makes every safety decision (predictable, testable).
- AI writes and explains, but can never approve, merge, or release.
- No GitHub write happens without the engine's approval; irreversible actions need a human trigger; there is a kill switch.
- It governs the CI/CD pipeline but never runs builds (GitHub Actions does that).

## Why it's the right bet

- **Compounds** - build once, every engagement benefits forever (reusable infrastructure).
- **Encodes our standard** - best practice is enforced, inherited automatically by new hires.
- **Scales with us** - multi-tenant: one instance serves all teams, isolated.
- **Client-facing trust** - a clean audit trail is a professionalism signal that wins and keeps business.
- **Potential product** - other consultancies have this exact pain.

## What it deliberately does NOT do

No running of builds (governs, doesn't replace CI) · no AI deciding anything · no storing secrets (pointers + encryption only) · GitHub-only for now (Azure DevOps later). Focused, not boil-the-ocean.

## How we build it (de-risked)

Safe-core-first, in parts, each independently usable:
**Part 1** Governance core (read-only) → shippable on its own ·
**Part 2** Scanner + historical PR audit + pipeline reading (read-only) ·
**Part 3** Governed writes + pipeline trigger (tiered, guarded) ·
**Part 4** Bootstrapper + UI + tenai-infra interop (I) + tacit-knowledge layer (J) + polish.
Even if only Part 1 ships, we have a working product that replaces the spreadsheet and enforces the rules.

## The value

Real and compounding: saved repetitive setup/release work (scales with project count), prevented incidents (one avoided leak or bad deploy can exceed the build cost), enforced consistency, and auditability. The value concentrates in the cheap governance core (A-D, F); the write/CI-CD capabilities (G, H) are strategic bets earned not front-loaded; the knowledge layer (J) - the namesake - compounds most over time as project experience accumulates.

## Status & the ask

Planning and design are **complete** (full spec, data model, rules, API, build plan). **No code yet** - design-first by choice. **The ask: approve construction, starting with the safe governance core (Part 1)** - the cheapest part that delivers most of the value and proves the concept.

---

*The Tacit turns our development standard into enforced software: it reads each team's GitHub, scans for security issues, and decides - with clear reasons - whether code is clean enough to merge and safe enough to ship, requiring real human approval for production; it automates the busywork with AI, keeps the audit trail that replaces our spreadsheets, and safely governs deployments - while a deterministic engine, never AI, makes every safety decision and humans own every release.*
