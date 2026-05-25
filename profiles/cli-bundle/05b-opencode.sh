#!/usr/bin/env bash
# ============================================================
# 05b-opencode.sh — Installs OpenCode CLI.
# Upstream installer: https://opencode.ai/install
# Auth: provider keys per Models.dev integration.
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

if [[ "${INSTALL_OPENCODE:-false}" != "true" ]]; then
  echo "==> OpenCode install disabled (INSTALL_OPENCODE != true). Skipping."
  exit 0
fi

echo "==> Installing OpenCode CLI (upstream installer)"
curl -fsSL https://opencode.ai/install | bash

# Installer typically drops binary in ~/.opencode/bin or ~/.local/bin.
if ! grep -q 'OPENCODE_BIN' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'EOF'

# OpenCode CLI
export OPENCODE_BIN="$HOME/.opencode/bin"
case ":$PATH:" in *":$OPENCODE_BIN:"*) ;; *) export PATH="$OPENCODE_BIN:$HOME/.local/bin:$PATH";; esac
EOF
fi
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

opencode --version 2>/dev/null || echo "    (opencode binary not yet on PATH — run \`source ~/.bashrc\`)"

echo "==> OpenCode CLI installed. Configure with: opencode auth"
