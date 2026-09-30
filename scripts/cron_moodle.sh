#!/usr/bin/env bash
# Wrapper do cron do Moodle com log rotativo. Crontab (cPanel, a cada minuto):
#   * * * * * /bin/bash /home/ctdolc07/infra-educacao/scripts/cron_moodle.sh
# flock evita execucoes sobrepostas.
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"
LOG="${LOG:-$LOG_DIR/moodle_cron.log}"
MAX_KB="${MAX_KB:-5120}"   # rotaciona acima de 5 MB
KEEP="${KEEP:-5}"
require_moodle
mkdir -p "$LOG_DIR"

if [ -f "$LOG" ] && [ "$(du -k "$LOG" | cut -f1)" -ge "$MAX_KB" ]; then
  for i in $(seq $((KEEP-1)) -1 1); do [ -f "$LOG.$i" ] && mv "$LOG.$i" "$LOG.$((i+1))"; done
  mv "$LOG" "$LOG.1"
fi

exec 9>"$LOG_DIR/.moodle_cron.lock"
flock -n 9 || { echo "$(date '+%F %T') cron anterior ainda em execucao; pulando" >>"$LOG"; exit 0; }
{ echo "--- $(date '+%F %T') inicio"; "$PHP_BIN" "$MOODLE_DIR/admin/cli/cron.php"; echo "--- fim (rc=$?)"; } >>"$LOG" 2>&1
