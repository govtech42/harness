#!/usr/bin/env bats
# tests/test_mission_control.bats — unit tests for lib/mission-control.sh.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  # shellcheck source=../lib/mission-control.sh
  source "$REPO_ROOT/lib/mission-control.sh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "install_mission_control: no-op when toggle is false" {
  INSTALL_MISSION_CONTROL=false run install_mission_control
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
  [ ! -d "$TEST_HOME/mission-control" ]
}

@test "install_mission_control: no-op when toggle unset" {
  run install_mission_control
  [ "$status" -eq 0 ]
  [[ "$output" == *"disabled"* ]]
}
