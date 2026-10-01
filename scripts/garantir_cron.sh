#!/usr/bin/env bash
# ==============================================================================
# garantir_cron.sh — Garante a entrada do cron do Moodle no crontab de ctdolc07
# Chamado pelo deploy_ci.sh. Idempotente: se a entrada ja existe, nao faz nada.
#
# A conta hospeda outros subdominios da CTDOL: este script NUNCA altera nem remove
# outras linhas do crontab. So acrescenta a do Moodle, com backup antes e
# verificacao depois (se as linhas antigas nao estiverem intactas, restaura o backup).
# ==============================================================================
set -uo pipefail

MARCA="edu.ctdol.com.br/admin/cli/cron.php"
LINHA="* * * * * /usr/local/bin/ea-php83 /home/ctdolc07/edu.ctdol.com.br/admin/cli/cron.php >/home/ctdolc07/logs/moodle-cron.log 2>&1"
BACKUPS="/home/ctdolc07/backups/moodle"

atual=$(crontab -l 2>/tmp/garantir_cron.err); rc=$?
if [ $rc -ne 0 ]; then
  # Codigo != 0 so e aceitavel quando a conta ainda nao tem crontab.
  if grep -qi "no crontab" /tmp/garantir_cron.err; then
    atual=""
  else
    echo "ERRO: nao foi possivel ler o crontab; nada alterado."
    rm -f /tmp/garantir_cron.err
    exit 1
  fi
fi
rm -f /tmp/garantir_cron.err

if grep -v '^[[:space:]]*#' <<<"$atual" | grep -qF "$MARCA"; then
  echo "Cron do Moodle ja agendado; nada a fazer."
  exit 0
fi

mkdir -p "$BACKUPS" /home/ctdolc07/logs
copia="$BACKUPS/crontab-$(date +%Y%m%d-%H%M%S).bak"
printf '%s\n' "$atual" > "$copia"

{ [ -n "$atual" ] && printf '%s\n' "$atual"; echo "$LINHA"; } | crontab - || {
  echo "ERRO: crontab recusou a nova tabela; nada alterado."
  exit 1
}

# Verificacao: todas as linhas antigas continuam e a do Moodle entrou.
novo=$(crontab -l 2>/dev/null)
esperado=$({ [ -n "$atual" ] && printf '%s\n' "$atual"; echo "$LINHA"; })
if [ "$novo" != "$esperado" ]; then
  echo "ERRO: crontab resultante difere do esperado; restaurando backup $copia."
  if [ -s "$copia" ] && [ -n "$atual" ]; then crontab "$copia"; else crontab -r 2>/dev/null; fi
  exit 1
fi
echo "Cron do Moodle agendado (a cada minuto). Backup do crontab anterior: $copia"
