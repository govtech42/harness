#!/usr/bin/env bash
# 01-system.sh — base system deps for OpenClaw.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck disable=SC1091
set -a; source "$SCRIPT_DIR/.env"; set +a

# shellcheck source=../../lib/base-packages.sh
source "$REPO_ROOT/lib/base-packages.sh"

TIMEZONE="${TIMEZONE:-America/Sao_Paulo}"
SWAP_SIZE_GB="${SWAP_SIZE_GB:-2}"

install_base_packages
install_db_clients
install_headless_browser

install_node "${NODE_MAJOR:-22}"
install_pnpm "${PNPM_VERSION:-latest}"

sudo timedatectl set-timezone "$TIMEZONE" || true

if [[ "$SWAP_SIZE_GB" != "0" ]] && ! swapon --show | grep -q '/swapfile'; then
  sudo fallocate -l "${SWAP_SIZE_GB}G" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

echo "==> System ready."
