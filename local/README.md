# local/ — Plugins locais CTDOL

Versionamento dos plugins proprios (relatorios, integracoes). Cada plugin em `local/<nome>/` espelha `local/<nome>` do Moodle.

## Convencoes
- Componente `local_ctdol<funcao>` (ex.: `local_ctdolrelatorios`); `version.php` com `$plugin->component`, `$plugin->version` (AAAAMMDDXX), `$plugin->requires` (Moodle 4.5 = 2024100700), `$plugin->maturity`.
- Usar as APIs do Moodle (DB API, capabilities, privacy provider, lang strings). Sem SQL cru concatenado; sem segredos no codigo.
- Integracoes externas: configuracao via settings do admin; credenciais nunca no git.
- **Nao interferir no `auth_oauth2`/Keycloak** (realm `moodle`); qualquer plugin de identidade deve apenas consumir a sessao existente.

## Deploy
Sincronizar para `/home/ctdolc07/edu.ctdol.com.br/local/<nome>/`, entao (com backup previo):
```bash
/usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/upgrade.php --non-interactive
bash ~/infra-educacao/scripts/limpar_cache.sh
```
