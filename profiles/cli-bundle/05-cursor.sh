#!/usr/bin/env bash
# ============================================================
# 05-cursor.sh — Installs Cursor CLI (cursor-agent).
# Upstream installer: https://cursor.com/install
# Auth: `cursor-agent login`.
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

if [[ "${INSTALL_CURSOR:-false}" != "true" ]]; then
  echo "==> Cursor install disabled (INSTALL_CURSOR != true). Skipping."
  exit 0
fi

echo "==> Installing Cursor CLI (upstream installer)"
curl -fsSL https://cursor.com/install | bash

# Cursor installer typically writes to ~/.local/bin/cursor-agent.
if ! grep -q 'CURSOR_BIN' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'EOF'

# Cursor CLI
export CURSOR_BIN="$HOME/.local/bin"
case ":$PATH:" in *":$CURSOR_BIN:"*) ;; *) export PATH="$CURSOR_BIN:$PATH";; esac
EOF
fi
export PATH="$HOME/.local/bin:$PATH"

cursor-agent --version 2>/dev/null || echo "    (cursor-agent not yet on PATH — run \`source ~/.bashrc\`)"

echo "==> Cursor CLI installed. Auth with: cursor-agent login"
