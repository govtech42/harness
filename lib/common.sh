#!/usr/bin/env bash
# ============================================================
# lib/common.sh — shared helpers for all install profiles.
# Source it from a profile install.sh:
#   source "$REPO_ROOT/lib/common.sh"
# ============================================================

HARNESS_MARKER="${HARNESS_MARKER:-$HOME/.harness-profile}"

# Load a .env file if present (no-op if missing).
load_env() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    set -a; source "$env_file"; set +a
    chmod 600 "$env_file" 2>/dev/null || true
  fi
}

# Refuse to install if a *different* profile is already installed.
# Pass --force as $2 to bypass.
mutex_check() {
  local target="$1"
  local force="${2:-}"
  if [[ -f "$HARNESS_MARKER" ]]; then
    local current
    current="$(cat "$HARNESS_MARKER" 2>/dev/null | tr -d '[:space:]')"
    if [[ -n "$current" && "$current" != "$target" ]]; then
      if [[ "$force" == "--force" ]]; then
        echo "WARN: overriding existing profile '$current' (--force)"
      else
        echo "ERROR: profile '$current' already installed on this host."
        echo "       Refusing to install '$target'."
        echo "       Override:  --force   (not recommended; profiles are not designed to coexist)"
        exit 2
      fi
    fi
  fi
}

# Stamp the marker at end of install.
mutex_set() {
  local target="$1"
  echo "$target" > "$HARNESS_MARKER"
  chmod 600 "$HARNESS_MARKER" 2>/dev/null || true
  echo "==> Marker written: $HARNESS_MARKER = $target"
}

# Pretty banner.
banner() {
  echo "============================================================"
  echo "  $*"
  echo "============================================================"
}
