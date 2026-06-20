#!/usr/bin/env bash
# setup-branch-protection.sh - apply Tenacious branch protection via the GitHub
# API (Standard §2). Closes the gap that templates carry FILES but not SETTINGS.
# Run once per repo after creating it from the template.
#
# Requires the GitHub CLI (`gh`) authenticated with repo admin rights:
#   gh auth login
#
# Usage:
#   scripts/setup-branch-protection.sh <owner/repo> [branch]
#   (branch defaults to the repo's default branch)
#
# Makes the CI / security / coverage checks the real merge gate and requires a
# pull request + code-owner review. Idempotent - safe to re-run.
set -euo pipefail

REPO="${1:?usage: setup-branch-protection.sh <owner/repo> [branch]}"
BRANCH="${2:-$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)}"

echo "Applying branch protection to ${REPO}@${BRANCH} ..."

# Required status checks - must match the workflow job/check names.
# Adjust this list to the checks your project actually runs.
CHECKS='["ci","security","coverage"]'

gh api -X PUT "repos/${REPO}/branches/${BRANCH}/protection" \
  -H "Accept: application/vnd.github+json" \
  -f "required_status_checks[strict]=true" \
  -f "required_status_checks[contexts][]=ci" \
  -f "required_status_checks[contexts][]=security" \
  -f "required_status_checks[contexts][]=coverage" \
  -F "enforce_admins=true" \
  -F "required_pull_request_reviews[required_approving_review_count]=1" \
  -F "required_pull_request_reviews[require_code_owner_reviews]=true" \
  -F "restrictions=null" \
  -F "allow_force_pushes=false" \
  -F "allow_deletions=false" \
  -F "required_conversation_resolution=true"

echo "Done. ${BRANCH} now requires PRs, passing checks, and code-owner review."
echo "For production branches, raise required approvals to 2 (Tech Lead + Project Owner)."
