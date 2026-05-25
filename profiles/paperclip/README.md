# Paperclip profile

Local install of [paperclipai/paperclip](https://github.com/paperclipai/paperclip).

Default path: `git clone` + `pnpm install` + `pnpm build`. Set
`PAPERCLIP_USE_NPX=true` to delegate to upstream's `npx paperclipai onboard --yes`.

## Runtime
- Node **20+** (NodeSource via `01-system.sh`)
- pnpm **9.15+** (corepack)
- Embedded PostgreSQL provisioned automatically on first run
- API server on port **3100** (`PAPERCLIP_PORT`)

## Usage
```bash
cp .env.example .env && nano .env
bash install.sh                          # or ../../install.sh paperclip
```

After install:
```bash
cd ~/paperclip
pnpm dev               # API + UI in watch mode
pnpm dev:server        # API only
# or, if PAPERCLIP_AS_SERVICE=true:
sudo systemctl status paperclip
```

Telemetry is disabled by default (`PAPERCLIP_TELEMETRY_DISABLED=1`,
`DO_NOT_TRACK=1`).

## Mutex
Refuses if another profile is installed. Override: `bash install.sh --force`.
