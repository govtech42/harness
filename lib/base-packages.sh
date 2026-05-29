#!/usr/bin/env bash
# ============================================================
# lib/base-packages.sh — shared system packages and DB clients.
# Source from a profile's 01-system.sh:
#   source "$REPO_ROOT/lib/base-packages.sh"
#   install_base_packages
#   install_db_clients
# ============================================================

# Common Linux tooling expected on any agent host.
# Override the list with $BASE_PACKAGES in .env if needed.
BASE_PACKAGES_DEFAULT=(
  # network
  curl wget ca-certificates openssh-client dnsutils net-tools lsof
  # vcs + build
  git build-essential pkg-config
  # terminal multiplexer + editors
  tmux screen vim nano less man-db
  # archive
  unzip zip tar rsync xz-utils gzip
  # parsing + search
  jq tree ripgrep fd-find fzf
  # observability
  htop ncdu iotop sysstat
  # python (used by many agent harnesses for venvs and tools)
  python3 python3-pip python3-venv
)

install_base_packages() {
  echo "==> apt update + upgrade"
  sudo apt-get update -y
  sudo apt-get -o Dpkg::Options::="--force-confnew" upgrade -y

  local pkgs=("${BASE_PACKAGES_DEFAULT[@]}")
  if [[ -n "${BASE_PACKAGES:-}" ]]; then
    # shellcheck disable=SC2206
    pkgs=($BASE_PACKAGES)
  fi

  echo "==> Installing base packages: ${pkgs[*]}"
  sudo apt-get install -y "${pkgs[@]}"
}

# PostgreSQL client (psql). Toggle: INSTALL_POSTGRES_CLIENT=true
install_postgres_client() {
  if [[ "${INSTALL_POSTGRES_CLIENT:-true}" != "true" ]]; then
    echo "==> Postgres client disabled."
    return 0
  fi
  echo "==> Installing postgresql-client"
  sudo apt-get install -y postgresql-client
  psql --version
}

# ClickHouse client. Toggle: INSTALL_CLICKHOUSE_CLIENT=true
# Uses the official ClickHouse deb repo with signed keyring.
install_clickhouse_client() {
  if [[ "${INSTALL_CLICKHOUSE_CLIENT:-true}" != "true" ]]; then
    echo "==> ClickHouse client disabled."
    return 0
  fi
  echo "==> Installing clickhouse-client (official repo)"
  sudo apt-get install -y apt-transport-https gnupg

  local keyring=/etc/apt/keyrings/clickhouse-keyring.gpg
  sudo mkdir -p /etc/apt/keyrings
  if [[ ! -f "$keyring" ]]; then
    curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' \
      | sudo gpg --dearmor -o "$keyring"
  fi

  local listfile=/etc/apt/sources.list.d/clickhouse.list
  if [[ ! -f "$listfile" ]]; then
    echo "deb [signed-by=$keyring] https://packages.clickhouse.com/deb stable main" \
      | sudo tee "$listfile" >/dev/null
  fi

  sudo apt-get update -y
  sudo apt-get install -y clickhouse-client
  clickhouse-client --version
}

# NodeSource Node.js install. Pass major version as $1 (default 20).
install_node() {
  local major="${1:-20}"
  if command -v node >/dev/null 2>&1; then
    local current
    current="$(node -v | sed 's/v\([0-9]*\).*/\1/')"
    if [[ "$current" -ge "$major" ]]; then
      echo "==> Node $(node -v) already installed (>= $major)"
      return 0
    fi
  fi
  echo "==> Installing Node.js ${major}.x via NodeSource"
  curl -fsSL "https://deb.nodesource.com/setup_${major}.x" | sudo -E bash -
  sudo apt-get install -y nodejs
  node -v
}

# Install pnpm via corepack (ships with Node 16+).
install_pnpm() {
  local version="${1:-latest}"
  if command -v pnpm >/dev/null 2>&1; then
    echo "==> pnpm $(pnpm -v) already installed"
    return 0
  fi
  echo "==> Enabling pnpm via corepack ($version)"
  sudo corepack enable
  corepack prepare "pnpm@${version}" --activate || sudo corepack prepare "pnpm@${version}" --activate
  pnpm -v
}

# Install uv (Python package manager used by Hermes).
install_uv() {
  if command -v uv >/dev/null 2>&1; then
    echo "==> uv $(uv --version) already installed"
    return 0
  fi
  echo "==> Installing uv (astral.sh)"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
}

# Convenience wrapper.
# Install a headless-capable browser via apt. Tries chromium-browser then
# chromium; logs a warning if neither package is reachable (some minimal
# Ubuntu images route chromium-browser through snap and offer no apt
# alternative — in that case Playwright's bundled Chromium covers the gap
# when INSTALL_PLAYWRIGHT=true).
install_headless_browser() {
  if [[ "${INSTALL_HEADLESS_BROWSER:-true}" != "true" ]]; then
    echo "==> Headless browser disabled (INSTALL_HEADLESS_BROWSER != true)."
    return 0
  fi
  if command -v chromium-browser >/dev/null 2>&1 \
     || command -v chromium >/dev/null 2>&1 \
     || command -v google-chrome >/dev/null 2>&1; then
    echo "==> Headless browser already present"
    return 0
  fi
  echo "==> Installing headless browser (chromium via apt)"
  if sudo apt-get install -y chromium-browser 2>/dev/null; then
    return 0
  fi
  if sudo apt-get install -y chromium 2>/dev/null; then
    return 0
  fi
  echo "WARN: no chromium apt package available."
  echo "      Playwright's bundled Chromium will be used if INSTALL_PLAYWRIGHT=true."
}

install_db_clients() {
  if [[ "${INSTALL_DB_CLIENTS:-true}" != "true" ]]; then
    echo "==> DB clients disabled (INSTALL_DB_CLIENTS != true)."
    return 0
  fi
  install_postgres_client
  install_clickhouse_client
}
