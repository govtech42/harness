#!/usr/bin/env bash
# ============================================================
# 03-codex.sh — Installs OpenAI Codex CLI.
# Package: @openai/codex (npm). Auth: `codex login` or OPENAI_API_KEY.
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

if [[ "${INSTALL_CODEX:-false}" != "true" ]]; then
  echo "==> Codex install disabled (INSTALL_CODEX != true). Skipping."
  exit 0
fi

export PATH="$HOME/.npm-global/bin:$PATH"

echo "==> Installing @openai/codex"
npm install -g @openai/codex

codex --version || true

if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  echo "==> Persisting OPENAI_API_KEY in ~/.bashrc"
  sed -i '/^export OPENAI_API_KEY=/d' "$HOME/.bashrc"
  echo "export OPENAI_API_KEY=\"$OPENAI_API_KEY\"" >> "$HOME/.bashrc"
  export OPENAI_API_KEY
  chmod 600 "$HOME/.bashrc" 2>/dev/null || true
else
  echo "==> No OPENAI_API_KEY set. Run \`codex login\` to auth."
fi

echo "==> Codex CLI installed."
