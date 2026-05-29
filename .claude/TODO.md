# TODO

> Changelog of structural decisions lives in [CHANGELOG.md](CHANGELOG.md).

## Blockers (must resolve before real-VPS install)

- [x] **openclaw/02-openclaw.sh** — upstream is `npm i -g openclaw`. Replaced.
- [x] **hermes/02-hermes.sh** — upstream `curl|bash` installer wired; dev path fallback.
- [x] **paperclip/02-paperclip.sh** — `git clone + pnpm install + pnpm build` wired.
- [x] Upstream repo URLs verified via WebFetch (2026-05-25).
- [ ] Confirm `@openai/codex` npm package name on a clean VPS (some versions ship as `@openai/codex-cli`).
- [ ] Confirm Antigravity v2 installer URL `https://antigravity.google/cli/install.sh` is stable (or pin to a tagged release).
- [ ] Confirm Cursor CLI installer URL `https://cursor.com/install` is the agent-mode binary, not the IDE.
- [ ] OpenClaw daemon: `openclaw onboard --install-daemon` may prompt — test non-interactive mode (`--yes` flag?).
- [ ] Paperclip systemd unit assumes `pnpm dev:server` is correct production command — confirm vs `pnpm start`.
- [ ] Hermes upstream installer writes to `~/.local/bin` and modifies shell rc — confirm idempotency on re-run.

## Nice-to-have (security hardening)

- [ ] Add optional `01b-harden.sh` per profile: UFW (allow 22/tcp only), fail2ban, unattended-upgrades.
- [ ] Add `04-verify.sh` per profile: post-install health check (binaries on PATH, service status, swap, timezone).
- [ ] Add `uninstall.sh` per profile + top-level `./install.sh --uninstall`.
- [ ] Per-profile `.env` validation: required keys present, key formats sane.
- [ ] CLAUDE.md global seed in `~/.claude/CLAUDE.md` with user prefs (tz, idiom).

## CLI bundle

- [ ] Wire `06-mcp.sh` to skip if `INSTALL_CLAUDE=false`.
- [ ] Wire `07-dream.sh` to skip if `INSTALL_CLAUDE=false`.
- [ ] Per-CLI auth verification (`claude --version`, `codex --version`, etc.) gated by toggle.
- [ ] Document tmux session naming convention when running multiple CLIs.

## Plugins (v0.5.0+)

- [ ] **Antigravity + superpowers**: confirm whether `antigravity extensions install <url>` is a real command. Replace manual hint with headless install if confirmed.
- [ ] Superpowers OpenCode install is "fetch instructions" — investigate whether OpenCode has a headless prompt API to drive it programmatically.
- [ ] Plugin verification: after install, run a sanity check (e.g. `claude -p "/plugin list"` and grep for the installed names).

## Obsidian vault (v0.4.0+)

- [ ] Workstation-side companion: doc snippet for installing Obsidian app + git pull of the same vault.
- [ ] Optional Local REST API integration when an Obsidian app *is* reachable (registers a richer `obsidian` MCP with search/backlinks/tags).
- [ ] Auto-tagging convention: each agent prefixes its log entries with `#agent/claude` etc. for filter views.
- [ ] Vault GC: prune `agents/*/log.md` entries older than N days (currently grows unbounded).
- [ ] Conflict-aware fallback: when `-X ours` would discard >N lines, stash the remote into `conflict/<host>-<ts>` branch instead of silently dropping (escape hatch for high-volume cases).

## Launcher

- [ ] `--uninstall <profile>` subcommand.
- [ ] `--dry-run` mode that prints what would run.
- [ ] Non-interactive bootstrap: `curl ... | bash -s -- <profile>`.
- [ ] Color output (TTY-detect, no escape codes in pipes).

## Docs

- [ ] Per-profile README: real first-run walkthrough once TODOs above are resolved.
- [ ] Top-level README: add cost/latency notes per profile.
- [ ] `.claude/profiles/*.md` research notes: fill in concrete commands and links.

## Tests

- [x] `bash -n` syntax check in CI for every `*.sh` (`tests/lint.sh`, v0.3.0).
- [x] shellcheck pass (`tests/lint.sh`, v0.3.0).
- [x] bats unit + launcher tests (`tests/test_*.bats`, v0.3.0).
- [x] `.env.example` completeness check (`tests/check_env_completeness.sh`, v0.3.0).
- [ ] Optional: docker-based dry-run that exercises `01-system.sh` against an Ubuntu 22.04 image (`workflow_dispatch` manual run).

## CI / workflows

- [ ] **GitHub Actions: bump `actions/checkout@v4` → `@v5`** when released. `@v4` runs on Node.js 20, deprecated 2026-06-02, removed 2026-09-16. Forced to Node 24 in workflow files via `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` is the interim escape hatch.
- [ ] Cache apt packages across CI runs (shellcheck/bats install on every job).
- [ ] Add `concurrency:` group to cancel superseded PR builds.
- [ ] Sign releases (sigstore or GPG).
