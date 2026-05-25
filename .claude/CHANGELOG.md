# CHANGELOG — what was built and why

Reverse-chronological log of structural changes to the harness repo.
Each entry: **what** changed, **why** it was needed, **files** touched.

---

## 2026-05-25 — v0.6.0 — Official plugins (Linear/Slack/etc) + headless browser as base tool

**What**
- `lib/base-packages.sh` — new `install_headless_browser()`. Tries `chromium-browser` then `chromium` apt packages; falls back to "use Playwright's bundled Chromium" warning if neither resolves. Toggle `INSTALL_HEADLESS_BROWSER` (default `true`).
- All 4 profile `01-system.sh` scripts call `install_headless_browser` after `install_db_clients`.
- `lib/plugins.sh` — new `install_official_claude_plugin <name>` (uses always-available `claude-plugins-official` marketplace; no `marketplace add` needed).
- `profiles/cli-bundle/09-plugins.sh` — adds 10 official plugin toggles: `INSTALL_{LINEAR,SLACK,GITHUB,NOTION,ATLASSIAN,ASANA,FIGMA,SENTRY,SUPABASE,VERCEL}_PLUGIN`.
- `profiles/cli-bundle/.env.example` — new `INSTALL_HEADLESS_BROWSER` (in base block) + 10 `*_PLUGIN` toggles (in plugins block).
- `profiles/cli-bundle/README.md` — sections for official plugins + Playwright clarification.
- `tests/test_plugins.bats` — 1 new test for `install_official_claude_plugin` (verifies install + reload, no spurious marketplace add).

**Playwright**
- No official plugin exists. Existing `INSTALL_PLAYWRIGHT=true` path in `06-mcp.sh` remains: `playwright install-deps` + bundled Chromium + `@playwright/mcp@latest`. Documented as the local-script alternative.

**Why**
- Official Anthropic-curated plugins (Linear, Slack, GitHub, Notion, Atlassian, Asana, Figma, Sentry, Supabase, Vercel) bundle pre-configured MCP + skills + slash commands. Richer than raw MCP registration alone, and `claude-plugins-official` is always available so no marketplace bootstrap step is needed.
- Headless browser belongs in base tooling so the agent can drive curl/inspect/screenshot flows even without enabling Playwright. Playwright's own Chromium download is heavy and only worth it when Playwright MCP is on.

**Coexistence of plugin vs raw MCP**
- `INSTALL_LINEAR=true` (raw MCP via `06-mcp.sh`) and `INSTALL_LINEAR_PLUGIN=true` (official plugin via `09-plugins.sh`) can both be on. The plugin is recommended; raw MCP stays as the lightweight fallback.

**Files**
- `lib/base-packages.sh` (`install_headless_browser`)
- `lib/plugins.sh` (`install_official_claude_plugin`)
- `profiles/cli-bundle/09-plugins.sh` (10 toggles)
- `profiles/cli-bundle/.env.example` (new toggles)
- `profiles/cli-bundle/README.md` (sections)
- `profiles/{cli-bundle,openclaw,hermes,paperclip}/01-system.sh` (`install_headless_browser` call)
- `profiles/{cli-bundle,openclaw,hermes,paperclip}/.env.example` (`INSTALL_HEADLESS_BROWSER`)
- `tests/test_plugins.bats` (1 new test)

---

## 2026-05-25 — v0.5.0 — OpenCode CLI + plugin marketplaces (GSD/gstack/superpowers)

**What**
- `profiles/cli-bundle/05b-opencode.sh` — installs OpenCode via upstream `curl -fsSL https://opencode.ai/install | bash`. Adds `~/.opencode/bin` and `~/.local/bin` to PATH via `~/.bashrc`. Toggle: `INSTALL_OPENCODE`.
- `lib/base-packages.sh` — new `install_bun()` (required by gstack).
- `lib/plugins.sh` — `claude_headless`, `install_claude_plugin`, `install_gstack_for`, `print_manual_install_hint`.
- `profiles/cli-bundle/09-plugins.sh` — orchestrates the three plugins across the bundle.
- `tests/test_plugins.bats` — 4 new unit tests (stubbed `claude` binary).
- `.env.example` — toggles + per-plugin per-CLI subtoggles.

**Plugin coverage matrix**
| Plugin       | Claude   | Codex            | Antigravity                  | Cursor               | OpenCode             |
|--------------|----------|------------------|------------------------------|----------------------|----------------------|
| GSD          | headless | —                | —                            | —                    | —                    |
| gstack       | headless | —                | —                            | —                    | headless (`--host opencode`) |
| superpowers  | headless | manual `/plugins`| manual (NOT documented)      | manual `/add-plugin` | manual fetch URL     |

**Decisions**
- **Antigravity superpowers**: option (b) from prior planning — no blind attempt. Prints manual hint with a Gemini-CLI-pattern guess + warning that upstream docs don't cover Antigravity.
- **gstack runtime**: requires Bun. `install_bun()` lives in `base-packages.sh` (reusable) rather than `plugins.sh`; only invoked when `INSTALL_GSTACK=true`.
- **Headless plugin install for Claude**: uses `claude -p "/plugin install ..." --dangerously-skip-permissions`. Other CLIs lack equivalent flags; we deliberately do not script keystrokes against interactive prompts.
- **gstack targets**: list-based (`GSTACK_TARGETS="claude opencode"`) instead of per-target booleans. Extensible to other supported hosts (Cursor, Codex, Hermes, etc.) without env-var explosion.

**Why**
- The three plugins shape how every CLI session behaves (slash commands, agent roles, workflows). Manual install on every fresh VPS is the worst kind of toil.
- OpenCode joins the bundle because gstack and superpowers both support it and the install path is the same shape as the other CLIs (single curl|bash).

**Files**
- `profiles/cli-bundle/05b-opencode.sh` (new)
- `profiles/cli-bundle/09-plugins.sh` (new)
- `profiles/cli-bundle/install.sh` (calls 05b + 09)
- `profiles/cli-bundle/.env.example` (`INSTALL_OPENCODE`, plugin toggles)
- `profiles/cli-bundle/README.md` (Plugins section)
- `lib/plugins.sh` (new)
- `lib/base-packages.sh` (`install_bun`)
- `tests/test_plugins.bats` (new, 4 tests)

---

## 2026-05-25 — v0.4.0 — Obsidian vault for cli-bundle agents

**What**
- `lib/obsidian.sh` — shared helpers: `setup_vault` (creates skeleton + bashrc export + cdvault alias), `sync_vault_now` (one-shot git pull/commit/push), `sync_vault_install` (user-cron wrapper at `~/.local/bin/obsidian-vault-sync`), `sync_vault_uninstall`.
- `profiles/cli-bundle/08-obsidian.sh` — orchestrator gated on `INSTALL_OBSIDIAN`. Runs *before* `06-mcp.sh` so the vault exists when MCP is registered.
- `profiles/cli-bundle/06-mcp.sh` — when `INSTALL_OBSIDIAN=true`, registers an `obsidian-vault` filesystem MCP scoped to `$OBSIDIAN_VAULT_DIR`.
- `profiles/cli-bundle/.env.example` — adds `INSTALL_OBSIDIAN`, `OBSIDIAN_VAULT_DIR`, `OBSIDIAN_VAULT_REPO`, `OBSIDIAN_VAULT_BRANCH`, `OBSIDIAN_AUTOSYNC`, `OBSIDIAN_AUTOSYNC_SCHEDULE`.
- `profiles/cli-bundle/README.md` — full Obsidian section: layout, per-CLI access, sync, manual ops.
- `tests/test_obsidian.bats` — 7 tests (vault skeleton, bashrc idempotency, .gitignore content, log.md preservation, sync no-op + commit behaviour).

**Vault layout**
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

**Conflict strategy: `-X ours`**
Auto-sync commits local edits then `git merge --no-edit -X ours origin/<branch>` before pushing. Local always wins on conflict. Chosen because multiple agents writing in parallel makes silent loss of *remote* bits less costly than losing in-flight agent work. Trade-off documented in `.claude/RECOMMENDATIONS.md`-style entry.

**Why**
- Each CLI agent kept its own context dir (`~/.claude`, `~/.codex`, etc.). Sharing thought between them required copy-paste.
- Obsidian vault is plain markdown — works headless on a VPS without the Obsidian app, and the same files render in the desktop app on a workstation that pulls the git remote.
- Claude Code gets first-class access via filesystem MCP scoped to the vault. Other CLIs use the `cdvault` shell alias.
- Git sync is opt-in so single-host setups don't pay the complexity.

**Files**
- `lib/obsidian.sh` (new)
- `profiles/cli-bundle/08-obsidian.sh` (new)
- `profiles/cli-bundle/06-mcp.sh` (patched: registers `obsidian-vault` MCP)
- `profiles/cli-bundle/install.sh` (patched: invokes 08 before 06)
- `profiles/cli-bundle/.env.example` (vault knobs)
- `profiles/cli-bundle/README.md` (Obsidian section)
- `tests/test_obsidian.bats` (new — 7 tests)

---

## 2026-05-25 — v0.3.0 — Test suite + CI/Release workflows

**What**
- `tests/lint.sh` — `bash -n` + shellcheck on every `.sh` (SC1090/SC1091 ignored for runtime `.env` sourcing).
- `tests/check_env_completeness.sh` — every `INSTALL_*` toggle and `${VAR}` referenced in a profile's scripts must be documented in that profile's `.env.example`.
- `tests/test_lib.bats` — 12 unit tests for `lib/common.sh` (`mutex_check`, `mutex_set`, `load_env`, `banner`).
- `tests/test_launcher.bats` — 5 black-box tests for `./install.sh` (`--help`, `--status`, unknown profile, mutex rejection).
- `tests/README.md` — how to run locally, what each test covers.
- `.github/workflows/ci.yml` — three parallel jobs on push/PR (lint, env-completeness, bats). Exposed as `workflow_call`.
- `.github/workflows/release.yml` — on `v*` tag, runs CI first, extracts notes from `.claude/CHANGELOG.md`, idempotent `gh release create/edit`.

**Why**
- Manual `bash -n` was the only safety net. One typo merged could break a profile install on a real VPS hours later.
- `.env.example` drift was a foot-gun — a new `INSTALL_FOO` toggle in code with no `.env.example` entry means operators don't know it exists.
- Mutex contract is the most security-relevant logic in the repo; deserves explicit tests.
- Release notes hand-written per tag don't scale; deriving them from `CHANGELOG.md` keeps single source of truth.

**Files**
- `tests/*` (5 new files)
- `.github/workflows/ci.yml`, `.github/workflows/release.yml` (new)

---

## 2026-05-25 — Real upstream commands for openclaw / hermes / paperclip

**What**
- WebFetched each upstream README and replaced TODO scaffolds with verified install/run commands.
- `openclaw/02-openclaw.sh`: `npm i -g openclaw@<version>`, seed `~/.openclaw/openclaw.json`, optional `openclaw onboard --install-daemon`. Gateway port 18789.
- `hermes/02-hermes.sh`: default uses upstream `curl|bash` installer from `scripts/install.sh`; opt-out via `HERMES_USE_UPSTREAM_INSTALLER=false` for git-clone + `uv venv` dev path.
- `paperclip/02-paperclip.sh`: `git clone + pnpm install + pnpm build`, optional `npx paperclipai onboard --yes` path, optional systemd unit for API on port 3100.
- `lib/base-packages.sh` gained `install_node <major>`, `install_pnpm <version>`, `install_uv`.
- 3 × `01-system.sh` now call the right runtime installer (Node 22+pnpm for openclaw, Node 20+pnpm for paperclip, Python 3.11+uv for hermes).
- 3 × `.env.example` rewritten with real knobs (version pins, ports, provider keys, channel tokens, telemetry-off defaults).
- 3 × `README.md` rewritten with real first-run commands.

**Why**
- TODO markers in installer scripts are a foot-gun — operators copy/paste and find out at apt-time. Verifying upstream up front shrinks the "first install on a fresh VPS" risk window.
- Each upstream uses a different runtime story (npm global vs curl|bash vs git+pnpm). Captured each in idempotent shell instead of relying on operator memory.
- Centralising `install_node` / `install_pnpm` / `install_uv` in `lib/base-packages.sh` keeps the runtime story DRY across the four profiles.

**Files**
- `lib/base-packages.sh` (add `install_node`, `install_pnpm`, `install_uv`)
- `profiles/openclaw/{01-system,02-openclaw}.sh`, `.env.example`, `README.md`
- `profiles/hermes/{01-system,02-hermes}.sh`, `.env.example`, `README.md`
- `profiles/paperclip/{01-system,02-paperclip}.sh`, `.env.example`, `README.md`
- `.claude/TODO.md` (blockers closed)

---

## 2026-05-25 — Base Linux tooling + DB clients

**What**
- New `lib/base-packages.sh` exposing three reusable functions:
  - `install_base_packages` — apt-installs the standard set of agent-host tools
    (curl, wget, git, tmux, screen, vim, nano, jq, ripgrep, fd-find, fzf, tree,
    htop, ncdu, unzip/zip/tar/xz/rsync, python3 + venv + pip, build-essential,
    pkg-config, dnsutils, net-tools, lsof).
  - `install_postgres_client` — installs `postgresql-client` (psql).
  - `install_clickhouse_client` — adds the official ClickHouse deb repo with a
    signed keyring and installs `clickhouse-client`.
  - `install_db_clients` — wrapper that calls both, gated on env toggles.
- Every profile's `01-system.sh` sources `lib/base-packages.sh` and calls
  `install_base_packages` + `install_db_clients`.
- All four `.env.example` files gained: `BASE_PACKAGES`, `INSTALL_DB_CLIENTS`,
  `INSTALL_POSTGRES_CLIENT`, `INSTALL_CLICKHOUSE_CLIENT`.

**Why**
- Agents and humans both need a usable shell. The previous `01-system.sh`
  installed only the bare minimum (`curl ca-certificates git tmux
  build-essential jq`). Anyone debugging on the VPS missed obvious tools
  (`rg`, `htop`, `tree`, `vim`).
- DB clients on the harness host let agents drive remote OLTP (Postgres) and
  OLAP (ClickHouse) directly via Bash without spinning extra containers — the
  most common ask once an agent is live.
- Extracting the list into `lib/` removes drift between profiles: editing one
  function updates all four hosts.

**Files**
- `lib/base-packages.sh` (new)
- `profiles/cli-bundle/01-system.sh` (refactor)
- `profiles/openclaw/01-system.sh` (refactor)
- `profiles/hermes/01-system.sh` (refactor)
- `profiles/paperclip/01-system.sh` (refactor)
- `profiles/*/.env.example` (append toggles)

---

## 2026-05-25 — Multi-profile launcher + mutex

**What**
- New top-level `install.sh` launcher: interactive menu, `<profile>` arg,
  `--status`, `--force`.
- New `lib/common.sh` with `load_env`, `mutex_check`, `mutex_set`, `banner`.
- Migrated `claude-vps-setup/` to `profiles/cli-bundle/` and renumbered:
  01-system, 02-claude, 03-codex (new), 04-antigravity (new), 05-cursor (new),
  06-mcp, 07-dream.
- Scaffolded three new profiles, each with `install.sh`, `01-system.sh`,
  `02-<name>.sh`, `.env.example`, `README.md`:
  `profiles/openclaw/`, `profiles/hermes/`, `profiles/paperclip/`.
- Top-level `README.md` with profile matrix.
- `.claude/PLAN.md`, `.claude/TODO.md`, `.claude/profiles/*.md`.

**Why**
- User runs four distinct VPS stacks: a CLI bundle plus three single-agent
  hosts (OpenClaw, Hermes, Paperclip). One install script per host doesn't
  scale; one repo with profiles does.
- Mutex (`~/.harness-profile`) prevents accidentally co-installing
  incompatible stacks — they share PATH, ports, and systemd unit names.
- CLI bundle stays one profile because the four CLIs (Claude / Codex /
  Antigravity / Cursor) are thin remote clients with disjoint config dirs and
  no port binds.

**Files**
- `install.sh`, `lib/common.sh`, `README.md`
- `profiles/cli-bundle/*` (migrated + extended)
- `profiles/openclaw/*`, `profiles/hermes/*`, `profiles/paperclip/*` (new)
- `.claude/PLAN.md`, `.claude/TODO.md`, `.claude/profiles/*.md`

---

## 2026-05-25 — Dream mode (memory consolidation)

**What**
- New `04-install-dream.sh` (later renumbered to `07-dream.sh`) for the
  cli-bundle profile.
- Generates `~/.claude/dream.sh` wrapper that calls `claude -p` headless and
  invokes the `anthropic-skills:consolidate-memory` skill, with an inline
  fallback prompt if the skill isn't installed.
- Registers a user cron entry (default `0 3 * * *`).
- Log at `~/.claude/dream.log` with self-rotation at 5 MiB.
- `.env` toggles: `INSTALL_DREAM`, `DREAM_SCHEDULE`, `DREAM_PROMPT`.

**Why**
- Long-lived agent hosts accumulate memory files faster than they
  consolidate them. Drift compounds: duplicate facts, stale entries,
  index rot. A scheduled reflective pass keeps `~/.claude/memory/`
  healthy without operator intervention.
- "Dream" framing (madrugada / 03:00) fits the cron cadence and is
  intuitive to operators.

**Files**
- `profiles/cli-bundle/07-dream.sh` (new)
- `profiles/cli-bundle/install.sh` (call 07)
- `profiles/cli-bundle/.env.example` (toggles)
- `profiles/cli-bundle/README.md` (new section)

---

## 2026-05-25 — Initial cli-bundle (was claude-vps-setup)

**What**
- Three-script Claude Code installer for Ubuntu 22.04 VPS:
  - `01-install-system.sh` — apt, Node 20.x, tmux, swap, timezone, npm prefix
  - `02-install-claude.sh` — `@anthropic-ai/claude-code`, optional API key
  - `03-install-mcp.sh` — MCP server registry with per-server toggles
- One-shot `install.sh` orchestrator + `.env.example` + `README.md`.
- `.gitignore` for `.env` and `*.tgz` backups.

**Why**
- Baseline starting point. Idempotent, opinionated, OAuth-friendly,
  recoverable. Foundation everything else is built on.

**Files**
- `claude-vps-setup/*` (later migrated to `profiles/cli-bundle/`)

---

## Format

When adding entries, keep them small and structured. One commit-shaped change
per entry. The `What/Why/Files` triple keeps future readers from having to
diff to understand intent.
