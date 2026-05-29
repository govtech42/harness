#!/usr/bin/env bash
# ============================================================
# cli-bundle/install.sh
# Installs Claude Code + Codex + Antigravity + Cursor + OpenCode + OpenViking CLIs,
# plus optional Hindsight agent-memory (prototype). Toggle individually in .env.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

FORCE="${1:-}"
mutex_check "cli-bundle" "$FORCE"

if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  echo "ERROR: .env not found. Run: cp .env.example .env && nano .env"
  exit 1
fi
chmod 600 "$SCRIPT_DIR/.env"

bash "$SCRIPT_DIR/01-system.sh"
export PATH="$HOME/.npm-global/bin:$PATH"

# Per-CLI toggles read inside each script.
bash "$SCRIPT_DIR/02-claude.sh"
bash "$SCRIPT_DIR/03-codex.sh"
bash "$SCRIPT_DIR/04-antigravity.sh"
bash "$SCRIPT_DIR/05-cursor.sh"
bash "$SCRIPT_DIR/05b-opencode.sh"
bash "$SCRIPT_DIR/05c-openviking.sh"
bash "$SCRIPT_DIR/05d-hindsight.sh"
bash "$SCRIPT_DIR/08-obsidian.sh"   # vault skeleton first; MCP step below registers it
bash "$SCRIPT_DIR/06-mcp.sh"
bash "$SCRIPT_DIR/07-dream.sh"
bash "$SCRIPT_DIR/09-plugins.sh"    # plugin marketplaces (Claude headless; others manual hint)
bash "$SCRIPT_DIR/10-mission-control.sh"  # opt-in orchestration dashboard

mutex_set "cli-bundle"

echo
banner "cli-bundle installed. Run: source ~/.bashrc"
echo "Then start a session, e.g.:  tmux new -s ai  &&  claude"
