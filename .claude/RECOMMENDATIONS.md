# Recommendations — pending design decisions

Each item has a recommended choice + argument. Source: decision points
surfaced while building the multi-profile installer. Review and mark each
**Accept / Reject / Defer** before implementation.

---

## 1. Mutex — coexistência entre profiles
**Recommendation:** Manter rígido, com whitelist explícita.
- Coexistência cria suporte combinatório (N²/2 combos). Mutex remove classe inteira de bugs.
- Whitelist hoje: só `cli-bundle` interna. Se depois quiser `hermes+paperclip` juntos, adiciona combo nomeado (`hermes+paperclip`) com testes específicos.

## 2. Antigravity em VPS headless
**Recommendation:** Marcar `requires-display`, dropar do default.
- Google Antigravity v2 é IDE-first. CLI standalone provavelmente assume browser local pro OAuth callback.
- Default `INSTALL_ANTIGRAVITY=false` (já está). Doc avisa "for workstation, not headless VPS".
- Não remover script — operador local com X11 forward usa.

## 3. Codex npm package name
**Recommendation:** `@openai/codex` (sem `-cli`).
- Nome curto = canal oficial estável. `-cli` é variante histórica/abandonada na maioria dos ecossistemas OpenAI.
- Adicionar fallback no script: tenta `@openai/codex`, se 404 tenta `@openai/codex-cli`.

## 4. API keys storage
**Recommendation:** systemd `EnvironmentFile` quando daemon; `~/.bashrc` resto.
- `~/.bashrc` chmod 600 = OK pra single-user VPS. Vault/age = over-engineering pra escopo atual.
- Quando profile roda como systemd unit, mover keys pra `/etc/<profile>/secrets.env` chmod 600 root:user. Isola do shell.
- Roadmap: documentar migração pra Vault se múltiplos operadores.

## 5. `--dangerously-skip-permissions` no Dream cron
**Recommendation:** Manter + restringir via settings allowlist.
- Headless cron precisa do flag, sem opção realista.
- Mitigação: gerar `~/.claude/settings.dream.json` com `allow: ["Read", "Write(~/.claude/memory/**)", "Edit(~/.claude/memory/**)"]`, passar via `--settings`.
- Garante que mesmo com `--dangerously-skip-permissions`, Claude só toca memory dir.

## 6. UFW hardening default
**Recommendation:** Off por default, script opt-in.
- OAuth flows + ngrok-like tunnels quebram com UFW agressivo. Atrito grande pra ganho marginal em VPS já atrás de cloud firewall.
- `bash 01b-harden.sh` opcional. Doc recomenda + Lightsail security group como primeira linha.

## 7. systemd vs tmux default
**Recommendation:** tmux interativo default, systemd opt-in.
- Agents AI em produção real ainda raro. Usuário típico = dev iterando.
- tmux = trivial recovery (`tmux attach`). systemd = log opaco, requer journalctl literacy.
- `*_AS_SERVICE=true` quando operador realmente quer 24/7.

## 8. Backup strategy
**Recommendation:** Cron local + script `backup.sh` que aceita destino.
- Default: `tar czf ~/backups/harness-$(date).tgz ~/.<profile>/ ~/.claude.json`, rotaciona 7 dias.
- Operador escolhe upload: rclone, aws s3, restic. Não embuto provedor cloud — vendor lock-in.
- Tokens OAuth são curta-vida; perda = re-auth, não catástrofe.

## 9. Auto-update de runtime
**Recommendation:** Pinar versões + cron de check (notify, não apply).
- Auto-update em agent runtime = blast radius alto. Quebra silenciosa = trabalho perdido.
- `.env` tem `OPENCLAW_VERSION`, `PNPM_VERSION` etc. Default `latest` na 1ª install, pin manual depois.
- Cron semanal compara instalado vs upstream, manda email/log. Operador decide upgrade.

## 10. Keys compartilhadas entre profiles
**Recommendation:** Centralizar em `~/.harness/secrets.env`, profiles fazem source.
- Hoje 3 cópias de `ANTHROPIC_API_KEY` = drift garantido + 3 surfaces pra vazar.
- `lib/common.sh` ganha `load_secrets()` que faz `[[ -f ~/.harness/secrets.env ]] && source it` antes do `.env` local.
- Local override ainda funciona (precedência: shell > local .env > global secrets).

## 11. Docker compose alternativo
**Recommendation:** Não agora. Roadmap.
- Triplica trabalho (apt + Docker + dev mode). Cada profile precisaria Dockerfile testado.
- Valor real só aparece quando equipe ≥ 2 ou quer reproducible builds. Hoje target = single-operator VPS.
- Adicionar quando alguém pedir.

## 12. Telemetria global off
**Recommendation:** Sim, em `01-system.sh` via `/etc/environment`.
- `DO_NOT_TRACK=1` + `PAPERCLIP_TELEMETRY_DISABLED=1` + `DISABLE_TELEMETRY=1` em `/etc/environment` afeta todos shells.
- Custo zero, benefício privacy real. Padrão indústria (curl, gh, npm respeitam `DO_NOT_TRACK`).
- Operador desliga removendo linha se quiser opt-in.

---

## Prioridade de implementação sugerida

| Ordem | Itens     | Critério                                      |
|-------|-----------|-----------------------------------------------|
| 1     | #12, #10  | Wins rápidos, baixo risco                     |
| 2     | #5        | Segurança crítica do Dream cron               |
| 3     | #4        | Quando primeira unit systemd entrar           |
| 4     | #3        | Quando primeiro install real falhar           |
| 5     | #9        | Quando primeira regression silenciosa morder  |
| 6     | resto     | Quando dor aparecer                           |

---

## Decisão (preencher)

| #  | Status (Accept / Reject / Defer) | Notas |
|----|----------------------------------|-------|
| 1  |                                  |       |
| 2  |                                  |       |
| 3  |                                  |       |
| 4  |                                  |       |
| 5  |                                  |       |
| 6  |                                  |       |
| 7  |                                  |       |
| 8  |                                  |       |
| 9  |                                  |       |
| 10 |                                  |       |
| 11 |                                  |       |
| 12 |                                  |       |
