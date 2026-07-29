# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is not an application codebase. It is a small configuration workspace that connects Claude Code to the openEHR Discourse forum (https://discourse.openehr.org) via the official `@discourse/mcp` server, run inside Docker:

- `Dockerfile` — builds the `discourse-mcp` image: `node:24-alpine` with a **pinned** `@discourse/mcp` version installed at build time (`DISCOURSE_MCP_VERSION` build arg), running as the non-root `node` user with entrypoint `discourse-mcp`. Picking up a new release requires a rebuild (`make update`) plus an MCP reconnect.
- `.mcp.json` — registers the `discourse-openehr-org` MCP server with Claude Code (native `docker` CLI, `${HOME}` expansion for the profile path).
- `Makefile` — build/test/update helpers (`make help` lists targets).
- `README.md` — install and quick-start guide.

## Environment wiring

- The server command is the native `docker` CLI inside WSL (Docker Desktop WSL integration) — not `docker.exe`.
- The authentication profile lives at `~/.config/discourse-openehr-org.profile.json` and is mounted read-only into the container as `/profile.json`, passed to the server as `--profile /profile.json`.
- The correct flag is `--profile`. **`--auth-config` does not exist** — the server silently ignores unknown flags and then runs anonymous and untethered, which read-only public-forum tools mask. `make test` catches a non-loading profile.
- The server is tethered to a single site via `--site https://discourse.openehr.org` and runs read-only (upstream default). `--tools_mode discourse_api_only` is set because the forum has no `/ai/tools` endpoint (auto-detection would log a spurious 404).
- The auth profile contains credentials and is intentionally **not** in this repository (`.gitignore` blocks `*.profile.json`). Never copy it here or print its contents.

## Commands

All routine operations go through the Makefile:

```sh
make build            # build the image with the pinned version (VERSION=x.y.z to override)
make update           # rebuild against the latest version published on npm
make test             # smoke-test: image starts and the auth profile loads
make run              # run the server manually (MCP over stdio)
```

The image tag must stay `discourse-mcp` to match `.mcp.json`. After rebuilding the image or editing `.mcp.json`, reconnect the MCP server (`/mcp` in Claude Code). There is no build/lint/test tooling beyond this.

## Using the MCP server

When the server is connected, tools are available under `mcp__discourse-openehr-org__*` for working with the forum: `discourse_search`, `discourse_read_topic`, `discourse_read_post`, `discourse_filter_topics`, `discourse_get_user`, `discourse_list_users`, `discourse_list_user_posts`, `discourse_run_query` / `discourse_get_query` (Data Explorer), `discourse_get_chat_messages`, and `discourse_get_draft`. Tasks in this workspace are typically about querying/analyzing openEHR forum content, not editing code.
