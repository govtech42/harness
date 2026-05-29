#!/usr/bin/env bash
# ============================================================
# 09-plugins.sh — install superpowers + OpenSpec + official plugins.
#
# Coverage matrix:
#   superpowers  → Claude (headless), Codex/Cursor/OpenCode (manual hints),
#                  Antigravity (option (b) per RECOMMENDATIONS: no attempt,
#                  just print hint with the warning that it is not officially
#                  documented).
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

# shellcheck source=../../lib/plugins.sh
source "$REPO_ROOT/lib/plugins.sh"

export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

# --- superpowers (multi-CLI) ----------------------------------------------
if [[ "${INSTALL_SUPERPOWERS:-false}" == "true" ]]; then

  if [[ "${SUPERPOWERS_CLAUDE:-true}" == "true" && "${INSTALL_CLAUDE:-true}" == "true" ]]; then
    install_claude_plugin "obra/superpowers-marketplace" "superpowers@superpowers-marketplace"
  fi

  if [[ "${SUPERPOWERS_CODEX:-true}" == "true" && "${INSTALL_CODEX:-false}" == "true" ]]; then
    print_manual_install_hint "Codex CLI" \
      "/plugins  →  search 'superpowers'  →  Install Plugin"
  fi

  if [[ "${SUPERPOWERS_CURSOR:-true}" == "true" && "${INSTALL_CURSOR:-false}" == "true" ]]; then
    print_manual_install_hint "Cursor agent CLI" \
      "/add-plugin superpowers"
  fi

  if [[ "${SUPERPOWERS_OPENCODE:-true}" == "true" && "${INSTALL_OPENCODE:-false}" == "true" ]]; then
    print_manual_install_hint "OpenCode" \
      "Tell OpenCode:  Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md"
  fi

  if [[ "${SUPERPOWERS_ANTIGRAVITY:-false}" == "true" && "${INSTALL_ANTIGRAVITY:-false}" == "true" ]]; then
    # Option (b) from .claude/RECOMMENDATIONS-style decision: no blind attempt.
    print_manual_install_hint "Google Antigravity CLI" \
      "(NOT OFFICIALLY DOCUMENTED) Try the Gemini-CLI pattern manually:  antigravity extensions install https://github.com/obra/superpowers"
    echo "WARN: Antigravity superpowers integration is not officially documented."
    echo "      The hint above mirrors the Gemini CLI pattern — it may or may not work."
  fi
fi

# --- OpenSpec (universal: works in any AI CLI via slash commands) ----------
if [[ "${INSTALL_OPENSPEC:-false}" == "true" ]]; then
  install_openspec
  # Telemetry off by default unless operator opts in.
  if ! grep -q 'OPENSPEC_TELEMETRY' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<EOF

# OpenSpec
export OPENSPEC_TELEMETRY="${OPENSPEC_TELEMETRY:-0}"
EOF
  fi
fi

# --- agent-skills (Tech Leads Club curated registry) ----------------------
# Security-validated skills installed across the AI CLIs that support them.
# Default skill set is curated for the MiranteGov / Municipium stack
# (Next.js + React Native, NestJS + Nx monorepo, GovTech a11y + security).
# Override AGENT_SKILLS_LIST / AGENT_SKILLS_AGENTS in .env to customize.
if [[ "${INSTALL_AGENT_SKILLS:-false}" == "true" ]]; then
  # Curated default set (GovTech web/mobile stack). Override in .env.
  AGENT_SKILLS_DEFAULT="accessibility web-quality-audit react-best-practices \
security-best-practices security-threat-model security-ownership-map \
nestjs-modular-monolith react-native-expert gh-address-comments docs-writer \
tactical-ddd modular-design-principles domain-analysis coupling-analysis \
react-composition-patterns frontend-blueprint nx-workspace nx-generate \
nx-run-tasks nx-ci-monitor gh-fix-ci mermaid-studio frontend-design \
core-web-vitals perf-web-optimization sentry create-adr create-rfc \
technical-design-doc-creator"
  AGENT_SKILLS_LIST="${AGENT_SKILLS_LIST:-$AGENT_SKILLS_DEFAULT}"
  # Only target agents that are actually installed.
  resolved_agents=""
  for pair in "claude-code:${INSTALL_CLAUDE:-true}" \
              "codex:${INSTALL_CODEX:-false}" \
              "cursor:${INSTALL_CURSOR:-false}" \
              "opencode:${INSTALL_OPENCODE:-false}"; do
    agent="${pair%%:*}"; enabled="${pair##*:}"
    requested=" ${AGENT_SKILLS_AGENTS:-claude-code codex cursor opencode} "
    if [[ "$enabled" == "true" && "$requested" == *" $agent "* ]]; then
      resolved_agents="${resolved_agents:+$resolved_agents }$agent"
    fi
  done
  if [[ -z "$resolved_agents" ]]; then
    echo "WARN: INSTALL_AGENT_SKILLS=true but no matching CLI is installed — skipping."
  else
    install_agent_skills "$AGENT_SKILLS_LIST" "$resolved_agents"
  fi
fi

# --- Official Anthropic marketplace plugins (Claude-only) -----------------
# These bundle pre-configured MCP servers + skills + slash commands.
# Richer than the raw MCP registrations in 06-mcp.sh; either can be used.
if [[ "${INSTALL_CLAUDE:-true}" == "true" ]]; then
  [[ "${INSTALL_LINEAR_PLUGIN:-false}"    == "true" ]] && install_official_claude_plugin linear
  [[ "${INSTALL_SLACK_PLUGIN:-false}"     == "true" ]] && install_official_claude_plugin slack
  [[ "${INSTALL_GITHUB_PLUGIN:-false}"    == "true" ]] && install_official_claude_plugin github
  [[ "${INSTALL_NOTION_PLUGIN:-false}"    == "true" ]] && install_official_claude_plugin notion
  [[ "${INSTALL_ATLASSIAN_PLUGIN:-false}" == "true" ]] && install_official_claude_plugin atlassian
  [[ "${INSTALL_ASANA_PLUGIN:-false}"     == "true" ]] && install_official_claude_plugin asana
  [[ "${INSTALL_FIGMA_PLUGIN:-false}"     == "true" ]] && install_official_claude_plugin figma
  [[ "${INSTALL_SENTRY_PLUGIN:-false}"    == "true" ]] && install_official_claude_plugin sentry
  [[ "${INSTALL_SUPABASE_PLUGIN:-false}"  == "true" ]] && install_official_claude_plugin supabase
  [[ "${INSTALL_VERCEL_PLUGIN:-false}"    == "true" ]] && install_official_claude_plugin vercel
fi

echo
echo "==> Plugins step complete."
