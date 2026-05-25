#!/usr/bin/env bash
# ============================================================
# install.sh — One-shot orchestrator. Runs all 3 steps.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  echo "ERROR: .env not found. Run: cp .env.example .env && nano .env"
  exit 1
fi

bash "$SCRIPT_DIR/01-install-system.sh"

# Reload PATH for current shell so claude becomes visible
export PATH="$HOME/.npm-global/bin:$PATH"

bash "$SCRIPT_DIR/02-install-claude.sh"
bash "$SCRIPT_DIR/03-install-mcp.sh"
bash "$SCRIPT_DIR/04-install-dream.sh"

echo
echo "============================================================"
echo "  All done. Run \`source ~/.bashrc\` then \`tmux new -s claude\` and \`claude\`."
echo "============================================================"
