#!/usr/bin/env bash
# ============================================================
# paperclip/install.sh
# Local install of Paperclip — https://github.com/paperclip/paperclip
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

FORCE="${1:-}"
mutex_check "paperclip" "$FORCE"

if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  echo "ERROR: .env not found. Run: cp .env.example .env && nano .env"
  exit 1
fi
chmod 600 "$SCRIPT_DIR/.env"
load_env "$SCRIPT_DIR/.env"

bash "$SCRIPT_DIR/01-system.sh"
bash "$SCRIPT_DIR/02-paperclip.sh"

mutex_set "paperclip"
banner "Paperclip installed. See README.md for first-run instructions."
