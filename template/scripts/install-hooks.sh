#!/usr/bin/env bash
# Activate the repo's git hooks (secret scanning) for this clone.
# Idempotent - safe to re-run. Run once after cloning:  scripts/install-hooks.sh
# (Wire it into `make install` / `npm postinstall` so it runs automatically.)
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

chmod +x .githooks/pre-commit .githooks/pre-push scripts/secret-scan.sh 2>/dev/null || true
git config core.hooksPath .githooks

echo "OK core.hooksPath = .githooks (pre-commit + pre-push secret scanning active)"
if command -v gitleaks >/dev/null 2>&1; then
  echo "OK gitleaks found - fuller coverage enabled"
else
  echo "-  gitleaks not installed - the zero-dep scanner is active; CI runs the scan regardless."
fi
