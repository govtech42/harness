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
