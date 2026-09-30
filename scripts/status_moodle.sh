#!/usr/bin/env bash
# Checagem rapida de saude. Sai com codigo != 0 se algo critico falhar.
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"
FAILURES=0; WARNINGS=0

CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 15 "$MOODLE_URL")
[ "$CODE" = 200 ] && ok "HTTP $MOODLE_URL = 200" || fail "HTTP $MOODLE_URL = $CODE"
CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 15 "${MOODLE_URL}login/index.php")
[ "$CODE" = 200 ] && ok "login/index.php = 200" || fail "login/index.php = $CODE"
CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 15 "$KEYCLOAK_REALM_URL/.well-known/openid-configuration")
[ "$CODE" = 200 ] && ok "Keycloak realm moodle = 200" || warn "Keycloak realm moodle = $CODE (SSO indisponivel; ver Break-Glass no CLAUDE.md)"

if pgrep -x httpd >/dev/null || pgrep -x apache2 >/dev/null || pgrep -f litespeed >/dev/null; then ok "servico web ativo"
else fail "processo Apache/LiteSpeed nao encontrado"; fi

if [ -f "$MOODLE_DIR/config.php" ] && [ -x "$PHP_BIN" ] && command -v mysql >/dev/null; then
  load_db_config
  mysql --defaults-extra-file="$DB_CNF" -e 'SELECT 1' "$DB_NAME" >/dev/null 2>&1 && ok "MySQL $DB_NAME acessivel" || fail "MySQL $DB_NAME inacessivel"
else warn "checagem MySQL ignorada (fora da VPS?)"; fi

for d in "$MOODLE_DIR" "$MOODLEDATA_DIR"; do
  [ -d "$d" ] || continue
  USO=$(df -P "$d" | awk 'NR==2{gsub("%","",$5); print $5}')
  if [ "$USO" -ge 90 ]; then fail "disco $d em ${USO}%"; elif [ "$USO" -ge 80 ]; then warn "disco $d em ${USO}%"; else ok "disco $d em ${USO}%"; fi
done
[ -f "$MOODLEDATA_DIR/climaintenance.html" ] && warn "modo manutencao ATIVO"

echo "== $FAILURES falha(s), $WARNINGS aviso(s) =="
[ "$FAILURES" -eq 0 ]
