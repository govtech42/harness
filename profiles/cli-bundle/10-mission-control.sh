#!/usr/bin/env bash
# ============================================================
# 10-mission-control.sh — Mission Control dashboard for cli-bundle.
# Wires MC_CLAUDE_HOME=~/.claude so the Claude SDK adapter sees the
# local session/config tree.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found."
  exit 1
fi

# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

# shellcheck source=../../lib/base-packages.sh
source "$REPO_ROOT/lib/base-packages.sh"
# shellcheck source=../../lib/mission-control.sh
source "$REPO_ROOT/lib/mission-control.sh"

export MC_CLAUDE_HOME="${MC_CLAUDE_HOME:-$HOME/.claude}"

install_mission_control
