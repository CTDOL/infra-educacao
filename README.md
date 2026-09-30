# 🎓 Moodle LMS CTDOL — Infraestrutura

Repositorio de infraestrutura, automacao e customizacoes do **Moodle 4.5** da CTDOL, com login exclusivo via **Keycloak SSO**.
Governanca e regras para o Claude Code: [`CLAUDE.md`](CLAUDE.md).

- **Plataforma:** https://edu.ctdol.com.br/ · **Login:** https://edu.ctdol.com.br/login/index.php
- **IdP:** https://sso.ctdol.com.br/realms/moodle

## 🏗️ Topologia (VPS HostGator `vps-14409668`)
| Componente | Detalhe |
|---|---|
| Painel / conta | cPanel/WHM, conta `ctdolc07` (multiplos subdominios) |
| Web | Apache (cPanel) + LiteSpeed PHP 8.3 (`/usr/local/bin/ea-php83`); Cloudflare na frente |
| Codigo | `/home/ctdolc07/edu.ctdol.com.br/` |
| Dados | `/home/ctdolc07/moodledata/` (fora do web root) |
| Banco | MySQL local `ctdolc07_moodle` |
| Cron | `ea-php83 .../admin/cli/cron.php` a cada minuto |
| Este repo | `/home/ctdolc07/infra-educacao` |

## 🔐 Autenticacao Keycloak SSO (Zero Trust)
Contas manuais locais estao bloqueadas; o acesso e pelo botao **"Entrar com Conta CTDOL"**.

```
Usuario -> Moodle /login (botao SSO)
        -> Keycloak realm "moodle" (sso.ctdol.com.br) autentica
        -> redirect para https://edu.ctdol.com.br/admin/oauth2callback.php?code=...
        -> Moodle (auth_oauth2) troca code por token, le userinfo, cria/loga o usuario
```
- Plugin: `auth_oauth2` nativo, emissor OpenID Connect. Segredo do client so no Moodle/Keycloak (nunca no git).
- **Contingencia (Break-Glass)** se o Keycloak cair — libera login manual temporario:
  ```bash
  /usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cfg.php --name=auth --set=manual,oauth2
  ```
  Ao terminar, reverter: `... cfg.php --name=auth --set=oauth2` e limpar caches.

## 🧰 Manual rapido dos scripts (`scripts/`)
Rodar na VPS como `ctdolc07`, a partir de `~/infra-educacao`.

| Script | Funcao |
|---|---|
| `revisar_moodle_vps.sh` | Diagnostico read-only: PHP/extensoes, permissoes, MySQL, emissor OAuth2/Keycloak, plugins, cron; relatorio final |
| `status_moodle.sh` | Saude rapida: HTTP 200, Keycloak, servico web, MySQL, disco (exit != 0 se critico) |
| `backup_moodle.sh` | `mysqldump`+gzip em `~/backups/moodle/`, copia do `config.php`, retencao 7 dias |
| `cron_moodle.sh` | Wrapper do cron com `flock` e log rotativo `~/logs/moodle_cron.log` |
| `limpar_cache.sh` | `purge_caches.php` via PHP 8.3 |
| `descomissionar_erp.sh` | Derruba o ERPNext legado (destrutivo, pede confirmacao; root p/ Apache) |

Crontab sugerido (`crontab -e`):
```cron
* * * * * /bin/bash /home/ctdolc07/infra-educacao/scripts/cron_moodle.sh
30 2 * * * /bin/bash /home/ctdolc07/infra-educacao/scripts/backup_moodle.sh
```
Os scripts leem credenciais do `config.php` real; nada de senha no repo.

## 🚀 Deploy / sincronizacao via Git na VPS
```bash
ssh ctdolc07@vps-14409668
cd ~/infra-educacao && git pull --ff-only     # ou: python3 deploy_antigravity.py [--purge-cache]
bash scripts/status_moodle.sh
```
Primeira vez: `git clone https://github.com/CTDOL/infra-educacao.git ~/infra-educacao && chmod +x ~/infra-educacao/scripts/*.sh`.
Customizacoes (`theme/`, `local/`): sincronizar para o diretorio do Moodle, `backup_moodle.sh`, `admin/cli/upgrade.php`, `limpar_cache.sh`.
Reload do Apache (root): `/scripts/restartsrv_httpd` — nunca `systemctl`, nunca editar `httpd.conf`.

## 📂 Estrutura
`CLAUDE.md` · `config/config.dist.php` (template sem segredos) · `scripts/` · `theme/` · `local/` · `docs/historico/` (notas da instalacao original) · `deploy_antigravity.py`
