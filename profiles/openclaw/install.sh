#!/usr/bin/env bash
# ============================================================
# openclaw/install.sh
# Local install of OpenClaw — https://github.com/openclaw/openclaw
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

FORCE="${1:-}"
mutex_check "openclaw" "$FORCE"

if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  echo "ERROR: .env not found. Run: cp .env.example .env && nano .env"
  exit 1
fi
chmod 600 "$SCRIPT_DIR/.env"
load_env "$SCRIPT_DIR/.env"

bash "$SCRIPT_DIR/01-system.sh"
bash "$SCRIPT_DIR/02-openclaw.sh"
bash "$SCRIPT_DIR/03-mission-control.sh"

mutex_set "openclaw"
banner "OpenClaw installed. See README.md for first-run instructions."
