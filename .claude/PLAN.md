# harness — architecture plan

## Goal
One repo, four mutually-exclusive VPS install profiles for AI coding agents.
Same idempotent-shell-script convention across all profiles. Single
top-level launcher picks the profile and enforces a one-per-host mutex.

## Profile matrix

| Profile      | Components                                        | Coexist? |
|--------------|---------------------------------------------------|----------|
| cli-bundle   | Claude Code, Codex, Antigravity, Cursor (CLIs)    | Yes (4)  |
| openclaw     | OpenClaw local agent                              | No       |
| hermes       | Nous Hermes Agent                                 | No       |
| paperclip    | Paperclip                                         | No       |

CLI tools in `cli-bundle` are independent binaries with disjoint config dirs
(`~/.claude`, `~/.codex`, `~/.antigravity`, `~/.cursor`). They share only
the npm-global prefix and the system PATH, both managed by `01-system.sh`.

Single-agent profiles each take over `$HOME` for their own clone +
optional systemd unit. Running two on the same host is unsupported.

## Directory layout

```
harness/
├── install.sh                 # launcher
├── lib/common.sh              # load_env, mutex_check, mutex_set, banner
├── profiles/
│   ├── cli-bundle/
│   │   ├── install.sh         # orchestrates 01..07
│   │   ├── 01-system.sh       # apt + node + swap + tz
│   │   ├── 02-claude.sh
│   │   ├── 03-codex.sh
│   │   ├── 04-antigravity.sh
│   │   ├── 05-cursor.sh
│   │   ├── 06-mcp.sh          # MCP servers (Claude only)
│   │   ├── 07-dream.sh        # cron memory consolidation (Claude only)
│   │   ├── .env.example
│   │   └── README.md
│   ├── openclaw/
│   ├── hermes/
│   └── paperclip/             # each: install.sh, 01-system.sh, 02-<name>.sh, .env.example, README.md
├── README.md
└── .claude/
    ├── PLAN.md                # this file
    ├── TODO.md                # what's still scaffolded
    └── profiles/              # per-profile research notes
        ├── cli-bundle.md
        ├── openclaw.md
        ├── hermes.md
        └── paperclip.md
```

## Mutex contract

- File: `~/.harness-profile` (chmod 600), contents = profile name.
- Written by `mutex_set` at end of each profile install.
- Checked by `mutex_check` at start of the launcher AND the profile install.
- Override flag: `--force` (logged as WARN, not silent).
- No automatic uninstall on override — operator must clean up.

## Why one profile per host

- Port clashes (multiple agent daemons on 8080/3000 ranges)
- PATH ambiguity between competing `agent` binaries
- systemd unit name collisions
- Memory pressure on small VPS (2 GB) when stacking model runtimes
- Telemetry / .env leakage across stacks

## CLI bundle rationale

The four CLIs in `cli-bundle` are thin clients that talk to remote model APIs.
Footprint is small (each ~50 MB on disk, idle), no daemons, no port binds.
Stacking them on one VPS is a legitimate dev-station pattern.

## Idempotency rules

- Every script: `set -euo pipefail`.
- Re-running must converge, not duplicate state.
  - `mkdir -p`, `grep -q` before appending to rc files
  - `git pull --ff-only` on existing clones
  - `claude mcp remove` before `claude mcp add`
  - cron entries gated by `# claude-dream` marker
- Re-running with different toggles in `.env` must add/remove cleanly.

## Security defaults

- `chmod 600 .env` enforced by the loader
- `chmod 600 ~/.bashrc` after writing API keys
- npm globals user-local (no sudo)
- Swap file chmod 600
- TODO: optional UFW + fail2ban hardening (see TODO.md)

## Not in scope (yet)

- Multi-host orchestration (Ansible/Terraform)
- Container images (Dockerfile per profile)
- Automated provider-key rotation
- Coexistence shims between profiles
