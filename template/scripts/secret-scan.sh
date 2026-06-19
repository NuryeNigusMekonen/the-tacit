#!/usr/bin/env bash
# secret-scan.sh - zero-dependency, high-precision secret detector (Standard §3).
# Refuses to commit/push obvious credential leaks. Tuned for PRECISION (very low
# false-positive rate) so developers never feel the urge to disable it.
#
# Usage:
#   scripts/secret-scan.sh --staged        # staged changes (pre-commit hook)
#   scripts/secret-scan.sh --range A..B     # a commit range (pre-push hook)
#   scripts/secret-scan.sh <files...>       # explicit paths (ad-hoc / CI)
#
# Suppress a known-safe placeholder line by appending:  pragma: allowlist secret
# Exit: 0 clean | 1 secret(s) found | 2 usage error.
set -euo pipefail

RED=$'\033[0;31m'; GRN=$'\033[0;32m'; NC=$'\033[0m'

# Paths that legitimately hold placeholders or describe secret patterns.
ALLOWLIST_PATHS_RE='(\.env\.example$|\.env\.template$|secret-scan\.sh$|\.gitleaks\.toml$|\.pre-commit-config\.yaml$|security\.yml$|package-lock\.json$|pnpm-lock\.yaml$|yarn\.lock$|uv\.lock$|AGENTS\.md$|README\.md$|CONTRIBUTING\.md$)'

PRAGMA='pragma: allowlist secret'

# label::PCRE  - high-precision detectors only.
PATTERNS=(
  'Connection URL with inline password::(postgres(ql)?|mysql|mariadb|mongodb(\+srv)?|amqps?|rediss?)(\+[a-z0-9]+)?://[^:/?#@[:space:]]+:[^@/?#[:space:]]{3,}@'
  'AWS access key id::\b(AKIA|ASIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA)[0-9A-Z]{16}\b'
  'Private key block::-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
  'JWT token::\beyJ[A-Za-z0-9_-]{6,}\.eyJ[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{6,}'
  'Prefixed API token::\b(xox[baprs]-[A-Za-z0-9-]{10,}|gh[pousr]_[A-Za-z0-9]{30,}|sk-(live|proj|ant)[A-Za-z0-9_-]{16,}|sk_(live|test)_[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_-]{30,})'
  'Hardcoded secret assignment::(?i)(password|passwd|pwd|secret|api[_-]?key|access[_-]?key|auth[_-]?token|client[_-]?secret)["'"'"' ]*[:=]["'"'"' ]*(?!\$[\{(])[^[:space:]"'"'"'#$]{12,}'
)

# Obviously-not-real values (dev defaults / placeholders). Keep tight.
SAFE_VALUE_RE='(REPLACE|EXAMPLE|example|changeme|change_me|your[-_]|<[^>]+>|xxxx|placeholder|dummy|test[-_]?(secret|key|token|password)|:-\}|\*\*\*|REDACTED)'

scan_one() { # $1 = file content to read, $2 = real repo path (for allow/report)
  local blob="$1" path="$2" found=0 entry label re hit lineno content
  grep -Iq . "$blob" 2>/dev/null || return 0                 # skip binaries
  printf '%s' "$path" | grep -Pq "$ALLOWLIST_PATHS_RE" && return 0
  for entry in "${PATTERNS[@]}"; do
    label="${entry%%::*}"; re="${entry#*::}"
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      lineno="${hit%%:*}"; content="${hit#*:}"
      printf '%s' "$content" | grep -q "$PRAGMA" && continue
      printf '%s' "$content" | grep -Pq "$SAFE_VALUE_RE" && continue
      printf '%s  x %s%s  %s:%s\n' "$RED" "$label" "$NC" "$path" "$lineno"
      printf '      %s\n' "$(printf '%s' "$content" | sed -E 's/^[[:space:]]+//' | cut -c1-120)"
      found=1
    done < <(grep -nP "$re" "$blob" 2>/dev/null || true)
  done
  return $found
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
declare -a PAIRS=()

stage_blob() { # $1 = git revspec, $2 = real path
  local dest="$TMP/$2"; mkdir -p "$(dirname "$dest")"
  git show "$1" > "$dest" 2>/dev/null && PAIRS+=("$dest::$2") || true
}

mode="${1:-}"
case "$mode" in
  --staged)
    while IFS= read -r p; do [ -n "$p" ] && stage_blob ":$p" "$p"
    done < <(git diff --cached --name-only --diff-filter=ACM) ;;
  --range)
    range="${2:?--range needs A..B}"; tip="${range##*..}"
    while IFS= read -r p; do [ -n "$p" ] && stage_blob "$tip:$p" "$p"
    done < <(git diff --name-only --diff-filter=ACM "$range") ;;
  "" ) echo "usage: secret-scan.sh --staged | --range A..B | <files...>" >&2; exit 2 ;;
  * ) for p in "$@"; do PAIRS+=("$p::$p"); done ;;
esac

[ ${#PAIRS[@]} -eq 0 ] && { echo "${GRN}secret-scan: nothing to scan${NC}"; exit 0; }

rc=0
for pair in "${PAIRS[@]}"; do
  scan_one "${pair%%::*}" "${pair##*::}" || rc=1
done

if [ "$rc" -ne 0 ]; then
  echo ""
  echo "${RED}secret-scan: potential secret(s) detected - commit/push BLOCKED.${NC}"
  echo "  - Remove the secret; use an env var / secret manager instead."
  echo "  - If it is a genuine placeholder, append '  ${PRAGMA}' to that line."
  echo "  - If a real secret already reached git, ROTATE it (history is not enough)."
else
  echo "${GRN}secret-scan: clean (${#PAIRS[@]} file(s)).${NC}"
fi
exit $rc
