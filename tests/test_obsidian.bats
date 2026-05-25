#!/usr/bin/env bats
# tests/test_obsidian.bats — unit tests for lib/obsidian.sh.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export OBSIDIAN_VAULT_DIR="$TEST_HOME/vault"
  # shellcheck source=../lib/obsidian.sh
  source "$REPO_ROOT/lib/obsidian.sh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# ---------- setup_vault ----------

@test "setup_vault: creates vault dir + per-CLI subdirs" {
  setup_vault
  [ -d "$OBSIDIAN_VAULT_DIR" ]
  for cli in .claude .codex .antigravity .cursor; do
    [ -d "$OBSIDIAN_VAULT_DIR/$cli" ]
    [ -f "$OBSIDIAN_VAULT_DIR/$cli/log.md" ]
  done
  [ -d "$OBSIDIAN_VAULT_DIR/notes" ]
  [ -f "$OBSIDIAN_VAULT_DIR/inbox.md" ]
  [ -f "$OBSIDIAN_VAULT_DIR/.obsidian/app.json" ]
  [ -f "$OBSIDIAN_VAULT_DIR/.gitignore" ]
}

@test "setup_vault: appends OBSIDIAN_VAULT_DIR export to ~/.bashrc once" {
  setup_vault
  setup_vault   # second call must not duplicate
  local count
  count=$(grep -c '^export OBSIDIAN_VAULT_DIR=' "$HOME/.bashrc")
  [ "$count" -eq 1 ]
}

@test "setup_vault: cdvault alias landed in ~/.bashrc" {
  setup_vault
  grep -q "alias cdvault=" "$HOME/.bashrc"
}

@test "setup_vault: .gitignore excludes per-machine workspace state" {
  setup_vault
  grep -q '\.obsidian/workspace\.json' "$OBSIDIAN_VAULT_DIR/.gitignore"
  grep -q '\.obsidian/cache' "$OBSIDIAN_VAULT_DIR/.gitignore"
}

@test "setup_vault: idempotent on log.md (does not overwrite existing)" {
  setup_vault
  echo "CUSTOM" >> "$OBSIDIAN_VAULT_DIR/.claude/log.md"
  setup_vault
  grep -q "CUSTOM" "$OBSIDIAN_VAULT_DIR/.claude/log.md"
}

# ---------- sync_vault_now ----------

@test "sync_vault_now: no-op when vault is not a git repo" {
  setup_vault
  run sync_vault_now
  [ "$status" -eq 0 ]
  [[ "$output" == *"not a git repo"* ]]
}

@test "sync_vault_now: with local-only git repo commits but exits non-zero on push" {
  setup_vault
  (
    cd "$OBSIDIAN_VAULT_DIR"
    git init -q -b main
    git config user.email "test@example.com"
    git config user.name "test"
    git add -A
    git commit -q -m "init"
    echo "new content" > new.md
  )
  # No remote configured — fetch + push will fail; merge/push step returns 1.
  run sync_vault_now
  # Commit should have happened despite push failure.
  [ -n "$(git -C "$OBSIDIAN_VAULT_DIR" log --oneline | grep auto:)" ]
}
