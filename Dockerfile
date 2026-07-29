FROM node:24-alpine

# Pin the MCP server version at build time. Update deliberately via `make update`
# (or `make build VERSION=x.y.z`) instead of resolving @latest on every start:
# faster startup, works offline, and no unreviewed code runs with the API key mounted.
ARG DISCOURSE_MCP_VERSION=0.2.9
RUN npm install -g @discourse/mcp@${DISCOURSE_MCP_VERSION} && npm cache clean --force

USER node
ENTRYPOINT ["discourse-mcp"]
