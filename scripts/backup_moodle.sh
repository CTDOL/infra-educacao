#!/usr/bin/env bash
# Backup do banco Moodle (mysqldump | gzip) + config.php, retencao de 7 dias.
# Uso: bash scripts/backup_moodle.sh   (pode ir no cron diario)
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"
RETENCAO_DIAS="${RETENCAO_DIAS:-7}"
require_moodle
command -v mysqldump >/dev/null || die "mysqldump indisponivel."
load_db_config

umask 077
mkdir -p "$BACKUP_DIR" && chmod 700 "$BACKUP_DIR"
TS=$(date +%Y%m%d_%H%M%S)
DUMP="$BACKUP_DIR/${DB_NAME}_$TS.sql.gz"

info "dump de $DB_NAME -> $DUMP"
if mysqldump --defaults-extra-file="$DB_CNF" --single-transaction --quick --routines --triggers "$DB_NAME" | gzip -9 >"$DUMP" \
   && [ "${PIPESTATUS[0]}" -eq 0 ] && gzip -t "$DUMP"; then
  ok "dump valido ($(du -h "$DUMP" | cut -f1))"
else
  rm -f "$DUMP"; die "falha no dump."
fi

cp -p "$MOODLE_DIR/config.php" "$BACKUP_DIR/config.php_$TS" && ok "config.php copiado"

find "$BACKUP_DIR" -maxdepth 1 -type f \( -name "${DB_NAME}_*.sql.gz" -o -name 'config.php_*' \) -mtime +"$RETENCAO_DIAS" -print -delete \
  | sed 's/^/removido: /'
ok "retencao de ${RETENCAO_DIAS} dias aplicada"
