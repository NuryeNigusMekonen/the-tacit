#!/usr/bin/env bash
# setup-branch-protection.sh - create the standard branch structure AND apply
# Tenacious branch protection via the GitHub API (Standard §2). Closes the gap
# that templates carry FILES but not SETTINGS. Run once per repo after creating
# it from the template.
#
# Requires the GitHub CLI (`gh`) authenticated with repo admin rights:
#   gh auth login
#
# Usage:
#   scripts/setup-branch-protection.sh <owner/repo>
#
# It will:
#   1. Create dev, staging, and production branches (if missing).
#   2. Apply protection to each: require PRs, passing checks, and code-owner
#      review; block force-push/delete; production requires 2 approvals.
# Idempotent - safe to re-run.
#
# NOTE on direction (feature -> dev -> staging -> production): GitHub protection
# enforces PR-only + checks + reviewers, but does NOT natively reject a
# wrong-source merge (e.g. dev -> production). Full directional enforcement is
# The Tacit's policy engine. This script lays the groundwork; see BRANCH_PROTECTION.md.
set -euo pipefail

REPO="${1:?usage: setup-branch-protection.sh <owner/repo>}"
DEFAULT="$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)"

# --- 1. create the standard branches off the default branch ------------------
base_sha="$(gh api "repos/${REPO}/git/refs/heads/${DEFAULT}" -q .object.sha)"
for b in dev staging production; do
  if gh api "repos/${REPO}/git/refs/heads/${b}" >/dev/null 2>&1; then
    echo "branch '${b}' already exists - skipping create."
  else
    gh api -X POST "repos/${REPO}/git/refs" \
      -f "ref=refs/heads/${b}" -f "sha=${base_sha}" >/dev/null
    echo "created branch '${b}'."
  fi
done

# --- 2. protect each branch --------------------------------------------------
protect() { # $1 = branch, $2 = required approvals
  local branch="$1" approvals="$2"
  echo "protecting '${branch}' (require ${approvals} approval(s)) ..."
  gh api -X PUT "repos/${REPO}/branches/${branch}/protection" \
    -H "Accept: application/vnd.github+json" \
    -f "required_status_checks[strict]=true" \
    -f "required_status_checks[contexts][]=ci" \
    -f "required_status_checks[contexts][]=security" \
    -f "required_status_checks[contexts][]=coverage" \
    -F "enforce_admins=true" \
    -F "required_pull_request_reviews[required_approving_review_count]=${approvals}" \
    -F "required_pull_request_reviews[require_code_owner_reviews]=true" \
    -F "restrictions=null" \
    -F "allow_force_pushes=false" \
    -F "allow_deletions=false" \
    -F "required_conversation_resolution=true" >/dev/null
}

protect dev 1                 # feature -> dev: automated checks + 1 review
protect staging 1             # dev -> staging: Tech Lead review
protect production 2          # staging -> production: Tech Lead + Project Owner

echo ""
echo "Done. dev / staging / production created and protected."
echo "Reminder: the directional rule (no skipping, no backward flow) is only"
echo "fully enforced by The Tacit's engine - see .github/BRANCH_PROTECTION.md."
