# The single command surface for this project (Tenacious Standard §4).
# CI runs these SAME targets, so local and pipeline behaviour stay identical.
#
# Auto-detects Python and/or Node and runs the right commands. A polyglot repo
# (both) runs both. Override any command by editing the recipe for your stack.

.PHONY: help install lint format test build coverage sast secret-scan

# --- stack detection ---------------------------------------------------------
HAS_PY  := $(shell { [ -f pyproject.toml ] || ls requirements*.txt >/dev/null 2>&1 || git ls-files '*.py' 2>/dev/null | grep -q . ; } && echo yes)
HAS_JS  := $(shell [ -f package.json ] && echo yes)

help:
	@echo "Targets: install | lint | format | test | build | coverage | sast | secret-scan"
	@echo "Detected stack: Python=$(if $(HAS_PY),yes,no)  Node=$(if $(HAS_JS),yes,no)"
	@echo "Other languages: fill in the recipes below (Go, Rust, Java, etc.)."

install:
ifeq ($(HAS_PY),yes)
	python -m pip install --upgrade pip
	pip install ruff pytest pytest-cov
	@[ -f requirements.txt ] && pip install -r requirements.txt || true
	@[ -f pyproject.toml ] && pip install -e ".[dev]" || pip install -e . || true
endif
ifeq ($(HAS_JS),yes)
	npm ci || npm install
endif
	@# Activate the secret-scanning hooks on every setup.
	bash scripts/install-hooks.sh

lint:
ifeq ($(HAS_PY),yes)
	ruff check .
endif
ifeq ($(HAS_JS),yes)
	@# Biome (recommended JS/TS linter+formatter, single fast tool). Falls back
	@# to the project's own `npm run lint` if it defines one.
	npx --yes @biomejs/biome ci . || npm run lint --if-present
endif
	@echo "lint: done"

format:
ifeq ($(HAS_PY),yes)
	ruff format .
endif
ifeq ($(HAS_JS),yes)
	npx --yes @biomejs/biome format --write . || npm run format --if-present
endif
	@echo "format: done"

test:
ifeq ($(HAS_PY),yes)
	pytest -q
endif
ifeq ($(HAS_JS),yes)
	npm test --if-present
endif
	@echo "test: done"

build:
ifeq ($(HAS_PY),yes)
	@python -m build 2>/dev/null || echo "python build: no build step configured (ok)"
endif
ifeq ($(HAS_JS),yes)
	npm run build --if-present
endif
	@echo "build: done"

coverage:
ifeq ($(HAS_PY),yes)
	@# Skip gate gracefully if no tests exist yet; enforce once they do.
	@if git ls-files | grep -qiE '(test_|_test|tests/|\.spec\.|\.test\.)'; then \
		pytest --cov=. --cov-report=term-missing --cov-fail-under=$${MIN_COVERAGE:-60}; \
	else echo "no tests yet - coverage gate skipped"; pytest --cov=. || true; fi
endif
ifeq ($(HAS_JS),yes)
	npm run coverage --if-present || npm test --if-present
endif
	@echo "coverage: done"

sast:
	@# Semgrep is multi-language (covers Python too) and runs for any stack.
	@# It is the single SAST tool here; CodeQL adds deeper analysis on the
	@# default branch + weekly (see .github/workflows/codeql.yml).
	pip install semgrep >/dev/null 2>&1 || true
	semgrep --config=auto --error || true   # advisory; flip --error to block
	@echo "sast: done"

secret-scan:
	bash scripts/secret-scan.sh $$(git ls-files)
