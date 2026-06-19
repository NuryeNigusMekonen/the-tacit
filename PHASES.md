# The Tacit - Phased Delivery Plan

A simple breakdown of how The Tacit will be built, phase by phase. Each phase produces something we can show and use on its own.

There are two ways to read this:
- **What the user gets** - the order a person experiences the system, from starting a project to shipping a release.
- **How we build it** - the safe order engineers work in (some user-facing features depend on lower-level pieces being built first).

---

## What the user gets (phase by phase)

### Phase 1 - Project setup (bootstrapping)
A team creates an empty repository, registers it in The Tacit, and clicks one button. The Tacit fills the repo with the standard starter files every project should have: ignore rules, the conventions file, the standard commands, a config template, branch protection, secret scanning, and a ready-to-run test/build pipeline.
**Result:** every new project starts the same way - consistent, safe, and ready - instead of each person setting it up by hand.

### Phase 2 - Pull request checks
The Tacit reads the project's pull requests and decides, for each one, whether it is ready to merge - and if not, exactly why (no description, not reviewed, tests failing, or it touches a sensitive area). AI writes a short summary to help.
**Result:** a clear "ready / blocked / risky" answer for every pull request, with the reasons spelled out.

### Phase 3 - Code and security scan
One click scans a project for problems: exposed passwords or keys, unused code, duplicated code, and other defects. It also reviews the project's past pull requests to show who contributed most, what issues came up most often, and how activity changed over time.
**Result:** a clear report of a codebase's health and history, on demand.

### Phase 4 - Release management
When a team wants to ship, The Tacit makes sure the rules are followed: the change must be approved by both the Tech Lead and the Project Owner, and it must have a rollback plan. It works out the version number, records what shipped, updates which version is live where, and drafts the announcement.
**Result:** nothing reaches production without proper approval, and every release is recorded automatically.

### Phase 5 - Deployment control (CI/CD)
The Tacit checks whether the automated build and tests passed before letting a change move forward, and once a release is approved, it starts the deployment. The actual building and deploying is still done by the existing pipeline; The Tacit controls when it is allowed to run.
**Result:** unsafe deployments are blocked, and approved ones are released smoothly.

### Phase 6 - Acting on the repository safely
The Tacit can take actions on the repository - leave a comment, merge a pull request, start a deployment - but only when the rules allow it. Anything that cannot be undone needs a person to confirm, every action can be previewed first, and everything is recorded.
**Result:** the system can do things for you, safely and with a full record.

### Phase 7 - Coding from anywhere
From the dashboard, a team member can start a coding session on their own device (including a phone) and choose which AI coding assistant to use. When the work comes back, The Tacit checks whether it is safe to ship.
**Result:** start work from anywhere; the system still governs the result.

### Phase 8 - Shared knowledge (the namesake)
The Tacit remembers the lessons from every project - what went wrong, what was learned - and brings the right lesson back at the right moment, such as when starting a new project or making a risky change.
**Result:** the company's experience becomes reusable, so new projects start smarter instead of repeating old mistakes.

---

## How we build it (the safe order)

We build from the ground up, so each step stands on a solid base. Some user-facing features (like project setup) come later in the build because they depend on lower-level pieces being ready first.

| Step | What we build | Why it comes here |
|------|---------------|-------------------|
| 1 | Foundations - project skeleton, database, and protecting our own code | nothing exists yet |
| 2 | Login and roles | every action needs to be tied to a real person |
| 3 | The rules engine (the core that decides ready / blocked) | the heart of the system, built and tested on its own |
| 4 | Core data and the main screens' data | the engine needs information to work on |
| 5 | Reading pull requests from the repository | gives the engine real information |
| 6 | Release management and approvals | completes the decision core |
| 7 | AI assistance (summaries, drafts) | helps people; never makes decisions |
| 8 | Code and security scan + history report | the scan and audit feature |
| 9 | Reading the build/test pipeline | used as input, no actions yet |
| 10 | The safe machinery for taking actions | built and tested before any real action |
| 11 | Low-risk actions (comments, labels) | start small |
| 12 | High-risk actions (merge, deploy) | only after the safe machinery is proven |
| 13 | Project setup / bootstrapping | needs the safe action machinery from steps 10-12 |
| 14 | The web dashboard | needs the features above it to be ready |
| 15 | Coding-from-anywhere connection | governs work the rest produces |
| 16 | Shared knowledge | works best once there is real project data |
| 17 | Final testing and polish | last hardening before it's done |

---

## The key points

- **Each phase is something real we can show** - we are never building for months with nothing to demonstrate.
- **Project setup leads the story** because it is where a project's life begins, but in the build it comes later, since it needs the safe action machinery to exist first.
- **Even the early steps alone are useful** - once the rules engine and release management are built, we already have a working tool that replaces the manual process and enforces the standards.
- **This is the full vision in one version** - a large, multi-month build by choice. The phasing keeps it trackable and keeps a usable product available early.

*Full design is in `inception.md`; the detailed specification is in `elaboration.md`. No code has been built yet - this is the planning stage.*
