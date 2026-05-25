#!/usr/bin/env bash
# ============================================================
# 04-antigravity.sh — Installs Google Antigravity CLI (v2).
# Upstream installer: https://antigravity.google/cli/install.sh
# Auth: `antigravity login` (browser/OAuth).
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

if [[ "${INSTALL_ANTIGRAVITY:-false}" != "true" ]]; then
  echo "==> Antigravity install disabled (INSTALL_ANTIGRAVITY != true). Skipping."
  exit 0
fi

echo "==> Installing Antigravity CLI (upstream installer)"
# Upstream installer is curl|bash. Reviewed as of script authoring; pin or audit if compliance requires it.
curl -fsSL https://antigravity.google/cli/install.sh | bash

# Most installers drop binary in ~/.local/bin or similar. Ensure on PATH.
if ! grep -q 'ANTIGRAVITY_BIN' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'EOF'

# Antigravity CLI
export ANTIGRAVITY_BIN="$HOME/.local/bin"
case ":$PATH:" in *":$ANTIGRAVITY_BIN:"*) ;; *) export PATH="$ANTIGRAVITY_BIN:$PATH";; esac
EOF
fi
export PATH="$HOME/.local/bin:$PATH"

antigravity --version 2>/dev/null || echo "    (antigravity binary not yet on PATH — run \`source ~/.bashrc\`)"

echo "==> Antigravity CLI installed. Auth with: antigravity login"
