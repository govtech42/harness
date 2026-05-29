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
# $1 = marketplace spec (e.g. "obra/superpowers-marketplace")
# $2 = plugin spec      (e.g. "superpowers@superpowers-marketplace")
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

# Install Tech Leads Club agent-skills — a curated, security-validated skill
# registry. Runs the CLI non-interactively (`install --skill … --agent …`).
# $1 = space-separated skill names, $2 = space-separated agent identifiers.
# Skills are installed globally (user home) so every project sees them.
# Upstream: https://github.com/tech-leads-club/agent-skills
install_agent_skills() {
  local skills="$1"
  local agents="$2"
  if ! command -v npx >/dev/null 2>&1; then
    echo "ERROR: npx not on PATH — agent-skills requires Node.js >= 22."
    return 1
  fi
  if [[ -z "$skills" || -z "$agents" ]]; then
    echo "WARN: no skills or agents resolved — skipping agent-skills."
    return 0
  fi
  echo "==> Installing agent-skills (global) → agents: $agents"
  echo "    skills: $skills"
  # Intentional word-splitting: each name becomes a separate --skill/--agent arg.
  # shellcheck disable=SC2086
  npx --yes @tech-leads-club/agent-skills install \
    --global \
    --skill $skills \
    --agent $agents
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
