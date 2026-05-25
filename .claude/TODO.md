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

- [ ] `bash -n` syntax check in CI for every `*.sh`.
- [ ] shellcheck pass.
- [ ] Optional: docker-based dry-run that exercises `01-system.sh` against an Ubuntu 22.04 image.
