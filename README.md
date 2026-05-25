# harness

> Idempotent shell-script installers that bootstrap a fresh Ubuntu 22.04 VPS
> for one of four AI-agent stacks, with a one-profile-per-host mutex,
> shared base tooling, and DB clients baked in.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
![Shell: bash](https://img.shields.io/badge/shell-bash-4EAA25)
![Target: Ubuntu 22.04](https://img.shields.io/badge/target-Ubuntu%2022.04-E95420)

## What is this

You rent a Lightsail/Hetzner/DO box. You want **one** of these stacks on it,
fully configured, in a single command:

| Profile      | What you get                                                                              |
|--------------|-------------------------------------------------------------------------------------------|
| `cli-bundle` | Claude Code + OpenAI Codex + Google Antigravity + Cursor CLIs (any combination)           |
| `openclaw`   | [OpenClaw](https://github.com/openclaw/openclaw) — local agent gateway on port `18789`    |
| `hermes`     | [Hermes Agent](https://github.com/NousResearch/hermes-agent) (Nous Research, Python+uv)   |
| `paperclip`  | [Paperclip](https://github.com/paperclipai/paperclip) — Node API + embedded Postgres :3100 |

Plus, on every profile:

- Common Linux toolkit (`tmux`, `git`, `vim`, `jq`, `ripgrep`, `fd`, `fzf`, `htop`, …)
- `psql` (PostgreSQL client) and `clickhouse-client` from the official ClickHouse deb repo
- Timezone, swap file, npm user-global prefix, `~/.bashrc` PATH
- A mutex marker so you don't accidentally stack two agent runtimes on one host

## Repo layout

```
harness/
├── install.sh                 # top-level launcher (menu, arg, --status, --force)
├── lib/
│   ├── common.sh              # mutex_check, mutex_set, load_env, banner
│   └── base-packages.sh       # install_base_packages, install_db_clients,
│                              # install_node, install_pnpm, install_uv
└── profiles/
    ├── cli-bundle/            # 01-system → 02-claude → 03-codex → 04-antigravity
    │                          # → 05-cursor → 06-mcp → 07-dream
    ├── openclaw/              # 01-system → 02-openclaw
    ├── hermes/                # 01-system → 02-hermes
    └── paperclip/             # 01-system → 02-paperclip
```

Per-profile docs live in each `profiles/<name>/README.md`. Architecture +
rationale in [`.claude/PLAN.md`](.claude/PLAN.md). Decision log in
[`.claude/CHANGELOG.md`](.claude/CHANGELOG.md). Open design decisions in
[`.claude/RECOMMENDATIONS.md`](.claude/RECOMMENDATIONS.md).

## Quick start

```bash
git clone https://github.com/govtech42/harness.git ~/harness
cd ~/harness
cp profiles/<profile>/.env.example profiles/<profile>/.env
nano profiles/<profile>/.env           # fill provider keys, toggles, etc.
./install.sh                           # interactive menu
# or jump straight in:
./install.sh cli-bundle
```

Example menu:

```
No profile installed yet.

Pick a profile to install:
1) cli-bundle
2) openclaw
3) hermes
4) paperclip
5) Quit
#?
```

## Launcher

```bash
./install.sh                    # interactive picker
./install.sh <profile>          # install named profile
./install.sh <profile> --force  # override mutex (see below)
./install.sh --status           # show installed profile, if any
./install.sh --help             # usage
```

`<profile>` is one of: `cli-bundle`, `openclaw`, `hermes`, `paperclip`.

## Mutex (one profile per host)

The launcher writes the profile name to `~/.harness-profile` (`chmod 600`) when
an install completes. Any subsequent run for a **different** profile refuses
with exit code `2`:

```
ERROR: profile 'cli-bundle' already installed on this host.
       Refusing to install 'openclaw'.
       Override:  --force   (not recommended; profiles are not designed to coexist)
```

Why: these stacks compete for PATH entries, ports, systemd unit names, and
memory on small VPSes. Coexistence isn't supported. If you *really* know
better, `--force` bypasses the check.

The `cli-bundle` profile is the one exception: it intentionally stacks four
**thin** CLI clients (Claude, Codex, Antigravity, Cursor) which have disjoint
config dirs and no port binds.

## Pre-requisites

| Requirement     | Detail                                                              |
|-----------------|---------------------------------------------------------------------|
| OS              | Ubuntu 22.04 LTS (other Debian-likes may work but are untested)     |
| RAM             | 2 GB minimum; 4 GB recommended for `cli-bundle` with MCPs enabled   |
| Disk            | 10 GB free                                                          |
| Network         | Outbound HTTPS to npm, GitHub, ClickHouse repo, each agent provider |
| Inbound         | Static IP / SSH on `:22`; OAuth callbacks for some agents           |
| User            | `ubuntu` (or any user with `sudo` and a writable `$HOME`)           |

## What each profile installs

### `cli-bundle`
Per-CLI toggles in `.env` (`INSTALL_CLAUDE`, `INSTALL_CODEX`,
`INSTALL_ANTIGRAVITY`, `INSTALL_CURSOR`). Each defaults `true` for Claude,
`false` for the others — flip to opt in.

- **Claude Code** — `npm i -g @anthropic-ai/claude-code`
- **Codex** — `npm i -g @openai/codex`
- **Antigravity** — upstream installer (`curl … | bash`)
- **Cursor** — upstream installer (`curl … | bash`)
- **MCP servers** — registered for Claude only (Context7, Linear, Slack,
  GitHub, Supabase, Sentry, Notion, Playwright, Filesystem)
- **Dream mode** — cron-driven `claude -p` invocation of the
  `anthropic-skills:consolidate-memory` skill at `03:00`. Log auto-rotates at
  5 MiB. See [profiles/cli-bundle/README.md](profiles/cli-bundle/README.md).

### `openclaw`
Installs `openclaw` from npm globally. Seeds `~/.openclaw/openclaw.json` with
your default model. Optionally onboards the systemd daemon
(`OPENCLAW_AS_SERVICE=true`).

### `hermes`
Defaults to the upstream `curl|bash` installer
(`HERMES_USE_UPSTREAM_INSTALLER=true`), which sets up Python 3.11 via `uv` and
puts `hermes` on PATH. Dev path (`false`) does git clone + `setup-hermes.sh`.

### `paperclip`
`git clone + pnpm install + pnpm build`. Embedded PostgreSQL is provisioned by
the app on first run; no external DB needed. Optional systemd unit for the API
server on port `3100`.

## Database clients

Every profile's `01-system.sh` installs:

- `postgresql-client` (Ubuntu apt) → `psql`
- `clickhouse-client` from the official ClickHouse deb repo (signed keyring at
  `/etc/apt/keyrings/clickhouse-keyring.gpg`)

Toggle off with `INSTALL_DB_CLIENTS=false` in the profile's `.env`. Granular
control: `INSTALL_POSTGRES_CLIENT`, `INSTALL_CLICKHOUSE_CLIENT`.

## Secrets

- Each profile's `.env` (copied from `.env.example`) holds provider keys and
  toggles. The loader `chmod 600`s it on first run.
- `ANTHROPIC_API_KEY` (and friends) get appended to `~/.bashrc`; the file is
  re-chmoded to `600` after the write.
- `~/.harness-profile` is `chmod 600`.
- Tokens (OAuth, etc.) live under `~/.claude/`, `~/.openclaw/`, etc. — back
  these up before destroying the VPS:
  ```bash
  tar czf harness-backup.tgz ~/.claude ~/.openclaw ~/.harness-profile
  ```

## Maintenance

```bash
# show installed profile
./install.sh --status

# re-run a profile (idempotent — re-applies .env changes)
./install.sh <profile>

# wipe the marker if you intend a clean swap (combine with --force)
rm ~/.harness-profile && ./install.sh <other-profile>

# update a CLI in cli-bundle
npm update -g @anthropic-ai/claude-code
npm update -g @openai/codex
npm update -g openclaw     # for the openclaw profile
```

## Troubleshooting

| Symptom                                       | Fix                                                                |
|-----------------------------------------------|--------------------------------------------------------------------|
| `command not found: claude` (or any CLI)      | `source ~/.bashrc` (PATH update lives there)                       |
| `Refusing to install '<other>'`               | Expected — see [Mutex](#mutex-one-profile-per-host)                 |
| MCP OAuth callback never returns              | Open the URL on your **laptop**, not on the VPS                    |
| Playwright MCP install fails                  | `sudo npx playwright install-deps`                                 |
| Out of RAM mid-install                        | Bump `SWAP_SIZE_GB` in `.env`, re-run                              |
| ClickHouse repo signature error               | Delete `/etc/apt/keyrings/clickhouse-keyring.gpg` and re-run       |
| Cron Dream job logs nothing                   | `crontab -l \| grep claude-dream` to confirm registered            |

## Development

```bash
# syntax-check every shell script
find . -name '*.sh' -exec bash -n {} \; -print

# shellcheck (optional)
find . -name '*.sh' -exec shellcheck {} \;
```

Conventions baked into every script:

- `set -euo pipefail`
- Idempotent (`mkdir -p`, `grep -q` guards, `git pull --ff-only`,
  `claude mcp remove` before `add`)
- Pure bash, no perl/python dependencies for the launcher itself
- `.env` always sourced via the shared `load_env` helper

## Status & roadmap

| Profile      | Install path                          | Real-VPS verified |
|--------------|---------------------------------------|-------------------|
| cli-bundle   | npm global + upstream installers      | ✅ (partial)      |
| openclaw     | `npm i -g openclaw`                   | ⚠️ pending         |
| hermes       | upstream `curl \| bash`               | ⚠️ pending         |
| paperclip    | `git clone + pnpm build`              | ⚠️ pending         |

Open design decisions awaiting review: [`.claude/RECOMMENDATIONS.md`](.claude/RECOMMENDATIONS.md).
Open work items: [`.claude/TODO.md`](.claude/TODO.md).

## License

MIT — see [LICENSE.md](LICENSE.md).
