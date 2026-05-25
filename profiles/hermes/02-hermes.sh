#!/usr/bin/env bash
# ============================================================
# 02-hermes.sh — install Hermes Agent.
# Upstream: https://github.com/NousResearch/hermes-agent
# Runtime: Python 3.11 + uv.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
set -a; source "$SCRIPT_DIR/.env"; set +a

export PATH="$HOME/.local/bin:$PATH"

if [[ "${HERMES_USE_UPSTREAM_INSTALLER:-true}" == "true" ]]; then
  echo "==> Running upstream installer"
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
else
  INSTALL_DIR="${HERMES_DIR:-$HOME/hermes-agent}"
  REPO="${HERMES_REPO:-https://github.com/NousResearch/hermes-agent.git}"
  BRANCH="${HERMES_BRANCH:-main}"

  echo "==> Cloning into $INSTALL_DIR"
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    git -C "$INSTALL_DIR" fetch --all --prune
    git -C "$INSTALL_DIR" checkout "$BRANCH"
    git -C "$INSTALL_DIR" pull --ff-only
  else
    git clone --branch "$BRANCH" "$REPO" "$INSTALL_DIR"
  fi

  cd "$INSTALL_DIR"
  if [[ -x ./setup-hermes.sh ]]; then
    ./setup-hermes.sh
  else
    uv venv .venv --python 3.11
    # shellcheck disable=SC1091
    source .venv/bin/activate
    uv pip install -e ".[all,dev]"
  fi
fi

hermes --version 2>/dev/null || echo "    (hermes binary not yet on PATH — run \`source ~/.bashrc\`)"

echo
echo "==> Hermes installed."
echo "    Configure:   hermes setup"
echo "    Choose LLM:  hermes model"
echo "    Run:         hermes          # interactive"
echo "                 hermes gateway  # messaging gateway"
