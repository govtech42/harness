#!/usr/bin/env bash
# ============================================================
# 08-obsidian.sh — shared Obsidian vault for all CLI agents.
# Headless (no Obsidian app required). Optional git auto-sync.
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

if [[ "${INSTALL_OBSIDIAN:-false}" != "true" ]]; then
  echo "==> Obsidian vault disabled (INSTALL_OBSIDIAN != true). Skipping."
  exit 0
fi

# shellcheck source=../../lib/obsidian.sh
source "$REPO_ROOT/lib/obsidian.sh"

setup_vault

if [[ "${OBSIDIAN_AUTOSYNC:-false}" == "true" ]]; then
  if [[ -z "${OBSIDIAN_VAULT_REPO:-}" ]]; then
    echo "WARN: OBSIDIAN_AUTOSYNC=true but OBSIDIAN_VAULT_REPO is empty — skipping cron."
  else
    sync_vault_install
  fi
fi

echo "==> Obsidian vault setup complete."
echo "    Vault:  ${OBSIDIAN_VAULT_DIR:-$HOME/vault}"
echo "    Run \`source ~/.bashrc\` to pick up \$OBSIDIAN_VAULT_DIR and the \`cdvault\` alias."
