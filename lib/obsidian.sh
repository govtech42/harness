#!/usr/bin/env bash
# ============================================================
# lib/obsidian.sh — shared helpers for an Obsidian vault that all CLI
# agents (Claude, Codex, Antigravity, Cursor) read/write together.
#
# Designed for headless VPS use: no Obsidian app, no Local REST API.
# Vault is plain markdown on disk; optional git remote provides sync.
# Conflict strategy on auto-sync: `-X ours` (local always wins).
# ============================================================

# Expected env vars (see profiles/cli-bundle/.env.example):
#   OBSIDIAN_VAULT_DIR
#   OBSIDIAN_VAULT_REPO          (optional; triggers git clone)
#   OBSIDIAN_VAULT_BRANCH        (default: main)
#   OBSIDIAN_AUTOSYNC            (true/false; opt-in)
#   OBSIDIAN_AUTOSYNC_SCHEDULE   (cron expression)

# Sub-directories created at the vault root, one per CLI.
OBSIDIAN_CLI_DIRS=(.claude .codex .antigravity .cursor)

# --- vault skeleton --------------------------------------------------------

setup_vault() {
  local dir="${OBSIDIAN_VAULT_DIR:-$HOME/vault}"
  local repo="${OBSIDIAN_VAULT_REPO:-}"
  local branch="${OBSIDIAN_VAULT_BRANCH:-main}"

  if [[ -n "$repo" && ! -d "$dir/.git" ]]; then
    echo "==> Cloning vault from $repo"
    git clone --branch "$branch" "$repo" "$dir" || git clone "$repo" "$dir"
  else
    mkdir -p "$dir"
  fi

  # Per-CLI dirs at the vault root + a log file each.
  local cli
  for cli in "${OBSIDIAN_CLI_DIRS[@]}"; do
    mkdir -p "$dir/$cli"
    [[ -f "$dir/$cli/log.md" ]] || cat > "$dir/$cli/log.md" <<EOF
# ${cli#.} — agent log

One entry per session. Use this dir as the agent's working space.
EOF
  done

  mkdir -p "$dir/notes"
  [[ -f "$dir/inbox.md" ]] || cat > "$dir/inbox.md" <<'EOF'
# Inbox

Capture anything here. Any CLI agent may append.
EOF

  # Minimal Obsidian config so the workstation app opens the vault cleanly.
  mkdir -p "$dir/.obsidian"
  [[ -f "$dir/.obsidian/app.json" ]] || cat > "$dir/.obsidian/app.json" <<'EOF'
{
  "alwaysUpdateLinks": true,
  "newLinkFormat": "shortest",
  "promptDelete": false
}
EOF

  # Per-machine state shouldn't be versioned.
  if [[ ! -f "$dir/.gitignore" ]]; then
    cat > "$dir/.gitignore" <<'EOF'
# Per-machine Obsidian state — not portable across hosts.
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/cache
.obsidian/plugins/*/data.json
.trash/
EOF
  fi

  # Export the vault path system-wide for child shells + cron + systemd units.
  if ! grep -q 'OBSIDIAN_VAULT_DIR' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<EOF

# Obsidian vault shared by every CLI agent.
export OBSIDIAN_VAULT_DIR="$dir"
alias cdvault='cd "\$OBSIDIAN_VAULT_DIR"'
EOF
  fi

  echo "==> Vault ready at $dir"
}

# --- git sync --------------------------------------------------------------

# One-shot sync. Always uses `-X ours`: local edits win over remote on
# conflict (chosen for VPS-with-multiple-agents scenarios — silent loss of
# remote bits is preferred over losing in-flight agent work).
sync_vault_now() {
  local dir="${OBSIDIAN_VAULT_DIR:-$HOME/vault}"
  if [[ ! -d "$dir/.git" ]]; then
    echo "vault not a git repo — skipping sync"
    return 0
  fi

  cd "$dir" || return 1
  local host
  host="$(hostname -s)"
  local ts
  ts="$(date -Iseconds)"

  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "auto: ${host} @ ${ts}" >/dev/null
  fi

  # Pull with ours-merge; never fast-forward into a divergent state silently.
  git fetch origin
  if ! git merge --no-edit -X ours "origin/$(git rev-parse --abbrev-ref HEAD)" 2>&1; then
    echo "vault sync: merge failed (-X ours did not resolve) — leaving working tree dirty"
    return 1
  fi

  git push origin HEAD 2>&1 || {
    echo "vault sync: push failed (no remote? auth? offline?)"
    return 1
  }
}

# Install a user-cron entry that calls sync_vault_now via a wrapper.
# Marker `# obsidian-vault-sync` lets the entry be replaced idempotently.
sync_vault_install() {
  local schedule="${OBSIDIAN_AUTOSYNC_SCHEDULE:-*/15 * * * *}"
  local wrapper="$HOME/.local/bin/obsidian-vault-sync"
  mkdir -p "$HOME/.local/bin"

  cat > "$wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export OBSIDIAN_VAULT_DIR="${OBSIDIAN_VAULT_DIR:-\$HOME/vault}"
LOG="\$OBSIDIAN_VAULT_DIR/.claude/sync.log"
mkdir -p "\$(dirname "\$LOG")"
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/obsidian.sh"
{
  echo "----- \$(date -Iseconds) -----"
  sync_vault_now
} >> "\$LOG" 2>&1
EOF
  chmod 700 "$wrapper"

  local tmp
  tmp="$(mktemp)"
  crontab -l 2>/dev/null | grep -v 'obsidian-vault-sync' > "$tmp" || true
  echo "$schedule $wrapper  # obsidian-vault-sync" >> "$tmp"
  crontab "$tmp"
  rm -f "$tmp"

  echo "==> Auto-sync cron installed ($schedule)"
}

sync_vault_uninstall() {
  local tmp
  tmp="$(mktemp)"
  crontab -l 2>/dev/null | grep -v 'obsidian-vault-sync' > "$tmp" || true
  crontab "$tmp"
  rm -f "$tmp"
  rm -f "$HOME/.local/bin/obsidian-vault-sync"
  echo "==> Auto-sync removed"
}
