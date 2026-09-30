#!/usr/bin/env bash
# ==============================================================================
# backup_moodle.sh — Backup Automatizado do Banco e Configurações do Moodle
# Gera dump compactado em ~/backups/moodle/ com retenção dos últimos 7 dias
# ==============================================================================
set -euo pipefail

BACKUP_DIR="/home/ctdolc07/backups/moodle"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CONFIG_FILE="/home/ctdolc07/edu.ctdol.com.br/config.php"

mkdir -p "$BACKUP_DIR"

# Arquivo de credenciais temporario (600): evita a senha na linha de comando (visivel em `ps aux`)
MYSQL_CNF="$(mktemp)"
trap 'rm -f "$MYSQL_CNF"' EXIT
chmod 600 "$MYSQL_CNF"

echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] Gerando backup do Moodle CTDOL..."

# Extrair credenciais do config.php sem expor no terminal
DB_NAME=$(grep "\$CFG->dbname" "$CONFIG_FILE" | cut -d"'" -f2)
DB_USER=$(grep "\$CFG->dbuser" "$CONFIG_FILE" | cut -d"'" -f2)
DB_PASS=$(grep "\$CFG->dbpass" "$CONFIG_FILE" | cut -d"'" -f2)

printf '[client]\nuser=%s\npassword=%s\n' "$DB_USER" "$DB_PASS" > "$MYSQL_CNF"

DUMP_FILE="$BACKUP_DIR/moodle_db_${TIMESTAMP}.sql.gz"
CONFIG_BACKUP="$BACKUP_DIR/config_${TIMESTAMP}.php"

# Realizar dump MySQL limpo e compactar com gzip
mysqldump --defaults-extra-file="$MYSQL_CNF" --no-tablespaces --single-transaction --quick "$DB_NAME" 2>/dev/null | gzip > "$DUMP_FILE"
chmod 600 "$DUMP_FILE"

# Snapshot do config.php
cp "$CONFIG_FILE" "$CONFIG_BACKUP"
chmod 600 "$CONFIG_BACKUP"

echo "==> Backup concluído: $DUMP_FILE ($(du -h "$DUMP_FILE" | cut -f1))"

# Rotação de backups: manter os últimos 7 dias
echo "==> Aplicando política de retenção (7 dias)..."
find "$BACKUP_DIR" -type f -name "moodle_db_*.sql.gz" -mtime +7 -delete || true
find "$BACKUP_DIR" -type f -name "config_*.php" -mtime +7 -delete || true

echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] Rotina de backup finalizada."
