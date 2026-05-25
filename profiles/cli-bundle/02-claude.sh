#!/usr/bin/env bash
# ============================================================
# 02-install-claude.sh
# Installs Claude Code globally and exports ANTHROPIC_API_KEY if set.
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

if [[ "${INSTALL_CLAUDE:-true}" != "true" ]]; then
  echo "==> Claude install disabled (INSTALL_CLAUDE != true). Skipping."
  exit 0
fi

export PATH="$HOME/.npm-global/bin:$PATH"

echo "==> Installing @anthropic-ai/claude-code"
npm install -g @anthropic-ai/claude-code

claude --version || true

if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "==> Persisting ANTHROPIC_API_KEY in ~/.bashrc"
  # Remove old line if present
  sed -i '/^export ANTHROPIC_API_KEY=/d' "$HOME/.bashrc"
  echo "export ANTHROPIC_API_KEY=\"$ANTHROPIC_API_KEY\"" >> "$HOME/.bashrc"
  export ANTHROPIC_API_KEY
  echo "    API key exported."
else
  echo "==> No ANTHROPIC_API_KEY set. Run \`claude\` and use OAuth flow."
fi

chmod 600 "$HOME/.bashrc" 2>/dev/null || true

echo
echo "==> Claude Code installed."
