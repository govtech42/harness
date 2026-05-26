#!/usr/bin/env bash
# ============================================================
# 03-mission-control.sh — Mission Control dashboard for OpenClaw.
# OpenClaw is a first-class gateway adapter in Mission Control.
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

# Default the OpenClaw paths so MC wires straight into the local install.
export OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
export OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

install_mission_control
