#!/usr/bin/env bash
# tests/check_env_completeness.sh
# Verifies every env var referenced inside profile scripts is documented in
# that profile's .env.example. Catches drift between code and config.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail=0

# Vars we deliberately don't require in .env.example:
#  - HOME, USER, PATH, BATS_*, BASH_*: shell built-ins
#  - HARNESS_MARKER: internal to lib/common.sh
#  - INSTALL_DIR, SCRIPT_DIR, REPO_ROOT, ENV_FILE, FORCE, etc: script locals
#  - SC*: shellcheck directives, not env
EXCLUDE_REGEX='^(HOME|USER|PATH|SHELL|EUID|UID|PWD|OLDPWD|BATS_.*|BASH_.*|HARNESS_MARKER|SCRIPT_DIR|REPO_ROOT|ENV_FILE|FORCE|SCOPE|VERSION|PORT|TIMEZONE|SWAP_SIZE_GB|MCP_SCOPE|NODE_MAJOR|PNPM_VERSION|BASE_PACKAGES|BASE_PACKAGES_DEFAULT|INSTALL_DIR|REPO|BRANCH|MAX_LOG_BYTES|MAX|TMP_CRON|SCHEDULE|DREAM_DIR|WRAPPER|LOG|DEFAULT_PROMPT|USER_PROMPT|FS_PATHS|CFG_DIR|CFG_FILE|PNPM_BIN|FILESYSTEM_PATHS|DREAM_SCHEDULE|DREAM_PROMPT|SC[0-9]+)$'

extract_install_vars() {
  # INSTALL_FOO toggles — include digits (INSTALL_CONTEXT7 etc.)
  grep -hoE '\bINSTALL_[A-Z0-9_]+' "$@" 2>/dev/null | sort -u
}

extract_profile_vars() {
  # Profile-specific vars referenced as ${FOO:-...} or ${FOO}
  grep -hoE '\$\{[A-Z][A-Z0-9_]*' "$@" 2>/dev/null \
    | sed 's/^\${//' \
    | sort -u
}

check_profile() {
  local dir="$1"
  local example="$dir/.env.example"
  if [[ ! -f "$example" ]]; then
    echo "  SKIP $dir (no .env.example)"
    return
  fi

  local scripts=()
  while IFS= read -r f; do scripts+=("$f"); done < <(find "$dir" -maxdepth 1 -name '*.sh')

  local missing=()
  while read -r var; do
    [[ -z "$var" ]] && continue
    [[ "$var" =~ $EXCLUDE_REGEX ]] && continue
    if ! grep -q "^${var}=" "$example"; then
      missing+=("$var")
    fi
  done < <( { extract_install_vars "${scripts[@]}"; extract_profile_vars "${scripts[@]}"; } | sort -u)

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "  FAIL $dir"
    for m in "${missing[@]}"; do echo "       missing in .env.example: $m"; done
    fail=1
  else
    echo "  ok  $dir"
  fi
}

echo "==> env completeness check"
for prof in profiles/*/; do
  check_profile "${prof%/}"
done

if [[ $fail -ne 0 ]]; then
  echo
  echo "==> env completeness FAILED"
  exit 1
fi
echo
echo "==> env completeness OK"
