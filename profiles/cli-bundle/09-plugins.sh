#!/usr/bin/env bash
# ============================================================
# 09-plugins.sh — install GSD, gstack, superpowers across the CLIs.
#
# Coverage matrix:
#   GSD          → Claude only
#   gstack       → Claude, OpenCode (and any host listed in GSTACK_TARGETS)
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
# shellcheck source=../../lib/base-packages.sh
source "$REPO_ROOT/lib/base-packages.sh"

export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.bun/bin:$PATH"

# --- GSD (Claude only) ----------------------------------------------------
if [[ "${INSTALL_GSD:-false}" == "true" ]]; then
  if [[ "${INSTALL_CLAUDE:-true}" != "true" ]]; then
    echo "WARN: INSTALL_GSD=true but Claude not installed — skipping."
  else
    install_claude_plugin "jnuyens/gsd-plugin" "gsd@gsd-plugin"
  fi
fi

# --- gstack (Claude + any host in GSTACK_TARGETS) -------------------------
if [[ "${INSTALL_GSTACK:-false}" == "true" ]]; then
  install_bun
  TARGETS="${GSTACK_TARGETS:-claude}"
  for host in $TARGETS; do
    case "$host" in
      claude)
        if [[ "${INSTALL_CLAUDE:-true}" != "true" ]]; then
          echo "WARN: gstack target 'claude' requested but INSTALL_CLAUDE != true. Skipping."
          continue
        fi
        ;;
      opencode)
        if [[ "${INSTALL_OPENCODE:-false}" != "true" ]]; then
          echo "WARN: gstack target 'opencode' requested but INSTALL_OPENCODE != true. Skipping."
          continue
        fi
        ;;
    esac
    install_gstack_for "$host"
  done
fi

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

echo
echo "==> Plugins step complete."
