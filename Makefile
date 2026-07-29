IMAGE    := discourse-mcp
VERSION  ?= 0.2.9
PROFILE  ?= $(HOME)/.config/discourse-openehr-org.profile.json
SITE     ?= https://discourse.openehr.org

# Same flags .mcp.json uses, so manual runs match what Claude Code runs.
# tools_mode discourse_api_only: the openEHR forum has no /ai/tools endpoint,
# so auto-detection would log a spurious HTTP 404 at startup.
DOCKER_RUN_FLAGS := --rm --init --pull=never --security-opt no-new-privileges \
	-v $(PROFILE):/profile.json:ro
SERVER_ARGS := --profile /profile.json --site $(SITE) --tools_mode discourse_api_only

.PHONY: help build latest-version update run test shell clean

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the image with the pinned version (override: make build VERSION=x.y.z)
	docker build --build-arg DISCOURSE_MCP_VERSION=$(VERSION) -t $(IMAGE) .

latest-version: ## Show the latest @discourse/mcp version published on npm
	@docker run --rm node:24-alpine npm view @discourse/mcp version

update: ## Rebuild the image against the latest version published on npm
	docker build --pull --no-cache \
		--build-arg DISCOURSE_MCP_VERSION=$$(docker run --rm node:24-alpine npm view @discourse/mcp version) \
		-t $(IMAGE) .

run: ## Run the server interactively (MCP over stdio) with the auth profile mounted
	docker run -i $(DOCKER_RUN_FLAGS) $(IMAGE) $(SERVER_ARGS)

test: ## Smoke-test: image starts, auth profile loads, no errors
	@docker run $(DOCKER_RUN_FLAGS) $(IMAGE) $(SERVER_ARGS) 2>&1 \
		| grep -iE "error|failed|invalid" \
		&& { echo "FAILED: see errors above"; exit 1; } \
		|| echo "OK: server starts and profile loads"

shell: ## Open a shell inside the image for debugging
	docker run -it --rm --entrypoint sh $(IMAGE)

clean: ## Remove the local image
	docker rmi $(IMAGE)
