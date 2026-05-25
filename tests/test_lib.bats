#!/usr/bin/env bats
# tests/test_lib.bats — unit tests for lib/common.sh and lib/base-packages.sh.
# Run: bats tests/test_lib.bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export HARNESS_MARKER="$TEST_HOME/.harness-profile"
  # shellcheck source=../lib/common.sh
  source "$REPO_ROOT/lib/common.sh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# ---------- mutex_check ----------

@test "mutex_check: no marker = allow" {
  run mutex_check "cli-bundle"
  [ "$status" -eq 0 ]
}

@test "mutex_check: same profile = allow" {
  echo "cli-bundle" > "$HARNESS_MARKER"
  run mutex_check "cli-bundle"
  [ "$status" -eq 0 ]
}

@test "mutex_check: different profile without --force = refuse with exit 2" {
  echo "openclaw" > "$HARNESS_MARKER"
  run mutex_check "cli-bundle"
  [ "$status" -eq 2 ]
  [[ "$output" == *"already installed"* ]]
}

@test "mutex_check: different profile with --force = allow with warning" {
  echo "openclaw" > "$HARNESS_MARKER"
  run mutex_check "cli-bundle" "--force"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN"* ]]
  [[ "$output" == *"overriding"* ]]
}

@test "mutex_check: marker with trailing whitespace = matches" {
  printf 'cli-bundle  \n' > "$HARNESS_MARKER"
  run mutex_check "cli-bundle"
  [ "$status" -eq 0 ]
}

# ---------- mutex_set ----------

@test "mutex_set: writes profile name" {
  mutex_set "hermes"
  [ -f "$HARNESS_MARKER" ]
  [ "$(cat "$HARNESS_MARKER")" = "hermes" ]
}

@test "mutex_set: round-trip with mutex_check passes" {
  mutex_set "paperclip"
  run mutex_check "paperclip"
  [ "$status" -eq 0 ]
}

@test "mutex_set: overwrites previous marker" {
  echo "openclaw" > "$HARNESS_MARKER"
  mutex_set "cli-bundle"
  [ "$(cat "$HARNESS_MARKER")" = "cli-bundle" ]
}

# ---------- load_env ----------

@test "load_env: no-op when file missing" {
  run load_env "$TEST_HOME/.env"
  [ "$status" -eq 0 ]
}

@test "load_env: exports variables" {
  cat > "$TEST_HOME/.env" <<EOF
FOO=bar
BAZ="quoted value"
EOF
  load_env "$TEST_HOME/.env"
  [ "$FOO" = "bar" ]
  [ "$BAZ" = "quoted value" ]
}

@test "load_env: chmods file to 600" {
  echo "X=1" > "$TEST_HOME/.env"
  chmod 644 "$TEST_HOME/.env"
  load_env "$TEST_HOME/.env"
  local mode
  mode=$(stat -c '%a' "$TEST_HOME/.env" 2>/dev/null || stat -f '%Lp' "$TEST_HOME/.env")
  [ "$mode" = "600" ]
}

# ---------- banner ----------

@test "banner: prints message between rules" {
  run banner "hello"
  [ "$status" -eq 0 ]
  [[ "$output" == *"hello"* ]]
  [[ "$output" == *"==="* ]]
}
