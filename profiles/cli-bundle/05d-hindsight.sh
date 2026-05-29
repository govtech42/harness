#!/usr/bin/env bash
# ============================================================
# 05d-hindsight.sh — Installs Hindsight agent-memory (client + optional server).
# Client:  @vectorize-io/hindsight-client (npm) and/or hindsight-client (pip).
# Server:  Docker image ghcr.io/vectorize-io/hindsight:latest
#          API on :8888, UI on :9999. Needs an LLM provider + key.
# Upstream: https://github.com/vectorize-io/hindsight
# NOTE: prototype — opt-in via INSTALL_HINDSIGHT. Server start is gated again
#       on HINDSIGHT_START_SERVER and the presence of Docker.
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

if [[ "${INSTALL_HINDSIGHT:-false}" != "true" ]]; then
  echo "==> Hindsight install disabled (INSTALL_HINDSIGHT != true). Skipping."
  exit 0
fi

export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"

# --- Client libraries -----------------------------------------------------
# Node/TS client (default on; matches the npm-first convention of this bundle).
if [[ "${HINDSIGHT_NPM_CLIENT:-true}" == "true" ]]; then
  echo "==> Installing @vectorize-io/hindsight-client (npm)"
  npm install -g @vectorize-io/hindsight-client
fi

# Python client (opt-in). Uses pipx when available to avoid PEP 668 breakage.
if [[ "${HINDSIGHT_PIP_CLIENT:-false}" == "true" ]]; then
  if command -v pipx >/dev/null 2>&1; then
    echo "==> Installing hindsight-client (pipx)"
    pipx install hindsight-client || pipx upgrade hindsight-client || true
  elif command -v pip3 >/dev/null 2>&1; then
    echo "==> Installing hindsight-client (pip3 --user)"
    pip3 install --user -U hindsight-client
  else
    echo "WARN: neither pipx nor pip3 found — skipping Python client."
  fi
fi

# --- Server (Docker, opt-in) ----------------------------------------------
if [[ "${HINDSIGHT_START_SERVER:-false}" == "true" ]]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "WARN: HINDSIGHT_START_SERVER=true but Docker is not installed."
    echo "      Install Docker, then run:"
    echo "        docker run --rm -d --pull always -p 8888:8888 -p 9999:9999 \\"
    echo "          -e HINDSIGHT_API_LLM_PROVIDER=${HINDSIGHT_LLM_PROVIDER:-openai} \\"
    echo "          -e HINDSIGHT_API_LLM_API_KEY=<your-key> \\"
    echo "          -v \$HOME/.hindsight-docker:/home/hindsight/.pg0 \\"
    echo "          ghcr.io/vectorize-io/hindsight:latest"
  elif [[ -z "${HINDSIGHT_LLM_API_KEY:-}" ]]; then
    echo "WARN: HINDSIGHT_START_SERVER=true but HINDSIGHT_LLM_API_KEY is empty."
    echo "      Set it (and HINDSIGHT_LLM_PROVIDER) in .env, or start the server manually."
  else
    echo "==> Starting Hindsight server (Docker) — API :8888, UI :9999"
    mkdir -p "$HOME/.hindsight-docker"
    docker run --rm -d --pull always \
      --name hindsight \
      -p 8888:8888 -p 9999:9999 \
      -e "HINDSIGHT_API_LLM_PROVIDER=${HINDSIGHT_LLM_PROVIDER:-openai}" \
      -e "HINDSIGHT_API_LLM_API_KEY=${HINDSIGHT_LLM_API_KEY}" \
      -v "$HOME/.hindsight-docker:/home/hindsight/.pg0" \
      ghcr.io/vectorize-io/hindsight:latest
    echo "    Started. API: http://localhost:8888  ·  UI: http://localhost:9999"
  fi
else
  echo "==> Hindsight server start disabled (HINDSIGHT_START_SERVER != true)."
  echo "    Client installed. To run the server later (needs Docker + LLM key):"
  echo "      docker run --rm -d --pull always -p 8888:8888 -p 9999:9999 \\"
  echo "        -e HINDSIGHT_API_LLM_PROVIDER=${HINDSIGHT_LLM_PROVIDER:-openai} \\"
  echo "        -e HINDSIGHT_API_LLM_API_KEY=<your-key> \\"
  echo "        -v \$HOME/.hindsight-docker:/home/hindsight/.pg0 \\"
  echo "        ghcr.io/vectorize-io/hindsight:latest"
fi

echo "==> Hindsight step complete."
