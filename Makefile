COMPOSE ?= docker compose
SERVICE ?= app
PROJECT ?= $(notdir $(CURDIR))
VOLUME  ?= $(PROJECT)_fooocus-data

.DEFAULT_GOAL := help

.PHONY: help setup up down restart logs ps pull update shell config volume-path clean purge

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## First-time setup: pull image and start the stack
	$(COMPOSE) pull
	$(COMPOSE) up -d
	@echo
	@echo "Fooocus is starting. Open http://localhost:7865 once the model finishes downloading."
	@echo "Watch progress with: make logs"

up: ## Start the stack in the background
	$(COMPOSE) up -d

down: ## Stop and remove the container (volume is preserved)
	$(COMPOSE) down

restart: ## Restart the container
	$(COMPOSE) restart $(SERVICE)

logs: ## Follow container logs
	$(COMPOSE) logs -f $(SERVICE)

ps: ## Show container status
	$(COMPOSE) ps

pull: ## Pull the latest upstream image
	$(COMPOSE) pull

update: pull ## Pull latest image and recreate the container
	$(COMPOSE) up -d

shell: ## Open a bash shell inside the running container
	$(COMPOSE) exec $(SERVICE) bash

config: ## Print the active config.txt from the volume
	$(COMPOSE) exec $(SERVICE) cat /content/data/config.txt

volume-path: ## Show where the fooocus-data volume lives on the host
	@docker volume inspect $(VOLUME) --format '{{ .Mountpoint }}' 2>/dev/null || \
		echo "Volume '$(VOLUME)' not found. Run 'make up' first, or override with VOLUME=<name>."

clean: ## Stop the stack and remove the container (keeps models and outputs)
	$(COMPOSE) down --remove-orphans

purge: ## DANGER: remove the container AND the data volume (deletes all downloaded models)
	@printf "This will delete the '$(VOLUME)' volume and every model in it. Type 'yes' to continue: "; \
	read ans; [ "$$ans" = "yes" ] || { echo "Aborted."; exit 1; }
	$(COMPOSE) down -v --remove-orphans
