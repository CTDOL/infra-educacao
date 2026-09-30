# CLAUDE.md — Moodle LMS CTDOL (Sala Vermelha)

**Motor:** 🟣 Claude Code · **Escopo:** este repositório serve EXCLUSIVAMENTE ao Moodle LMS da CTDOL.
Qualquer artefato de ERP/Docker legado foi expurgado; nao reintroduzir.

## 1. Topologia de producao
| Item | Valor |
|---|---|
| URL publica | https://edu.ctdol.com.br/ (Moodle 4.5 Stable) |
| Login | https://edu.ctdol.com.br/login/index.php |
| Host | VPS HostGator `vps-14409668` (cPanel/WHM, CDN/DNS Cloudflare) |
| Conta cPanel | `ctdolc07` (hospeda varios subdominios institucionais — rigor absoluto) |
| Web server | Apache (cPanel) + LiteSpeed PHP 8.3 |
| PHP CLI | `/usr/local/bin/ea-php83` |
| Codigo Moodle | `/home/ctdolc07/edu.ctdol.com.br/` |
| Moodledata | `/home/ctdolc07/moodledata/` (fora do web root; 755 pastas / 644 arquivos) |
| Banco | MySQL local `ctdolc07_moodle` |
| Este repo na VPS | `/home/ctdolc07/infra-educacao` (fora do public_html) |
| Cron ativo | `/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cron.php` |

O operador tem SSH completo (usuario `ctdolc07` e `root`) a partir do Mac. Claude **nao** tem acesso a VPS:
prepara scripts/comandos para o operador executar.

## 2. Autenticacao Keycloak SSO — PRESERVACAO OBRIGATORIA
Configuracao **ativa em producao**. Nao alterar, desativar ou versionar segredos dela.

- **Modelo:** Zero Trust. Contas manuais locais bloqueadas; login somente via IdP corporativo, botao **"Entrar com Conta CTDOL"**.
- **IdP:** Keycloak central `https://sso.ctdol.com.br`, realm dedicado **`moodle`** (`https://sso.ctdol.com.br/realms/moodle`).
- **Discovery OIDC:** `https://sso.ctdol.com.br/realms/moodle/.well-known/openid-configuration`
- **Plugin:** `auth_oauth2` nativo do Moodle, emissor OpenID Connect (Administracao > Servidor > OAuth 2).
- **Callback (redirect URI no client Keycloak):** `https://edu.ctdol.com.br/admin/oauth2callback.php`
- **Client secret:** vive apenas no Moodle (banco) e no Keycloak. NUNCA em git.
- **Fluxo:** usuario -> botao SSO -> redirect ao Keycloak (realm `moodle`) -> autentica -> callback `oauth2callback.php` com `code` -> Moodle troca por token, le userinfo, loga/cria conta.

### Break-Glass (Keycloak fora do ar)
Habilita login manual temporariamente (root ou `ctdolc07` na VPS):
```bash
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cfg.php --name=auth --set=manual,oauth2
```
**Reverter assim que o SSO voltar** (senao o Zero Trust fica comprometido):
```bash
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cfg.php --name=auth --set=oauth2
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/purge_caches.php
```
`scripts/revisar_moodle_vps.sh` avisa se `manual` estiver ativo.

## 3. Comandos operacionais (VPS)
```bash
# Cron
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cron.php
# Limpar cache
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/purge_caches.php
# Manutencao
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/maintenance.php --enable   # ou --disable
# Reload seguro do Apache (root)
/scripts/restartsrv_httpd
```
Wrappers em `scripts/` (ver README.md).

## 4. Regras de seguranca estritas (cPanel/WHM)
1. NUNCA editar `httpd.conf` / `apache2.conf` (cPanel sobrescreve). Ajustes via `.htaccess` ou includes do WHM.
2. NUNCA reiniciar Apache com `systemctl`; usar `/scripts/restartsrv_httpd`.
3. NUNCA expor `moodledata` via web.
4. NUNCA commitar `config.php` real, `.env`, dumps SQL, logs, senhas ou client secret do Keycloak.
5. NUNCA instalar dependencias globais no servidor cPanel nem mexer em outros subdominios da conta `ctdolc07`.
6. Toda acao destrutiva (drop, `rm -rf`, alterar `auth`) exige confirmacao explicita do operador; fazer `scripts/backup_moodle.sh` antes.

## 5. Convencoes
- Scripts bash: idempotentes, `set -uo pipefail`, credenciais lidas do `config.php` real (`scripts/lib/common.sh`).
- Commits: `tipo(escopo): descricao [Claude]`, em portugues, sem segredos.
- Tema/plugins proprios: `theme/README.md` e `local/README.md`.
