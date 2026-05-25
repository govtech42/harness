# harness — VPS install profiles for AI coding agents

Idempotent shell-script installers that bootstrap an Ubuntu 22.04 VPS
(AWS Lightsail, Hetzner, DO, etc.) for one of four AI-agent stacks.

```
harness/
├── install.sh                 # top-level launcher (menu or arg)
├── lib/common.sh              # mutex + env helpers shared by all profiles
└── profiles/
    ├── cli-bundle/            # Claude Code + Codex + Antigravity + Cursor (coexist)
    ├── openclaw/              # OpenClaw — local agent
    ├── hermes/                # Hermes Agent (Nous Research)
    └── paperclip/             # Paperclip
```

## Quick start

```bash
git clone <this repo> ~/harness && cd ~/harness
./install.sh                          # interactive menu
# or
./install.sh cli-bundle               # direct
./install.sh openclaw --force         # override the mutex
./install.sh --status                 # show installed profile
```

Each profile expects its own `.env` (copy from `.env.example`) before running.

## Mutex

One profile per host. The launcher (and every profile's `install.sh`) reads
`~/.harness-profile`; if it's set to a different profile, the installer **refuses**
unless `--force` is passed. This is by design — these stacks make conflicting
assumptions about PATH, ports, and system services.

| Profile     | Coexists with                                  |
|-------------|------------------------------------------------|
| cli-bundle  | Claude, Codex, Antigravity, Cursor (4 in one)  |
| openclaw    | alone                                          |
| hermes      | alone                                          |
| paperclip   | alone                                          |

## Profiles

### `cli-bundle/`
Installs any combination of Claude Code, OpenAI Codex, Google Antigravity, and
Cursor CLIs. Toggle each in `.env` (`INSTALL_CLAUDE`, `INSTALL_CODEX`,
`INSTALL_ANTIGRAVITY`, `INSTALL_CURSOR`). Also bundles MCP-server registration
for Claude and the [Dream mode](profiles/cli-bundle/README.md#dream-mode) memory
consolidator. See [profiles/cli-bundle/README.md](profiles/cli-bundle/README.md).

### `openclaw/`
Clones [openclaw/openclaw](https://github.com/openclaw/openclaw) locally.
**Status:** scaffold — build/run step is a TODO marker, confirm upstream README.

### `hermes/`
Clones [nousresearch/hermes-agent](https://github.com/nousresearch/hermes-agent).
**Status:** scaffold — same TODO.

### `paperclip/`
Clones [paperclipai/paperclip](https://github.com/paperclipai/paperclip).
**Status:** scaffold — same TODO.

## Pre-requisites

- Ubuntu 22.04 LTS, ≥ 2 GB RAM (4 GB recommended for the cli-bundle + MCPs)
- Static IP (or domain) for OAuth flows
- SSH access as `ubuntu`
- Outbound HTTPS to npm, GitHub, and each agent's provider

## Conventions

- All scripts: `set -euo pipefail`, idempotent, safe to re-run
- Secrets live in `profiles/<name>/.env` (chmoded 600 by the installer)
- npm globals use `~/.npm-global` (no sudo, no PATH conflicts)
- Per-profile docs in each `profiles/<name>/README.md`

## Plan + TODO

See [.claude/PLAN.md](.claude/PLAN.md) for architecture rationale and
[.claude/TODO.md](.claude/TODO.md) for what's still scaffolded.
