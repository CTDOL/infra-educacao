#!/usr/bin/env bash
# ==============================================================================
# revisar_moodle_vps.sh — Diagnóstico Completo da Instalação do Moodle na VPS
# Executa auditoria técnica de PHP, permissões e integrações
# ==============================================================================
set -euo pipefail

PHP_BIN="/usr/local/bin/ea-php83"
MOODLE_DIR="/home/ctdolc07/edu.ctdol.com.br"
DATAROOT="/home/ctdolc07/moodledata"

echo "=== [$(date +'%Y-%m-%d %H:%M:%S')] Auditoria da Instalação Moodle VPS ==="

echo "1. Versão do PHP e Módulos:"
$PHP_BIN -v | head -n 1
echo -n "   Módulos críticos: "
$PHP_BIN -m | grep -E "mysqli|curl|gd|intl|mbstring|xml|zip|sodium|opcache" | tr '\n' ' '
echo ""

echo "2. Permissões de Diretórios:"
ls -ld "$MOODLE_DIR"
ls -ld "$DATAROOT"

echo "3. Autenticação e Provedores OAuth2 Ativos:"
$PHP_BIN -r "
define('CLI_SCRIPT', true);
require '$MOODLE_DIR/config.php';
echo '   Auth plugins: ' . get_config('core', 'auth') . PHP_EOL;
\$issuers = \$DB->get_records('oauth2_issuer');
foreach (\$issuers as \$i) {
    echo '   -> Issuer: ' . \$i->name . ' | URL: ' . \$i->baseurl . ' | Client: ' . \$i->clientid . ' | Ativo: ' . (\$i->enabled ? 'SIM' : 'NÃO') . PHP_EOL;
}
"

echo "4. Informações da Versão do Moodle:"
$PHP_BIN -r "
define('CLI_SCRIPT', true);
require '$MOODLE_DIR/config.php';
require_once '$MOODLE_DIR/version.php';
echo '   Moodle Release: ' . \$release . ' (Build: ' . \$version . ')' . PHP_EOL;
"

echo "=== Auditoria Concluída ==="
