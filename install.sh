#!/usr/bin/env bash
# ============================================================
# install.sh — top-level launcher.
# Usage:
#   ./install.sh                  # interactive menu
#   ./install.sh <profile>        # direct (cli-bundle|openclaw|hermes|paperclip)
#   ./install.sh <profile> --force
#   ./install.sh --status         # show installed profile
# ============================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$REPO_ROOT/lib/common.sh"

PROFILES=(cli-bundle openclaw hermes paperclip)

usage() {
  cat <<EOF
Usage: ./install.sh [profile] [--force]
       ./install.sh --status
       ./install.sh --help

Profiles:
  cli-bundle   Claude Code + Codex + Antigravity + Cursor CLIs (coexist)
  openclaw     OpenClaw — local agent
  hermes       Hermes Agent (Nous Research) — local
  paperclip    Paperclip — local agent

Only one profile per host. Use --force to override (not recommended).
EOF
}

status() {
  if [[ -f "$HARNESS_MARKER" ]]; then
    echo "Installed profile: $(cat "$HARNESS_MARKER")"
    echo "Marker:            $HARNESS_MARKER"
  else
    echo "No profile installed yet."
  fi
}

run_profile() {
  local profile="$1"; shift || true
  local force="${1:-}"
  local dir="$REPO_ROOT/profiles/$profile"

  if [[ ! -d "$dir" ]]; then
    echo "ERROR: profile '$profile' not found at $dir"
    exit 1
  fi
  if [[ ! -x "$dir/install.sh" && ! -f "$dir/install.sh" ]]; then
    echo "ERROR: profile '$profile' has no install.sh"
    exit 1
  fi

  mutex_check "$profile" "$force"
  banner "Installing profile: $profile"
  bash "$dir/install.sh" "$force"
  mutex_set "$profile"
  banner "Done: $profile"
}

# --- arg parsing ---
case "${1:-}" in
  -h|--help)    usage; exit 0 ;;
  --status)     status; exit 0 ;;
  "")           ;; # fall through to menu
  *)
    profile="$1"
    force="${2:-}"
    if [[ ! " ${PROFILES[*]} " == *" $profile "* ]]; then
      echo "ERROR: unknown profile '$profile'"
      usage; exit 1
    fi
    run_profile "$profile" "$force"
    exit 0
    ;;
esac

# --- interactive menu ---
status
echo
echo "Pick a profile to install:"
select choice in "${PROFILES[@]}" "Quit"; do
  case "$choice" in
    "")        echo "Invalid"; continue ;;
    Quit)      exit 0 ;;
    *)         run_profile "$choice"; break ;;
  esac
done
