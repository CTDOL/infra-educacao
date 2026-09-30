#!/usr/bin/env bash
# ==============================================================================
# limpar_cache.sh — Limpeza de Cache Oficial do Moodle via CLI
# ==============================================================================
set -euo pipefail

PHP_BIN="/usr/local/bin/ea-php83"
MOODLE_DIR="/home/ctdolc07/edu.ctdol.com.br"

echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] Purgando caches do Moodle CTDOL..."
$PHP_BIN "$MOODLE_DIR/admin/cli/purge_caches.php"
echo "==> Caches limpos com sucesso!"
