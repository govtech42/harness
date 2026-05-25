# openclaw — research notes

Upstream: https://github.com/openclaw/openclaw

## Unknowns (verify against upstream README before first real install)

- Build system (Python? Node? Go? Rust?)
- Run command for the agent loop
- Default ports / network surface
- Required provider API keys (Anthropic? OpenAI? local LLM?)
- Persistent state location

## Current scaffold

`02-openclaw.sh` does:
1. `git clone` (or `git pull`) into `$OPENCLAW_DIR`
2. **TODO marker** — placeholder for upstream build step
3. Optional systemd unit (also TODO — `ExecStart` is a stub)

## .env knobs

- `OPENCLAW_DIR` — clone destination (default `/home/ubuntu/openclaw`)
- `OPENCLAW_REPO` / `OPENCLAW_BRANCH`
- `OPENCLAW_AS_SERVICE` — install systemd unit
- `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` — pass through to the agent
