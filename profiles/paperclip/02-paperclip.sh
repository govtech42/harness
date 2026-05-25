#!/usr/bin/env bash
# ============================================================
# 02-paperclip.sh — install Paperclip.
# Upstream: https://github.com/paperclipai/paperclip
# Runtime: Node 20+ with pnpm 9.15+. API server on port 3100.
# Embedded PostgreSQL is provisioned automatically on first run.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
set -a; source "$SCRIPT_DIR/.env"; set +a

export PATH="$HOME/.npm-global/bin:$PATH"

INSTALL_DIR="${PAPERCLIP_DIR:-$HOME/paperclip}"
REPO="${PAPERCLIP_REPO:-https://github.com/paperclipai/paperclip.git}"
BRANCH="${PAPERCLIP_BRANCH:-main}"

if [[ "${PAPERCLIP_USE_NPX:-false}" == "true" ]]; then
  echo "==> Running upstream onboarder via npx"
  npx -y paperclipai onboard --yes
else
  echo "==> Cloning into $INSTALL_DIR"
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    git -C "$INSTALL_DIR" fetch --all --prune
    git -C "$INSTALL_DIR" checkout "$BRANCH"
    git -C "$INSTALL_DIR" pull --ff-only
  else
    git clone --branch "$BRANCH" "$REPO" "$INSTALL_DIR"
  fi

  cd "$INSTALL_DIR"
  echo "==> pnpm install"
  pnpm install --frozen-lockfile || pnpm install
  echo "==> pnpm build"
  pnpm build
fi

# Optional systemd unit for the API server.
if [[ "${PAPERCLIP_AS_SERVICE:-false}" == "true" ]]; then
  echo "==> Installing systemd unit"
  PORT="${PAPERCLIP_PORT:-3100}"
  PNPM_BIN="$(command -v pnpm)"
  sudo tee /etc/systemd/system/paperclip.service >/dev/null <<EOF
[Unit]
Description=Paperclip API server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
Environment=PORT=$PORT
Environment=PAPERCLIP_TELEMETRY_DISABLED=${PAPERCLIP_TELEMETRY_DISABLED:-1}
EnvironmentFile=$SCRIPT_DIR/.env
ExecStart=$PNPM_BIN dev:server
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now paperclip.service
  sudo systemctl status paperclip --no-pager || true
fi

echo
echo "==> Paperclip installed at $INSTALL_DIR"
echo "    Dev (API + UI):  cd $INSTALL_DIR && pnpm dev"
echo "    Server only:     cd $INSTALL_DIR && pnpm dev:server"
echo "    Default port:    ${PAPERCLIP_PORT:-3100}"
