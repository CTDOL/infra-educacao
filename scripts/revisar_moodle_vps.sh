#!/usr/bin/env bash
# Diagnostico somente-leitura da instalacao real do Moodle CTDOL. Rodar na VPS.
# Uso: bash scripts/revisar_moodle_vps.sh
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"
WARNINGS=0; FAILURES=0
require_moodle

echo "=== 1. PHP ==="
"$PHP_BIN" -v | head -1
PHPV=$("$PHP_BIN" -r 'echo PHP_VERSION;')
[[ "$PHPV" == 8.3.* ]] && ok "PHP $PHPV (8.3 esperado)" || warn "PHP $PHPV diferente de 8.3"
MODS=$("$PHP_BIN" -m | tr 'A-Z' 'a-z')
for m in curl ctype dom gd iconv intl json mbstring openssl pcre simplexml spl xml zip zlib sodium fileinfo mysqli soap xmlrpc opcache; do
  if grep -qx "$m" <<<"$MODS"; then ok "ext $m"
  else
    case $m in xmlrpc|soap|opcache) warn "ext $m ausente (recomendada)";; *) fail "ext $m AUSENTE (obrigatoria)";; esac
  fi
done
MIV=$("$PHP_BIN" -r 'echo ini_get("max_input_vars");')
[ "${MIV:-0}" -ge 5000 ] && ok "max_input_vars=$MIV" || fail "max_input_vars=$MIV (minimo 5000)"

echo; echo "=== 2. Versao Moodle ==="
"$PHP_BIN" -r 'define("MOODLE_INTERNAL",true); include $argv[1]; echo "release=$release version=$version\n";' "$MOODLE_DIR/version.php" 2>/dev/null \
  && ok "version.php lido" || fail "nao foi possivel ler version.php"

echo; echo "=== 3. Permissoes ==="
for d in "$MOODLE_DIR" "$MOODLEDATA_DIR"; do
  [ -d "$d" ] || { fail "diretorio ausente: $d"; continue; }
  echo "$d  dono=$(stat -c '%U:%G' "$d") modo=$(stat -c '%a' "$d")"
  BADD=$(find "$d" -type d ! -perm 755 2>/dev/null | wc -l)
  BADF=$(find "$d" -type f ! -perm 644 2>/dev/null | wc -l)
  [ "$BADD" -eq 0 ] && ok "pastas 755 em $d" || warn "$BADD pasta(s) fora de 755 em $d"
  [ "$BADF" -eq 0 ] && ok "arquivos 644 em $d" || warn "$BADF arquivo(s) fora de 644 em $d"
done
CM=$(stat -c '%a' "$MOODLE_DIR/config.php")
[[ "$CM" =~ ^(400|440|600|640|644)$ ]] && ok "config.php modo $CM" || warn "config.php modo $CM"
case "$MOODLEDATA_DIR" in "$MOODLE_DIR"/*) fail "moodledata DENTRO do web root!";; *) ok "moodledata fora do web root";; esac

echo; echo "=== 4. MySQL ==="
if command -v mysql >/dev/null; then
  load_db_config
  if mysql --defaults-extra-file="$DB_CNF" -e "SELECT 1" "$DB_NAME" >/dev/null 2>&1; then
    ok "conexao MySQL em $DB_NAME"
    NT=$(mysql --defaults-extra-file="$DB_CNF" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME'" 2>/dev/null)
    [ "${NT:-0}" -gt 300 ] && ok "$NT tabelas" || warn "apenas ${NT:-0} tabelas"
    for t in config user config_plugins oauth2_issuer; do
      mysql --defaults-extra-file="$DB_CNF" -N -e "SELECT 1 FROM ${DB_PREFIX}${t} LIMIT 1" "$DB_NAME" >/dev/null 2>&1 \
        && ok "tabela ${DB_PREFIX}${t}" || warn "tabela ${DB_PREFIX}${t} vazia/ausente"
    done
  else fail "sem conexao MySQL com $DB_NAME"; fi
else warn "cliente mysql indisponivel"; fi

echo; echo "=== 5. Keycloak SSO (auth_oauth2) ==="
AUTH=$("$PHP_BIN" "$MOODLE_DIR/admin/cli/cfg.php" --name=auth 2>/dev/null)
echo "auth ativo: ${AUTH:-?}"
case ",$AUTH," in
  *,manual,*) warn "auth 'manual' ATIVO (Break-Glass ligado? Reverter: cfg.php --name=auth --set=oauth2)";;
  *,oauth2,*) ok "somente oauth2 (Zero Trust)";;
  *) fail "oauth2 NAO esta habilitado em auth";;
esac
[ -d "$MOODLE_DIR/auth/oauth2" ] && ok "plugin auth/oauth2 presente" || fail "auth/oauth2 ausente"
if command -v mysql >/dev/null && [ -n "${DB_CNF:-}" ]; then
  mysql --defaults-extra-file="$DB_CNF" -t -e "SELECT id,name,baseurl,enabled,showonloginpage FROM ${DB_PREFIX}oauth2_issuer" "$DB_NAME" 2>/dev/null \
    || warn "nao foi possivel listar oauth2_issuer"
fi
CODE=$(curl -s -o /dev/null -w '%{http_code}' "$KEYCLOAK_REALM_URL/.well-known/openid-configuration")
[ "$CODE" = 200 ] && ok "discovery OIDC do realm moodle: 200" || fail "discovery OIDC retornou $CODE"
LOGIN=$(curl -s "${MOODLE_URL}login/index.php")
grep -qi 'Entrar com Conta CTDOL' <<<"$LOGIN" && ok "botao 'Entrar com Conta CTDOL' visivel" || warn "botao SSO nao encontrado na tela de login"

echo; echo "=== 6. Plugins nao-padrao ==="
"$PHP_BIN" "$MOODLE_DIR/admin/cli/uninstall_plugins.php" --show-contrib 2>/dev/null | head -40 || warn "listagem de plugins contrib falhou"
ls -d "$MOODLE_DIR"/local/*/ "$MOODLE_DIR"/theme/*/ 2>/dev/null | head -30

echo; echo "=== 7. Cron ==="
crontab -l 2>/dev/null | grep -q 'admin/cli/cron.php' && ok "cron do Moodle no crontab" || warn "cron nao encontrado no crontab do usuario atual"

echo; echo "=== RELATORIO: $FAILURES falha(s), $WARNINGS aviso(s) ==="
[ "$FAILURES" -eq 0 ]
