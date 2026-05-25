#!/usr/bin/env bash
# ============================================================
# 01-install-system.sh
# Installs Node.js 20, git, tmux, sets timezone, configures swap.
# Run as: bash 01-install-system.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Copy .env.example to .env first."
  exit 1
fi

# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

# shellcheck source=../../lib/base-packages.sh
source "$REPO_ROOT/lib/base-packages.sh"

TIMEZONE="${TIMEZONE:-America/Sao_Paulo}"
SWAP_SIZE_GB="${SWAP_SIZE_GB:-2}"

install_base_packages
install_db_clients
install_headless_browser

echo "==> Installing Node.js 20.x"
if ! command -v node >/dev/null 2>&1 || [[ "$(node -v | cut -d. -f1 | tr -d v)" -lt 18 ]]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
node -v
npm -v

echo "==> Setting timezone to $TIMEZONE"
sudo timedatectl set-timezone "$TIMEZONE" || true

if [[ "$SWAP_SIZE_GB" != "0" ]] && ! swapon --show | grep -q '/swapfile'; then
  echo "==> Creating ${SWAP_SIZE_GB}GB swap"
  sudo fallocate -l "${SWAP_SIZE_GB}G" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
else
  echo "==> Swap already configured or disabled"
fi

echo "==> Configuring npm user-local prefix (no sudo for global installs)"
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"

if ! grep -q 'NPM_GLOBAL_BIN' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'EOF'

# Claude Code VPS setup
export NPM_GLOBAL_BIN="$HOME/.npm-global/bin"
export PATH="$NPM_GLOBAL_BIN:$PATH"
EOF
fi

export PATH="$HOME/.npm-global/bin:$PATH"

echo
echo "==> System setup complete."
echo "    Run: source ~/.bashrc"
echo "    Then: bash 02-install-claude.sh"
