# Instrucoes para IA operadora — acesso ao repo, SSH na VPS e CI/CD

Documento para outra IA/agente que assuma a operacao do Moodle CTDOL. **Leia `CLAUDE.md` primeiro**: suas regras (Keycloak SSO, cPanel/WHM) prevalecem sobre este arquivo.

## 0. Limites inegociaveis
- Nao alterar/desativar o SSO Keycloak (`auth_oauth2`, realm `moodle`). Break-Glass so com pedido explicito do operador e com reversao imediata depois.
- Nunca editar `httpd.conf`/`apache2.conf`; nunca `systemctl` no Apache (usar `/scripts/restartsrv_httpd`, so root).
- Nunca expor `moodledata`; nunca commitar segredos (`config.php`, `.env`, dumps, chaves, client secret).
- A conta `ctdolc07` hospeda outros subdominios: nao tocar em nada fora de `~/edu.ctdol.com.br`, `~/moodledata`, `~/infra-educacao`, `~/backups/moodle`, `~/logs`.
- Acao destrutiva/`root`/alterar `auth`: pedir confirmacao ao operador e rodar `scripts/backup_moodle.sh` antes.
- Nunca pedir ou colar senhas/chaves privadas no chat ou em commits. Segredos vao em GitHub Secrets ou no proprio servidor.

## 1. Acesso ao repositorio (GitHub)
- Repo: `https://github.com/CTDOL/infra-educacao` (base `main`; trabalhar em branch `tipo/descricao` e abrir PR).
- Requer o Claude GitHub App/token com acesso ao repo (org admin instala em https://github.com/apps/claude/installations/select_target).
- Commits: `tipo(escopo): descricao [Agente]`, em portugues. Nunca push direto em `main`; nunca `--force` em branch alheia.

## 2. Acesso SSH a VPS (`vps-14409668`, HostGator)
O operador executa/autoriza; a IA **nao** guarda chave privada pessoal do operador.
1. **Chave dedicada de deploy** (gerar no Mac do operador, sem passphrase apenas se for para o CI):
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/ctdol_deploy -C "github-actions-deploy" -N ""
   ```
2. Na VPS, como `ctdolc07`, autorizar so a chave publica, **restrita** a um comando fixo:
   ```bash
   # ~/.ssh/authorized_keys  (uma linha)
   command="/bin/bash /home/ctdolc07/infra-educacao/scripts/deploy_ci.sh",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty ssh-ed25519 AAAA... github-actions-deploy
   ```
   (Se `scripts/deploy_ci.sh` ainda nao existir, criar conforme secao 4 antes de restringir; enquanto isso, teste manualmente.)
3. Segredos no GitHub (Settings > Secrets and variables > Actions, environment **production**):
   - `VPS_SSH_KEY` = conteudo de `~/.ssh/ctdol_deploy` (privada)
   - `VPS_HOST` = IP/host da VPS · `VPS_USER` = `ctdolc07` · `VPS_PORT` = porta SSH
   - `VPS_KNOWN_HOSTS` = saida de `ssh-keyscan -p <porta> <host>` (pin do host key; **nunca** usar `StrictHostKeyChecking=no`)
4. Acesso `root` **nao** entra no CI. Operacoes root (reload Apache, WHM) ficam manuais pelo operador.
5. Diagnostico inicial (somente leitura), como `ctdolc07`:
   ```bash
   cd ~/infra-educacao && git pull --ff-only
   bash scripts/revisar_moodle_vps.sh
   bash scripts/status_moodle.sh
   ```

## 3. CI (verificacao em PR/push) — `.github/workflows/ci.yml`
Criar via PR. Sem segredos; roda em PR e em push para `main`.
```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  verificar:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Sintaxe bash + shellcheck
        run: |
          sudo apt-get install -y shellcheck
          for f in scripts/*.sh scripts/lib/*.sh; do bash -n "$f"; done
          shellcheck -x -S warning scripts/*.sh scripts/lib/*.sh
      - name: Sintaxe Python
        run: python3 -m py_compile deploy_antigravity.py
      - name: PHP lint do template
        run: |
          sudo apt-get install -y php-cli
          php -l config/config.dist.php
      - name: Proibir segredos e arquivos sensiveis
        run: |
          ! git ls-files | grep -E '(^|/)(config\.php|\.env|.*\.sql(\.gz)?)$'
          ! git grep -nEi '(password|senha|secret)[^=]{0,20}=\s*["'\''][^<"'\'']{6,}' -- ':!docs' ':!*.md' ':!config/config.dist.php'
      - name: Permissao de execucao dos scripts
        run: test -z "$(git ls-files -s scripts/*.sh | awk '$1!="100755"')"
```
Configurar **branch protection** em `main`: exigir PR, o check `CI / verificar` verde e ao menos 1 aprovacao humana.

## 4. CD (deploy na VPS) — `.github/workflows/deploy.yml` + `scripts/deploy_ci.sh`
Deploy so em push para `main`, no environment `production` (com **required reviewers** para aprovacao manual).
```yaml
name: Deploy
on:
  push:
    branches: [main]
concurrency: deploy-producao
permissions:
  contents: read
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Preparar SSH
        run: |
          install -m 700 -d ~/.ssh
          echo "${{ secrets.VPS_SSH_KEY }}" > ~/.ssh/id && chmod 600 ~/.ssh/id
          echo "${{ secrets.VPS_KNOWN_HOSTS }}" > ~/.ssh/known_hosts
      - name: Deploy
        run: ssh -i ~/.ssh/id -p "${{ secrets.VPS_PORT }}" -o BatchMode=yes "${{ secrets.VPS_USER }}@${{ secrets.VPS_HOST }}"
```
`scripts/deploy_ci.sh` (executado na VPS pelo forced command; **criar via PR**, idempotente, sem root):
```bash
#!/usr/bin/env bash
set -euo pipefail
cd /home/ctdolc07/infra-educacao
git fetch origin main
git merge --ff-only origin/main            # falha se divergir: nunca sobrescrever
chmod +x scripts/*.sh
bash scripts/backup_moodle.sh              # backup antes de qualquer mudanca
# Sincronizacao de theme/local para o Moodle: adicionar aqui SOMENTE quando existirem
# (rsync --delete restrito a theme/ctdol e local/<plugin>; depois admin/cli/upgrade.php
#  --non-interactive e scripts/limpar_cache.sh).
bash scripts/status_moodle.sh              # falha o job se HTTP/Keycloak/DB/disco criticos falharem
```
Rollback: `git -C ~/infra-educacao revert <sha>` via PR novo (nao reescrever historico) e restaurar dump de `~/backups/moodle/` se houver mudanca de banco.

## 5. Criterios de "CI/CD garantido" (checklist)
- [ ] `ci.yml` verde em PR e em `main`; branch protection ativa.
- [ ] `deploy.yml` com environment `production` e aprovacao manual; segredos so no GitHub.
- [ ] Chave de deploy restrita (forced command, sem pty/forwarding); host key pinado.
- [ ] `deploy_ci.sh` faz backup, ff-only, status; falha visivel no Actions.
- [ ] Cron do Moodle e backup diario no crontab de `ctdolc07` (ver README).
- [ ] Apos deploy: `status_moodle.sh` = 0 falhas e botao "Entrar com Conta CTDOL" visivel em `/login/index.php`.
- [ ] Nenhum segredo no repo (o historico antigo continha senhas: confirmar que foram rotacionadas).

## 6. Relatorio esperado da IA
Ao concluir cada etapa, reportar: o que mudou (PR/commit), saidas de `revisar_moodle_vps.sh`/`status_moodle.sh`, o que ficou pendente e qualquer acao que exija o operador (root, segredos, aprovacao).
