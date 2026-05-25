#!/usr/bin/env bash
# ============================================================
# 03-install-mcp.sh
# Registers MCP servers based on .env toggles.
# Idempotent: removes existing entry before re-adding.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found."
  exit 1
fi

# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

export PATH="$HOME/.npm-global/bin:$PATH"

SCOPE="${MCP_SCOPE:-user}"

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: 'claude' not in PATH. Run 02-install-claude.sh first and \`source ~/.bashrc\`."
  exit 1
fi

add_mcp() {
  local name="$1"; shift
  echo "==> Registering MCP: $name (scope=$SCOPE)"
  claude mcp remove "$name" -s "$SCOPE" 2>/dev/null || true
  claude mcp add -s "$SCOPE" "$name" "$@"
}

add_mcp_transport() {
  local name="$1" transport="$2" url="$3"
  echo "==> Registering MCP: $name [$transport] (scope=$SCOPE)"
  claude mcp remove "$name" -s "$SCOPE" 2>/dev/null || true
  claude mcp add -s "$SCOPE" --transport "$transport" "$name" "$url"
}

# --- Context7 (stdio via npx) ---
if [[ "${INSTALL_CONTEXT7:-false}" == "true" ]]; then
  if [[ -n "${CONTEXT7_API_KEY:-}" ]]; then
    add_mcp context7 -e CONTEXT7_API_KEY="$CONTEXT7_API_KEY" -- npx -y @upstash/context7-mcp
  else
    add_mcp context7 -- npx -y @upstash/context7-mcp
  fi
fi

# --- Linear (remote SSE, OAuth) ---
if [[ "${INSTALL_LINEAR:-false}" == "true" ]]; then
  add_mcp_transport linear sse https://mcp.linear.app/sse
fi

# --- Slack (remote HTTP, OAuth) ---
if [[ "${INSTALL_SLACK:-false}" == "true" ]]; then
  add_mcp_transport slack http https://mcp.slack.com/mcp
fi

# --- GitHub (remote HTTP, OAuth) ---
if [[ "${INSTALL_GITHUB:-false}" == "true" ]]; then
  add_mcp_transport github http https://api.githubcopilot.com/mcp/
fi

# --- Supabase (remote HTTP, OAuth) ---
if [[ "${INSTALL_SUPABASE:-false}" == "true" ]]; then
  add_mcp_transport supabase http https://mcp.supabase.com/mcp
fi

# --- Sentry (remote HTTP, OAuth) ---
if [[ "${INSTALL_SENTRY:-false}" == "true" ]]; then
  add_mcp_transport sentry http https://mcp.sentry.dev/mcp
fi

# --- Notion (remote HTTP, OAuth) ---
if [[ "${INSTALL_NOTION:-false}" == "true" ]]; then
  add_mcp_transport notion http https://mcp.notion.com/mcp
fi

# --- Playwright (stdio, needs Chromium deps) ---
if [[ "${INSTALL_PLAYWRIGHT:-false}" == "true" ]]; then
  echo "==> Installing Playwright system deps (sudo)"
  sudo npx -y playwright install-deps || true
  npx -y playwright install chromium || true
  add_mcp playwright -- npx -y @playwright/mcp@latest
fi

# --- Filesystem (stdio) ---
if [[ "${INSTALL_FILESYSTEM:-false}" == "true" ]]; then
  FS_PATHS="${FILESYSTEM_PATHS:-$HOME}"
  # shellcheck disable=SC2086
  add_mcp fs -- npx -y @modelcontextprotocol/server-filesystem $FS_PATHS
fi

# --- Obsidian vault (stdio, via filesystem MCP scoped to the vault) ---
# Installed independently of INSTALL_FILESYSTEM so the broader fs MCP stays
# off by default while the vault remains accessible.
if [[ "${INSTALL_OBSIDIAN:-false}" == "true" ]]; then
  VAULT="${OBSIDIAN_VAULT_DIR:-$HOME/vault}"
  if [[ -d "$VAULT" ]]; then
    add_mcp obsidian-vault -- npx -y @modelcontextprotocol/server-filesystem "$VAULT"
  else
    echo "WARN: INSTALL_OBSIDIAN=true but vault dir $VAULT missing. Run 08-obsidian.sh first."
  fi
fi

echo
echo "==> MCP registration done. Current servers:"
claude mcp list

cat <<'EOF'

Next steps:
  1. Start a tmux session:    tmux new -s claude
  2. Launch Claude Code:      claude
  3. Authenticate remote MCPs: type `/mcp` inside claude — opens OAuth URLs.
  4. Detach tmux:             Ctrl+b then d
  5. Reattach later:          tmux attach -t claude
EOF
