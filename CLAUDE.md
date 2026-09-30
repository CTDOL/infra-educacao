# 🟣 Diretrizes de Governança e Operação: Moodle LMS CTDOL

> [!tldr] Resumo Executivo
> - **Alvo:** Moodle LMS CTDOL (`https://edu.ctdol.com.br`)
> - **Infraestrutura:** VPS HostGator (`vps-14409668`), conta cPanel `ctdolc07`
> - **Autenticação:** Provedor de Identidade Corporativo Keycloak (Realm `moodle`, OIDC `auth_oauth2`)
> - **Precedência:** As regras de segurança deste arquivo são mandatórias e invioláveis.

---

## 0. Limites Inegociáveis
1. **SSO Keycloak Sagrado:** NUNCA alterar, desativar ou reverter o plugin `auth_oauth2` ou o realm `moodle`. O botão *"Entrar com Conta CTDOL"* em `https://edu.ctdol.com.br/login/index.php` deve permanecer 100% ativo.
2. **Proteção cPanel:** NUNCA edite `httpd.conf` ou `apache2.conf`. NUNCA use `systemctl restart apache2` (reload apenas pelo root com `/scripts/restartsrv_httpd`).
3. **Isolamento ctdolc07:** A conta hospeda múltiplos subdomínios da CTDOL. NÃO altere nada fora de `~/edu.ctdol.com.br`, `~/moodledata`, `~/infra-educacao`, `~/backups/moodle` e `~/logs`.
4. **Zero Leakage:** NUNCA commitar senhas, `config.php`, `.env` ou dumps SQL no Git.

---

## 🛠️ Comandos de Operação na VPS
- **Executar Cron:** `/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cron.php`
- **Limpar Cache:** `/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/purge_caches.php`
- **Modo Manutenção:** `/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/maintenance.php --enable` (ou `--disable`)
- **Status do Sistema:** `bash /home/ctdolc07/infra-educacao/scripts/status_moodle.sh`
- **Backup Manual:** `bash /home/ctdolc07/infra-educacao/scripts/backup_moodle.sh`

---

## 🔐 Procedimento de Emergência (Break-Glass do SSO)
Se o Keycloak estiver indisponível e o administrador precisar acessar via senha local de emergência:
```bash
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cfg.php --name=auth --set=manual,oauth2
```
*Após restabelecer o Keycloak, reverter imediatamente para o padrão Zero Trust:*
```bash
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cfg.php --name=auth --set=oauth2
```
