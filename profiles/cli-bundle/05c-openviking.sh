#!/usr/bin/env bash
# ============================================================
# 05c-openviking.sh — Installs OpenViking CLI (`ov`).
# Package: @openviking/cli (npm). Connects to an OpenViking
# server (default http://localhost:1933).
# Upstream: https://github.com/volcengine/OpenViking
# Setup: `ov config` (interactive) to point at your server.
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

if [[ "${INSTALL_OPENVIKING:-false}" != "true" ]]; then
  echo "==> OpenViking install disabled (INSTALL_OPENVIKING != true). Skipping."
  exit 0
fi

export PATH="$HOME/.npm-global/bin:$PATH"

echo "==> Installing @openviking/cli"
npm install -g @openviking/cli

ov --version 2>/dev/null || ov status 2>/dev/null || true

echo "==> OpenViking CLI installed."
echo "    Configure your server with: ov config"
echo "    (defaults to http://localhost:1933; override via OPENVIKING_CLI_CONFIG_FILE)"
