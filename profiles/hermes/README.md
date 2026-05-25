# Hermes Agent profile

Local install of [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent).

Default path uses the **upstream installer** (`scripts/install.sh`), which
provisions Python 3.11 via `uv` and registers the `hermes` CLI.
Dev path (`HERMES_USE_UPSTREAM_INSTALLER=false`) clones the repo and
runs `setup-hermes.sh` or a manual `uv venv + uv pip install -e ".[all,dev]"`.

## Runtime
- Python **3.11** (installed by `01-system.sh`)
- `uv` (Astral, installed by `01-system.sh`)
- No fixed default port

## Usage
```bash
cp .env.example .env && nano .env       # provider keys (OpenRouter / OpenAI / etc.)
bash install.sh                          # or ../../install.sh hermes
```

After install:
```bash
hermes setup           # configuration wizard
hermes model           # pick LLM provider
hermes tools           # toggle tools
hermes                 # interactive CLI
hermes gateway         # messaging gateway
```

## Mutex
Refuses if another profile is installed. Override: `bash install.sh --force`.
