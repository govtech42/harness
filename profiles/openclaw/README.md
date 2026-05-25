# OpenClaw profile

Local install of [OpenClaw](https://github.com/openclaw/openclaw) on Ubuntu 22.04.

Upstream is published on npm (`openclaw`). The installer simply pulls it
globally into `~/.npm-global/bin`, seeds `~/.openclaw/openclaw.json`, and
optionally onboards the systemd daemon.

## Runtime
- Node.js **22.19+** (24 recommended) — installed via NodeSource by `01-system.sh`
- pnpm (corepack) — installed in case you switch to dev-mode
- Gateway port **18789**

## Usage
```bash
cp .env.example .env && nano .env       # set OPENCLAW_MODEL and provider keys
bash install.sh                          # or ../../install.sh openclaw
```

After install:
```bash
openclaw onboard                 # interactive setup
openclaw gateway --verbose       # foreground
# or, if OPENCLAW_AS_SERVICE=true was used:
openclaw gateway status
```

Config: `~/.openclaw/openclaw.json` (chmod 600 by installer).

## Mutex
Refuses if another profile is installed. Override: `bash install.sh --force`.
