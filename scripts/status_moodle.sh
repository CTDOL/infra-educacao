#!/usr/bin/env bash
# ==============================================================================
# status_moodle.sh — Checagem de Saúde e Integridade do Moodle CTDOL
# Valida HTTP, Apache, MySQL, Keycloak SSO e disco
# ==============================================================================
set -euo pipefail

PHP_BIN="/usr/local/bin/ea-php83"
MOODLE_DIR="/home/ctdolc07/edu.ctdol.com.br"
DATAROOT="/home/ctdolc07/moodledata"
FAILURES=0

echo "=== [$(date +'%Y-%m-%d %H:%M:%S')] Diagnóstico de Saúde Moodle CTDOL ==="

# Falhas transitorias (ex.: 525 do Cloudflare logo apos limpar caches): ate 3 tentativas.
http_code() {
  local c
  for _ in 1 2 3; do
    c=$(curl -s -o /dev/null -m 30 -w "%{http_code}" "$1")
    case "$c" in 200|303) break ;; esac
    sleep 5
  done
  echo "$c"
}

# 1. Checagem HTTP da Página Inicial e Login
echo -n "[*] Testando endpoint público HTTPS (https://edu.ctdol.com.br)... "
HTTP_CODE=$(http_code https://edu.ctdol.com.br/)
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 303 ]; then
  echo "OK (HTTP $HTTP_CODE)"
else
  echo "FALHA (HTTP $HTTP_CODE)"
  FAILURES=$((FAILURES + 1))
fi

# 2. Checagem da Tela de Login (Keycloak SSO)
echo -n "[*] Testando tela de login SSO (https://edu.ctdol.com.br/login/index.php)... "
LOGIN_CODE=$(http_code https://edu.ctdol.com.br/login/index.php)
if [ "$LOGIN_CODE" -eq 200 ]; then
  echo "OK (HTTP $LOGIN_CODE)"
else
  echo "FALHA (HTTP $LOGIN_CODE)"
  FAILURES=$((FAILURES + 1))
fi

# 3. Checagem do Banco de Dados e Plugin OAuth2 via PHP CLI
echo -n "[*] Testando integridade do banco MySQL e emissor Keycloak... "
if $PHP_BIN -r "define('CLI_SCRIPT', true); require '$MOODLE_DIR/config.php'; \$issuers = \$DB->get_records('oauth2_issuer'); if (count(\$issuers) > 0) { exit(0); } else { exit(1); }" 2>/dev/null; then
  echo "OK (Emissor Keycloak ativo)"
else
  echo "FALHA (Erro ao consultar emissores OAuth2)"
  FAILURES=$((FAILURES + 1))
fi

# 4. Checagem de Espaço em Disco
echo -n "[*] Verificando armazenamento do moodledata... "
MOODLE_DATA_SIZE=$(du -sh "$DATAROOT" 2>/dev/null | cut -f1)
echo "Tamanho atual: $MOODLE_DATA_SIZE"

# Resultado final
echo "------------------------------------------------------------"
if [ "$FAILURES" -eq 0 ]; then
  echo "✅ STATUS GERAL: OPERACIONAL (0 falhas)"
  exit 0
else
  echo "❌ STATUS GERAL: ALERTA ($FAILURES falha(s) detectada(s))"
  exit 1
fi
