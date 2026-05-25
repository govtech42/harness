#!/usr/bin/env bash
# ============================================================
# lib/plugins.sh — install Claude Code plugins (and friends) headlessly.
#
# Most plugin markets are interactive (`/plugin install …` typed inside a
# CLI session). Where headless is supported, we drive it via `claude -p`
# with --dangerously-skip-permissions. Elsewhere we print a manual hint
# the operator pastes into the relevant CLI.
# ============================================================

# Run a Claude Code slash command headless and return its exit code.
# $1 = prompt (typically a slash command like `/plugin install foo`)
claude_headless() {
  local prompt="$1"
  if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: 'claude' not on PATH — install Claude Code first."
    return 1
  fi
  claude -p "$prompt" --dangerously-skip-permissions
}

# Install a plugin from the official Anthropic marketplace
# (always available; no `marketplace add` needed).
# $1 = plugin name (e.g. "linear", "slack", "github")
install_official_claude_plugin() {
  local name="$1"
  echo "==> Claude official plugin: $name"
  claude_headless "/plugin install ${name}@claude-plugins-official"
  claude_headless "/reload-plugins" || true
}

# Install a Claude Code plugin from a marketplace.
# $1 = marketplace spec (e.g. "jnuyens/gsd-plugin" or "obra/superpowers-marketplace")
# $2 = plugin spec      (e.g. "gsd@gsd-plugin" or "superpowers@claude-plugins-official")
install_claude_plugin() {
  local marketplace="$1"
  local plugin="$2"
  echo "==> Claude plugin: marketplace=$marketplace plugin=$plugin"
  # Marketplace add is idempotent in Claude Code; install is too (re-runs fine).
  claude_headless "/plugin marketplace add $marketplace" || true
  claude_headless "/plugin install $plugin"
  claude_headless "/reload-plugins" || true
}

# Install OpenSpec — spec-driven development CLI. npm-global; works inside
# any AI assistant via /opsx:* slash commands (no per-CLI binding).
# Upstream: https://github.com/Fission-AI/OpenSpec
install_openspec() {
  local version="${OPENSPEC_VERSION:-latest}"
  if ! command -v npm >/dev/null 2>&1; then
    echo "ERROR: npm not on PATH — OpenSpec requires Node.js."
    return 1
  fi
  echo "==> Installing @fission-ai/openspec@${version} globally"
  npm install -g "@fission-ai/openspec@${version}"
  openspec --version 2>/dev/null || true
}

# Install gstack into a target CLI's skills dir.
# $1 = host name (claude, opencode, etc.)
install_gstack_for() {
  local host="$1"
  local target_dir="$HOME/.${host}/skills/gstack"
  echo "==> Installing gstack for $host → $target_dir"

  if [[ -d "$target_dir/.git" ]]; then
    git -C "$target_dir" fetch --depth 1 origin
    git -C "$target_dir" reset --hard origin/HEAD
  else
    git clone --single-branch --depth 1 \
      https://github.com/garrytan/gstack.git "$target_dir"
  fi

  pushd "$target_dir" >/dev/null || return 1
  if [[ -x ./setup ]]; then
    if [[ "$host" == "claude" ]]; then
      ./setup
    else
      ./setup --host "$host"
    fi
  else
    echo "WARN: gstack/setup not found or not executable"
  fi
  popd >/dev/null || return 1
}

# Tell the operator exactly what to type into a non-headless CLI.
print_manual_install_hint() {
  local cli="$1"
  local instruction="$2"
  cat <<EOF

----------------------------------------------------------------
MANUAL STEP REQUIRED — $cli
----------------------------------------------------------------
Open a $cli session, then run:

    $instruction

This CLI does not expose a headless plugin-install path; the step
has to be performed interactively.
----------------------------------------------------------------
EOF
}
