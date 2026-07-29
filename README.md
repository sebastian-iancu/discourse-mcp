# discourse-mcp — openEHR forum access for Claude Code

Connects [Claude Code](https://claude.com/claude-code) to the [openEHR Discourse forum](https://discourse.openehr.org) through the official [`@discourse/mcp`](https://github.com/discourse/discourse-mcp) server, packaged in a small Docker image.

Running the server in Docker (instead of the upstream-recommended bare `npx`) keeps it isolated: the container sees exactly one read-only file (the auth profile), runs as a non-root user, and executes a version pinned at build time rather than whatever `@latest` resolves to at startup.

## Prerequisites

- Docker (Docker Desktop with WSL integration, or any Linux Docker)
- GNU make
- Claude Code, or any MCP client that speaks stdio

## Quick start

### 1. Build the image

```sh
make build
```

### 2. Create an authentication profile (one-time)

The server authenticates with a Discourse **user API key**, stored in a profile file that lives **outside this repository**. Generate it with the built-in interactive helper (it prints a URL to approve in your browser):

```sh
docker run -it --rm -v "$HOME/.config:/out" node:24-alpine \
  npx -y @discourse/mcp@latest generate-user-api-key \
  --site https://discourse.openehr.org \
  --save-to /out/discourse-openehr-org.profile.json

chmod 600 ~/.config/discourse-openehr-org.profile.json
```

### 3. Verify

```sh
make test   # expects: "OK: server starts and profile loads"
```

### 4. Connect Claude Code

[`.mcp.json`](.mcp.json) in this repo already registers the server (project scope). Start Claude Code in this directory and approve the server when prompted; `/mcp` shows the connection status. After a rebuild or a config change, reconnect via `/mcp`.

## Everyday commands

| Command               | What it does                                                        |
| --------------------- | ------------------------------------------------------------------- |
| `make help`           | List all targets                                                     |
| `make build`          | Build the image with the pinned version (`make build VERSION=x.y.z`) |
| `make latest-version` | Show the newest `@discourse/mcp` version on npm                      |
| `make update`         | Rebuild the image against that newest version                        |
| `make test`           | Smoke-test: image starts and the auth profile loads                  |
| `make run`            | Run the server interactively (MCP over stdio) for manual debugging   |
| `make shell`          | Open a shell inside the image                                        |
| `make clean`          | Remove the local image                                               |

## Configuration notes

- The server is tethered to a single site with `--site https://discourse.openehr.org`, so the `discourse_select_site` tool is not needed (or exposed).
- The auth profile is passed as `--profile /profile.json`. **The flag is `--profile`** — `--auth-config` does not exist and is silently ignored, leaving the server anonymous.
- The server defaults to read-only (`--read_only true`). To allow posting/drafts, add `--allow_writes --read_only=false` to the args in `.mcp.json` — deliberately not enabled here.
- `--tools_mode discourse_api_only` is set because the openEHR forum does not expose the Discourse AI tool-exec endpoint (`/ai/tools`); the default auto-detection would log a spurious HTTP 404 at startup. Remove the flag if the forum ever enables that API.

## Security

- **Never commit the auth profile.** It contains API keys. It lives at `~/.config/discourse-openehr-org.profile.json`, and [`.gitignore`](.gitignore) additionally blocks `*.profile.json` in case a copy ever lands in the working tree.
- The profile is mounted read-only; the container runs as the non-root `node` user with `--security-opt no-new-privileges` and `--pull=never`.
- To rotate the key, rerun step 2 of the quick start and revoke the old key in your forum preferences (Preferences → Security → Recently used devices / Apps).
