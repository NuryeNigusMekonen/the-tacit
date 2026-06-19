# The single command surface for this project (Tenacious Standard §4).
# CI runs these same targets, so local and pipeline behaviour stay identical.
# Fill in the language-specific commands for your stack.

.PHONY: help install lint format test build secret-scan

help:
	@echo "Targets: install | lint | format | test | build | secret-scan"

install:
	@echo "Install dependencies for your stack, e.g.:"
	@echo "  pip install -e '.[dev]'   or   npm ci"
	@# Activate the secret-scanning hook on every setup:
	bash scripts/install-hooks.sh

lint:
	@# e.g. ruff check .   |   npm run lint
	@echo "Add your lint command here."

format:
	@# e.g. ruff format .  |  npm run format
	@echo "Add your format command here."

test:
	@# e.g. pytest -q      |   npm test
	@echo "Add your test command here."

build:
	@# e.g. python -m build  |  npm run build
	@echo "Add your build command here."

secret-scan:
	bash scripts/secret-scan.sh $(shell git ls-files)
