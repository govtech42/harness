# Claude Code VPS Setup (AWS Lightsail / Ubuntu)

Scripts idempotentes para instalar Claude Code + MCP servers em VPS Ubuntu 22.04 LTS.

## Pré-requisitos
- Instância Lightsail Ubuntu 22.04, mín 2 GB RAM
- Static IP anexado
- Acesso SSH como usuário `ubuntu`

## Uso

### 1. Copiar scripts pra VPS
Do teu Mac:
```bash
scp -r claude-vps-setup ubuntu@<IP>:~/
ssh ubuntu@<IP>
cd ~/claude-vps-setup
```

### 2. Configurar .env
```bash
cp .env.example .env
nano .env   # preenche as chaves e habilita os MCPs
```

Variáveis:
| Var | Obrigatório | Descrição |
|-----|-------------|-----------|
| `ANTHROPIC_API_KEY` | Não | Pula OAuth. Pega em console.anthropic.com |
| `CONTEXT7_API_KEY` | Não | Rate limit maior |
| `TIMEZONE` | — | Default `America/Sao_Paulo` |
| `SWAP_SIZE_GB` | — | `0` desativa |
| `MCP_SCOPE` | — | `user` (global) ou `local` (por projeto) |
| `INSTALL_*` | — | Toggle `true`/`false` por servidor |

### 3. Rodar
```bash
chmod +x *.sh
./install.sh
```

Ou passo a passo:
```bash
bash 01-install-system.sh    # Node, git, tmux, swap, timezone
source ~/.bashrc
bash 02-install-claude.sh    # Claude Code + API key
bash 03-install-mcp.sh       # MCP servers
bash 04-install-dream.sh     # Dream mode (optional, opt-in via .env)
```

### 4. Primeira sessão
```bash
tmux new -s claude
claude
```
Dentro do Claude Code:
- `/mcp` → autenticar MCPs OAuth (Linear, Slack, GitHub, Supabase, Notion, Sentry)
- Cola URL no browser local, completa OAuth, volta no terminal

Detach tmux: `Ctrl+b d` · Reattach: `tmux attach -t claude`

## MCPs incluídos
- **Context7** — docs de libs (stdio, free)
- **Linear** — issues/projects (SSE, OAuth)
- **Slack** — mensagens (HTTP, OAuth)
- **GitHub** — PRs, issues, code (HTTP, OAuth)
- **Supabase** — DB ops (HTTP, OAuth)
- **Sentry** — erros prod (HTTP, OAuth) — opcional
- **Notion** — docs (HTTP, OAuth) — opcional
- **Playwright** — browser automation (stdio, instala Chromium) — opcional
- **Filesystem** — acesso a dirs extras (stdio) — opcional

## Dream mode (consolidação de memória)

Pass reflexivo periódico sobre `~/.claude/memory/` — merge duplicatas, corrige
fatos obsoletos, atualiza `MEMORY.md`. Usa o skill
`anthropic-skills:consolidate-memory` em modo headless (`claude -p`).

Habilitar no `.env`:
```env
INSTALL_DREAM=true
DREAM_SCHEDULE=0 3 * * *      # cron user; default 03:00 local
DREAM_PROMPT=                 # opcional, sobrescreve prompt padrão
```

Rodar:
```bash
bash 04-install-dream.sh
```

Primeiro uso — dentro do `claude`, instale o skill:
```
/plugin install anthropic-skills
```
Sem ele, o wrapper usa prompt inline equivalente como fallback.

Artefatos:
- `~/.claude/dream.sh` — wrapper (chmod 700)
- `~/.claude/dream.log` — log (auto-rotaciona a 5 MiB)
- Entrada no crontab do user com marker `# claude-dream`

Testar manualmente:
```bash
~/.claude/dream.sh && tail -n 40 ~/.claude/dream.log
```

Desativar:
```bash
crontab -l | grep -v claude-dream | crontab -
rm ~/.claude/dream.sh
```

## Obsidian vault (workspace compartilhado entre CLIs)

Vault único em `$OBSIDIAN_VAULT_DIR` (default `~/vault`) que todos os CLIs
(Claude, Codex, Antigravity, Cursor) leem e escrevem. Headless — não precisa
do app Obsidian no VPS; vault é só markdown em disco. Workstation com app
Obsidian abre o mesmo vault via git sync.

Habilitar no `.env`:
```env
INSTALL_OBSIDIAN=true
OBSIDIAN_VAULT_DIR=/home/ubuntu/vault
OBSIDIAN_VAULT_REPO=git@github.com:you/your-vault.git    # opcional
OBSIDIAN_AUTOSYNC=true                                    # opt-in
OBSIDIAN_AUTOSYNC_SCHEDULE=*/15 * * * *
```

Rodar:
```bash
bash 08-obsidian.sh
```

Layout criado:
```
~/vault/
├── .claude/log.md           # Claude Code grava aqui
├── .codex/log.md            # Codex
├── .antigravity/log.md      # Antigravity
├── .cursor/log.md           # Cursor
├── inbox.md                 # captura rápida, qualquer agente escreve
├── notes/                   # markdown principal
├── .obsidian/app.json       # config base (versionada se git)
└── .gitignore               # ignora workspace.json, cache, .trash/
```

Acesso por CLI:
- **Claude Code**: MCP `obsidian-vault` registrado em `06-mcp.sh` (filesystem MCP scoped ao vault). Sem necessidade de `cd`.
- **Codex / Antigravity / Cursor**: rode com `cdvault` (alias adicionado no `~/.bashrc`) ou via flag de workspace do CLI.

Git auto-sync (opt-in):
- Cron de user (default `*/15`) faz `git add + commit + pull -X ours + push`
- **Conflitos**: estratégia `-X ours` — edições locais sempre vencem o remoto
- Log: `~/vault/.claude/sync.log`
- Wrapper: `~/.local/bin/obsidian-vault-sync`

Sync manual on-demand:
```bash
source ~/.bashrc
obsidian-vault-sync
```

Desativar auto-sync:
```bash
crontab -l | grep -v obsidian-vault-sync | crontab -
rm ~/.local/bin/obsidian-vault-sync
```

## Plugins (GSD, gstack, superpowers)

Opt-in plugin install handled by `09-plugins.sh`. Headless onde possível;
hint manual onde não.

| Plugin       | Claude            | Codex             | Antigravity                 | Cursor            | OpenCode          |
|--------------|-------------------|-------------------|-----------------------------|-------------------|-------------------|
| GSD          | headless          | —                 | —                           | —                 | —                 |
| gstack       | headless (`./setup`) | —              | —                           | —                 | headless (`./setup --host opencode`) |
| superpowers  | headless          | manual `/plugins` | manual (não documentado)    | manual `/add-plugin` | manual fetch URL |

Toggles no `.env`:
```env
INSTALL_GSD=true                      # Claude only
INSTALL_GSTACK=true
GSTACK_TARGETS="claude opencode"      # ou só "claude"
INSTALL_SUPERPOWERS=true
SUPERPOWERS_CLAUDE=true
SUPERPOWERS_CODEX=true
SUPERPOWERS_CURSOR=true
SUPERPOWERS_OPENCODE=true
SUPERPOWERS_ANTIGRAVITY=false         # não documentado oficialmente
```

Rodar isolado:
```bash
bash 09-plugins.sh
```

**Bun**: gstack precisa de Bun. `09-plugins.sh` instala via `install_bun()` se
`INSTALL_GSTACK=true`.

**Antigravity superpowers**: docs upstream não cobrem. Toggle imprime hint
manual com palpite (padrão Gemini CLI). Sem tentativa automática.

**Manual hints**: Codex/Cursor/OpenCode imprimem mensagem com comando exato
pra colar dentro da sessão. Sem CLI flag headless documentada.

## Manutenção
```bash
claude mcp list                  # ver registrados
claude mcp remove <name> -s user # desregistrar
npm update -g @anthropic-ai/claude-code   # atualizar
```

Reaplicar após mudar `.env`:
```bash
bash 03-install-mcp.sh
```

## Backup
Tokens OAuth ficam em `~/.claude/`. Antes de reinstalar VPS:
```bash
tar czf claude-backup.tgz ~/.claude ~/.claude.json
```

## Troubleshooting
- `claude: command not found` → `source ~/.bashrc` ou `export PATH=~/.npm-global/bin:$PATH`
- MCP OAuth trava → dentro do claude: `/mcp` → seleciona server → re-auth
- RAM cheia → aumenta `SWAP_SIZE_GB` ou desativa MCPs stdio não usados
- Playwright falha → precisa libs sistema: `sudo npx playwright install-deps`
