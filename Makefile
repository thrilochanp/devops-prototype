SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help bootstrap doctor up down down-vm test image dora

help: ## Show targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

bootstrap: ## Install the macOS toolchain with Ansible + Homebrew and check Docker Desktop
	ansible-playbook -i ansible/inventory.ini ansible/bootstrap.yml

doctor: ## Print tool versions and cluster health
	@scripts/doctor.sh

up: ## Create cluster + gateway + Argo CD, then GitOps restores the rest
	@scripts/up.sh

down: ## Back up the sealing key and destroy the cluster
	@scripts/down.sh

down-vm: ## make down, then quit Docker Desktop to free its RAM
	@scripts/down.sh --stop-vm

test: ## Run app lint and tests
	cd app && . .venv/bin/activate && ruff check . && python -m pytest -q

image: ## Build the app image locally
	docker build -t orders-api:local --build-arg APP_VERSION=local app

dora: ## Print DORA metrics for the last 30 days
	python3 scripts/dora.py --days 30
