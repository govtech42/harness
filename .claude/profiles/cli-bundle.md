# cli-bundle — research notes

## Components

| CLI         | Package / installer                                      | Auth                              |
|-------------|----------------------------------------------------------|-----------------------------------|
| Claude Code | `npm i -g @anthropic-ai/claude-code`                     | OAuth (`claude`) or ANTHROPIC_API_KEY |
| Codex       | `npm i -g @openai/codex` *(verify name)*                 | `codex login` or OPENAI_API_KEY   |
| Antigravity | `curl -fsSL https://antigravity.google/cli/install.sh \| bash` | `antigravity login`               |
| Cursor      | `curl -fsSL https://cursor.com/install \| bash`          | `cursor-agent login`              |

## Config dirs (disjoint by design)

- `~/.claude/` — config, memory, MCP registry, dream wrapper + log
- `~/.codex/` — Codex session/config
- `~/.antigravity/` — Antigravity workspace
- `~/.cursor/` — Cursor CLI state

## PATH

All four expected on PATH after `01-system.sh` exports:
- `~/.npm-global/bin` (claude, codex)
- `~/.local/bin` (antigravity, cursor)

## MCP + Dream

`06-mcp.sh` and `07-dream.sh` only matter for Claude. They no-op if their
respective env toggles are off but currently do not gate on `INSTALL_CLAUDE`
— see TODO.

## Resource budget (idle, no model loaded)

- Disk: ~250 MB for all four CLIs
- RAM: negligible idle; usage spikes during agent turns are model-side (remote API)
- Outbound: each CLI maintains an HTTPS session to its provider

## Open questions

- Does Antigravity v2 CLI run headless on a server, or does it require a desktop session?
- Cursor CLI agent mode vs. cursor-cli (IDE link) — confirm we want the former.
