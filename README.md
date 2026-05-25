# harness

> Idempotent shell-script installers that bootstrap a fresh Ubuntu 22.04 VPS
> for one of four AI-agent stacks, with a one-profile-per-host mutex,
> shared base tooling, DB clients, headless browser, MCP servers, plugins,
> and an Obsidian-vault workspace shared across every CLI agent.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
![Shell: bash](https://img.shields.io/badge/shell-bash-4EAA25)
![Target: Ubuntu 22.04](https://img.shields.io/badge/target-Ubuntu%2022.04-E95420)
![CI](https://github.com/govtech42/harness/actions/workflows/ci.yml/badge.svg)
![Release](https://github.com/govtech42/harness/actions/workflows/release.yml/badge.svg)

## What is this

You rent a Lightsail/Hetzner/DO box. You want **one** of these stacks on it,
fully configured, in a single command:

| Profile      | What you get                                                                                          |
|--------------|-------------------------------------------------------------------------------------------------------|
| `cli-bundle` | Claude Code + OpenAI Codex + Google Antigravity + Cursor + **OpenCode** CLIs (any combination)        |
| `openclaw`   | [OpenClaw](https://github.com/openclaw/openclaw) — local agent gateway on port `18789`                |
| `hermes`     | [Hermes Agent](https://github.com/NousResearch/hermes-agent) (Nous Research, Python+uv)               |
| `paperclip`  | [Paperclip](https://github.com/paperclipai/paperclip) — Node API + embedded Postgres :3100            |

Plus, on every profile:

- Common Linux toolkit (`tmux`, `git`, `vim`, `jq`, `ripgrep`, `fd`, `fzf`, `htop`, …)
- `psql` (PostgreSQL client) and `clickhouse-client` from the official ClickHouse deb repo
- **Headless browser** (`chromium` via apt — falls back to Playwright's bundled Chromium)
- Timezone, swap file, npm user-global prefix, `~/.bashrc` PATH
- A mutex marker so you don't accidentally stack two agent runtimes on one host

`cli-bundle` additionally bundles:

- **MCP servers** for Claude (Context7, Linear, Slack, GitHub, Supabase, Sentry, Notion, Playwright, Filesystem, Obsidian)
- **Plugins** — GSD, gstack, superpowers, OpenSpec, plus the official Anthropic marketplace (Linear/Slack/GitHub/Notion/Atlassian/Asana/Figma/Sentry/Supabase/Vercel)
- **Obsidian vault** — shared workspace at `$OBSIDIAN_VAULT_DIR`, all CLIs read/write, optional git auto-sync
- **Dream mode** — cron-driven memory consolidation for Claude

## Repo layout

```
harness/
├── install.sh                 # top-level launcher (menu, arg, --status, --force)
├── lib/
│   ├── common.sh              # mutex_check, mutex_set, load_env, banner
│   ├── base-packages.sh       # install_base_packages, install_db_clients,
│   │                          # install_headless_browser, install_node,
│   │                          # install_pnpm, install_bun, install_uv
│   ├── obsidian.sh            # setup_vault, sync_vault_now/install/uninstall
│   └── plugins.sh             # claude_headless, install_official_claude_plugin,
│                              # install_claude_plugin, install_openspec,
│                              # install_gstack_for, print_manual_install_hint
└── profiles/
    ├── cli-bundle/            # 01-system → 02-claude → 03-codex → 04-antigravity
    │                          # → 05-cursor → 05b-opencode → 08-obsidian
    │                          # → 06-mcp → 07-dream → 09-plugins
    ├── openclaw/              # 01-system → 02-openclaw
    ├── hermes/                # 01-system → 02-hermes
    └── paperclip/             # 01-system → 02-paperclip
```

Per-profile docs live in each `profiles/<name>/README.md`. Architecture +
rationale in [`.claude/PLAN.md`](.claude/PLAN.md). Decision log in
[`.claude/CHANGELOG.md`](.claude/CHANGELOG.md). Open design decisions in
[`.claude/RECOMMENDATIONS.md`](.claude/RECOMMENDATIONS.md). Open work items
in [`.claude/TODO.md`](.claude/TODO.md).

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

The `cli-bundle` profile is the exception: it intentionally stacks **five**
thin CLI clients (Claude, Codex, Antigravity, Cursor, OpenCode) which have
disjoint config dirs and no port binds.

## Pre-requisites

| Requirement     | Detail                                                                |
|-----------------|-----------------------------------------------------------------------|
| OS              | Ubuntu 22.04 LTS (other Debian-likes may work but are untested)       |
| RAM             | 2 GB minimum; 4 GB recommended for `cli-bundle` with MCPs + plugins   |
| Disk            | 10 GB free                                                            |
| Network         | Outbound HTTPS to npm, GitHub, ClickHouse repo, each agent provider   |
| Inbound         | Static IP / SSH on `:22`; OAuth callbacks for some agents             |
| User            | `ubuntu` (or any user with `sudo` and a writable `$HOME`)             |

## What each profile installs

### `cli-bundle`

Five CLIs — toggle each in `.env`. Defaults: Claude `true`, others `false`.

| Toggle                 | CLI                  | Install path                                          |
|------------------------|----------------------|-------------------------------------------------------|
| `INSTALL_CLAUDE`       | Claude Code          | `npm i -g @anthropic-ai/claude-code`                  |
| `INSTALL_CODEX`        | OpenAI Codex         | `npm i -g @openai/codex`                              |
| `INSTALL_ANTIGRAVITY`  | Google Antigravity   | upstream installer (`curl … \| bash`)                 |
| `INSTALL_CURSOR`       | Cursor agent         | upstream installer (`curl … \| bash`)                 |
| `INSTALL_OPENCODE`     | OpenCode             | upstream installer (`curl -fsSL https://opencode.ai/install \| bash`) |

Plus:

- **MCP servers** registered for Claude (`06-mcp.sh`) — Context7, Linear,
  Slack, GitHub, Supabase, Sentry, Notion, Playwright, Filesystem, Obsidian.
- **Plugins** (`09-plugins.sh`) — see [Plugins](#plugins) below.
- **Obsidian vault** (`08-obsidian.sh`) — shared workspace for every CLI.
- **Dream mode** (`07-dream.sh`) — cron-driven `claude -p` invocation of
  `anthropic-skills:consolidate-memory` at `03:00`; log auto-rotates at 5 MiB.

Full docs: [profiles/cli-bundle/README.md](profiles/cli-bundle/README.md).

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

## Plugins

Available in `cli-bundle` via `09-plugins.sh`. Headless install where the CLI
supports it; printed manual hint otherwise.

| Plugin           | Claude   | Codex             | Antigravity                | Cursor               | OpenCode             |
|------------------|----------|-------------------|----------------------------|----------------------|----------------------|
| GSD              | headless | —                 | —                          | —                    | —                    |
| gstack           | headless | —                 | —                          | —                    | headless             |
| superpowers      | headless | manual `/plugins` | manual (not documented)    | manual `/add-plugin` | manual fetch URL     |
| **OpenSpec**     | universal (npm global, `/opsx:*` slash commands from any CLI) — invoked via `openspec init` per project |

Plus the **official Anthropic marketplace** (Claude-only, bundles pre-configured MCP + skills + slash commands):

`INSTALL_LINEAR_PLUGIN`, `INSTALL_SLACK_PLUGIN`, `INSTALL_GITHUB_PLUGIN`,
`INSTALL_NOTION_PLUGIN`, `INSTALL_ATLASSIAN_PLUGIN`, `INSTALL_ASANA_PLUGIN`,
`INSTALL_FIGMA_PLUGIN`, `INSTALL_SENTRY_PLUGIN`, `INSTALL_SUPABASE_PLUGIN`,
`INSTALL_VERCEL_PLUGIN`.

These coexist with the raw MCP toggles in `06-mcp.sh` (e.g. `INSTALL_LINEAR=true`
registers the bare MCP endpoint); the official plugin is the richer path.

## Obsidian vault (cli-bundle)

Opt-in shared workspace every CLI reads and writes. Headless on VPS (no
Obsidian app required); same files render in the desktop app on a workstation
that pulls the git remote.

```env
INSTALL_OBSIDIAN=true
OBSIDIAN_VAULT_DIR=/home/ubuntu/vault
OBSIDIAN_VAULT_REPO=git@github.com:you/your-vault.git   # optional
OBSIDIAN_AUTOSYNC=true                                  # opt-in
OBSIDIAN_AUTOSYNC_SCHEDULE=*/15 * * * *
```

Layout:

```
$OBSIDIAN_VAULT_DIR/
├── .claude/log.md            # Claude Code writes here
├── .codex/log.md             # Codex
├── .antigravity/log.md       # Antigravity
├── .cursor/log.md            # Cursor
├── inbox.md                  # any agent appends
├── notes/                    # main markdown
├── .obsidian/app.json        # config seed (versioned if git)
└── .gitignore                # excludes workspace.json, cache, .trash/
```

Git auto-sync uses `-X ours` — local edits always win on conflict
(trade-off documented in `.claude/RECOMMENDATIONS.md` and `.claude/CHANGELOG.md`).

## Database clients

Every profile's `01-system.sh` installs:

- `postgresql-client` (Ubuntu apt) → `psql`
- `clickhouse-client` from the official ClickHouse deb repo (signed keyring at
  `/etc/apt/keyrings/clickhouse-keyring.gpg`)

Toggle off with `INSTALL_DB_CLIENTS=false` in the profile's `.env`. Granular
control: `INSTALL_POSTGRES_CLIENT`, `INSTALL_CLICKHOUSE_CLIENT`.

## Headless browser

`install_headless_browser()` in `lib/base-packages.sh` tries `chromium-browser`
then `chromium` via apt; warns (does not fail) if no apt package resolves.
Used for general agent shell work. Default `INSTALL_HEADLESS_BROWSER=true`.

Playwright is a separate concern: `INSTALL_PLAYWRIGHT=true` in `06-mcp.sh`
does its own `playwright install-deps` + bundled-Chromium download +
`@playwright/mcp@latest` MCP registration.

## Secrets

- Each profile's `.env` (copied from `.env.example`) holds provider keys and
  toggles. The loader `chmod 600`s it on first run.
- `ANTHROPIC_API_KEY` (and friends) get appended to `~/.bashrc`; the file is
  re-chmoded to `600` after the write.
- `~/.harness-profile` is `chmod 600`.
- Tokens (OAuth, etc.) live under `~/.claude/`, `~/.openclaw/`, etc. — back
  these up before destroying the VPS:
  ```bash
  tar czf harness-backup.tgz ~/.claude ~/.openclaw ~/.opencode \
        ~/.codex ~/.cursor ~/.antigravity ~/vault ~/.harness-profile
  ```

## Maintenance

```bash
# show installed profile
./install.sh --status

# re-run a profile (idempotent — re-applies .env changes)
./install.sh <profile>

# wipe the marker if you intend a clean swap (combine with --force)
rm ~/.harness-profile && ./install.sh <other-profile>

# update an npm-global CLI
npm update -g @anthropic-ai/claude-code
npm update -g @openai/codex
npm update -g openclaw                 # for the openclaw profile
npm update -g @fission-ai/openspec     # if INSTALL_OPENSPEC=true

# manual Obsidian sync (if INSTALL_OBSIDIAN + git repo configured)
source ~/.bashrc && obsidian-vault-sync
```

## Tests + CI

Local test harness in `tests/`:

```bash
# install deps (Ubuntu/Debian)
sudo apt-get install -y shellcheck bats
# install deps (macOS)
brew install shellcheck bats-core

bash tests/lint.sh
bash tests/check_env_completeness.sh
bats tests/
```

GitHub Actions:

- [`ci.yml`](.github/workflows/ci.yml) — runs `lint`, `env-completeness`, and
  `bats` jobs in parallel on every push and PR.
- [`release.yml`](.github/workflows/release.yml) — on `v*` tag, reruns CI then
  publishes a GitHub release with notes extracted from `.claude/CHANGELOG.md`.

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
| Obsidian auto-sync fails                      | `tail ~/vault/.claude/sync.log`; verify `OBSIDIAN_VAULT_REPO` push access |
| Plugin install hangs in `claude -p`           | Check `~/.claude/logs/` and retry with `--dangerously-skip-permissions` |
| `chromium` package missing                    | Rely on Playwright's bundled Chromium (set `INSTALL_PLAYWRIGHT=true`) |

## Development

```bash
# syntax-check every shell script
find . -name '*.sh' -exec bash -n {} \; -print

# shellcheck (optional)
find . -name '*.sh' -exec shellcheck -x -S warning -e SC1090,SC1091 {} \;
```

Conventions baked into every script:

- `set -euo pipefail`
- Idempotent (`mkdir -p`, `grep -q` guards, `git pull --ff-only`,
  `claude mcp remove` before `add`)
- Pure bash, no perl/python dependencies for the launcher itself
- `.env` always sourced via the shared `load_env` helper

## Status & roadmap

| Profile      | Install path                                        | Real-VPS verified |
|--------------|-----------------------------------------------------|-------------------|
| cli-bundle   | npm global + upstream installers (5 CLIs + plugins) | ✅ (partial)      |
| openclaw     | `npm i -g openclaw`                                 | ⚠️ pending         |
| hermes       | upstream `curl \| bash`                             | ⚠️ pending         |
| paperclip    | `git clone + pnpm build`                            | ⚠️ pending         |

Releases: [v0.6.1](https://github.com/govtech42/harness/releases/tag/v0.6.1) (latest) — see [`.claude/CHANGELOG.md`](.claude/CHANGELOG.md) for the full reverse-chrono history.

Open design decisions awaiting review: [`.claude/RECOMMENDATIONS.md`](.claude/RECOMMENDATIONS.md).
Open work items: [`.claude/TODO.md`](.claude/TODO.md).

## License

MIT — see [LICENSE.md](LICENSE.md).
