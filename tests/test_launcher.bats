#!/usr/bin/env bats
# tests/test_launcher.bats — black-box tests for ./install.sh.
# Runs the launcher in an isolated $HOME so mutex_set doesn't leak.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export HARNESS_MARKER="$TEST_HOME/.harness-profile"
  LAUNCHER="$REPO_ROOT/install.sh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "launcher: --help prints usage and exits 0" {
  run "$LAUNCHER" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"cli-bundle"* ]]
  [[ "$output" == *"openclaw"* ]]
  [[ "$output" == *"hermes"* ]]
  [[ "$output" == *"paperclip"* ]]
}

@test "launcher: --status with no marker reports clean" {
  run "$LAUNCHER" --status
  [ "$status" -eq 0 ]
  [[ "$output" == *"No profile installed"* ]]
}

@test "launcher: --status with marker reports profile name" {
  echo "openclaw" > "$HARNESS_MARKER"
  run "$LAUNCHER" --status
  [ "$status" -eq 0 ]
  [[ "$output" == *"openclaw"* ]]
}

@test "launcher: unknown profile fails with usage" {
  run "$LAUNCHER" nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown profile"* ]]
}

@test "launcher: mutex blocks cross-profile install" {
  echo "openclaw" > "$HARNESS_MARKER"
  # Profile dir exists for cli-bundle; mutex_check should trip before any
  # install step runs. We expect exit 2 from mutex_check.
  run "$LAUNCHER" cli-bundle
  [ "$status" -eq 2 ]
  [[ "$output" == *"already installed"* ]]
}
