#!/usr/bin/env bash
# ============================================================
# 02-openclaw.sh — install OpenClaw via npm global.
# Upstream: https://github.com/openclaw/openclaw
# Runtime: Node 22.19+ (24 recommended). Gateway default port 18789.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
set -a; source "$SCRIPT_DIR/.env"; set +a

export PATH="$HOME/.npm-global/bin:$PATH"

# Ensure user-local npm prefix (no sudo for globals).
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
if ! grep -q 'NPM_GLOBAL_BIN' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'EOF'

# npm user-global
export NPM_GLOBAL_BIN="$HOME/.npm-global/bin"
export PATH="$NPM_GLOBAL_BIN:$PATH"
EOF
fi

VERSION="${OPENCLAW_VERSION:-latest}"
echo "==> Installing openclaw@${VERSION} globally"
npm install -g "openclaw@${VERSION}"

openclaw --version || true

# Seed minimal config if absent.
CFG_DIR="$HOME/.openclaw"
CFG_FILE="$CFG_DIR/openclaw.json"
mkdir -p "$CFG_DIR"
if [[ ! -f "$CFG_FILE" ]]; then
  echo "==> Writing seed config $CFG_FILE"
  cat > "$CFG_FILE" <<EOF
{
  "agent": {
    "model": "${OPENCLAW_MODEL:-anthropic/claude-sonnet-4-6}"
  }
}
EOF
  chmod 600 "$CFG_FILE"
fi

# Daemon install (systemd via the CLI's own command).
if [[ "${OPENCLAW_AS_SERVICE:-false}" == "true" ]]; then
  echo "==> Onboarding + installing daemon"
  openclaw onboard --install-daemon
  openclaw gateway status || true
else
  echo "==> Skipping daemon install (OPENCLAW_AS_SERVICE != true)"
  echo "    Run interactively:  openclaw gateway --port ${OPENCLAW_PORT:-18789} --verbose"
fi

echo "==> OpenClaw installed. Config: $CFG_FILE"
