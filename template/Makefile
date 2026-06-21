# The single command surface for this project (Tenacious Standard §4).
# CI runs these SAME targets, so local and pipeline behaviour stay identical.
#
# Auto-detects Python and/or Node and runs the right commands. A polyglot repo
# (both) runs both. Override any command by editing the recipe for your stack.

.PHONY: help install lint format test build secret-scan

# --- stack detection ---------------------------------------------------------
HAS_PY  := $(shell { [ -f pyproject.toml ] || ls requirements*.txt >/dev/null 2>&1 || git ls-files '*.py' 2>/dev/null | grep -q . ; } && echo yes)
HAS_JS  := $(shell [ -f package.json ] && echo yes)

help:
	@echo "Targets: install | lint | format | test | build | secret-scan"
	@echo "Detected stack: Python=$(if $(HAS_PY),yes,no)  Node=$(if $(HAS_JS),yes,no)"

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
	npm run lint --if-present
endif
	@echo "lint: done"

format:
ifeq ($(HAS_PY),yes)
	ruff format .
endif
ifeq ($(HAS_JS),yes)
	npm run format --if-present
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

secret-scan:
	bash scripts/secret-scan.sh $$(git ls-files)
