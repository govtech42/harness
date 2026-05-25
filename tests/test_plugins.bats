#!/usr/bin/env bats
# tests/test_plugins.bats — unit tests for lib/plugins.sh.
# Heavy integration with the real `claude` binary is out of scope here;
# we stub it so we can verify the helpers dispatch correctly.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TEST_HOME="$(mktemp -d)"
  STUB_DIR="$TEST_HOME/bin"
  mkdir -p "$STUB_DIR"
  export HOME="$TEST_HOME"
  export PATH="$STUB_DIR:$PATH"
  # shellcheck source=../lib/plugins.sh
  source "$REPO_ROOT/lib/plugins.sh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# ---------- claude_headless ----------

@test "claude_headless: errors when claude missing" {
  # Isolate PATH to a dir with no `claude` binary.
  PATH="$STUB_DIR" run claude_headless "/help"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not on PATH"* ]]
}

@test "claude_headless: dispatches prompt + flag to claude binary" {
  cat > "$STUB_DIR/claude" <<'EOF'
#!/usr/bin/env bash
echo "ARGS: $*"
EOF
  chmod +x "$STUB_DIR/claude"
  run claude_headless "/plugin install foo@bar"
  [ "$status" -eq 0 ]
  [[ "$output" == *"-p"* ]]
  [[ "$output" == *"/plugin install foo@bar"* ]]
  [[ "$output" == *"--dangerously-skip-permissions"* ]]
}

# ---------- install_claude_plugin ----------

@test "install_official_claude_plugin: install then reload, no marketplace add" {
  CALLS_FILE="$TEST_HOME/calls.txt"
  cat > "$STUB_DIR/claude" <<EOF
#!/usr/bin/env bash
shift  # drop -p
echo "\$1" >> "$CALLS_FILE"
EOF
  chmod +x "$STUB_DIR/claude"
  install_official_claude_plugin "linear"
  [ -f "$CALLS_FILE" ]
  grep -q "/plugin install linear@claude-plugins-official" "$CALLS_FILE"
  grep -q "/reload-plugins" "$CALLS_FILE"
  ! grep -q "marketplace add" "$CALLS_FILE"
}

@test "install_claude_plugin: runs marketplace add then install then reload" {
  CALLS_FILE="$TEST_HOME/calls.txt"
  cat > "$STUB_DIR/claude" <<EOF
#!/usr/bin/env bash
shift  # drop -p
echo "\$1" >> "$CALLS_FILE"
EOF
  chmod +x "$STUB_DIR/claude"
  install_claude_plugin "owner/repo" "name@market"
  [ -f "$CALLS_FILE" ]
  grep -q "/plugin marketplace add owner/repo" "$CALLS_FILE"
  grep -q "/plugin install name@market" "$CALLS_FILE"
  grep -q "/reload-plugins" "$CALLS_FILE"
}

# ---------- print_manual_install_hint ----------

@test "install_openspec: errors when npm missing" {
  PATH="$STUB_DIR" run install_openspec
  [ "$status" -ne 0 ]
  [[ "$output" == *"npm not on PATH"* ]]
}

@test "install_openspec: invokes npm install -g with @fission-ai/openspec" {
  CALLS_FILE="$TEST_HOME/npm-calls.txt"
  cat > "$STUB_DIR/npm" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$CALLS_FILE"
EOF
  chmod +x "$STUB_DIR/npm"
  # Keep /usr/bin + /bin on PATH so the stub's shebang (`env bash`) resolves.
  PATH="$STUB_DIR:/usr/bin:/bin" run install_openspec
  [ -f "$CALLS_FILE" ]
  grep -q "install -g @fission-ai/openspec@latest" "$CALLS_FILE"
}

@test "print_manual_install_hint: prints CLI name and instruction" {
  run print_manual_install_hint "Codex CLI" "/plugins → search"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Codex CLI"* ]]
  [[ "$output" == *"/plugins → search"* ]]
  [[ "$output" == *"MANUAL STEP REQUIRED"* ]]
}
