#!/usr/bin/env bash
# tests/lint.sh — syntax check + shellcheck across every .sh in the repo.
# Exit non-zero on any failure. Used by CI and pre-commit.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Discover scripts (skip .git, node_modules, anything generated).
SCRIPTS=()
while IFS= read -r f; do
  SCRIPTS+=("$f")
done < <(find . \
  -type d \( -name .git -o -name node_modules \) -prune -o \
  -type f -name '*.sh' -print | sort)

if [[ ${#SCRIPTS[@]} -eq 0 ]]; then
  echo "ERROR: no .sh files found"
  exit 1
fi

echo "==> bash -n syntax check (${#SCRIPTS[@]} files)"
fail=0
for f in "${SCRIPTS[@]}"; do
  if bash -n "$f" 2>&1; then
    echo "  ok  $f"
  else
    echo "  FAIL $f"
    fail=1
  fi
done

if ! command -v shellcheck >/dev/null 2>&1; then
  echo
  echo "WARN: shellcheck not installed — skipping deep lint."
  echo "      Install: sudo apt-get install -y shellcheck   (or brew install shellcheck)"
  [[ $fail -eq 0 ]] && exit 0 || exit 1
fi

echo
echo "==> shellcheck (severity=warning, follows sourced files)"
# -x: follow sourced files
# -S warning: report errors + warnings, ignore style/info
# -e SC1091: ignore "not following: ..." for .env (it's runtime data, not code)
for f in "${SCRIPTS[@]}"; do
  # SC1090/SC1091: sourced files we don't want shellcheck to follow (runtime .env, etc.)
  if shellcheck -x -S warning -e SC1090,SC1091 "$f"; then
    echo "  ok  $f"
  else
    echo "  FAIL $f"
    fail=1
  fi
done

if [[ $fail -ne 0 ]]; then
  echo
  echo "==> lint FAILED"
  exit 1
fi
echo
echo "==> lint OK"
