#!/usr/bin/env bash
# ==============================================================================
# diagnostico.sh — Diagnostico SOMENTE LEITURA (pagamento, saude, erros, seguranca)
# Chamado pelo workflow "Diagnostico" via forced command (SSH_ORIGINAL_COMMAND=diagnostico).
# Nao altera nada: sem restart, sem config, sem escrita fora de stdout.
# Toda a saida passa por um filtro que mascara segredos antes de sair da VPS.
# ==============================================================================
set -uo pipefail

PHP_BIN="/usr/local/bin/ea-php83"
REPO_DIR="${REPO_DIR:-/home/ctdolc07/infra-educacao}"
MOODLE_DIR="/home/ctdolc07/edu.ctdol.com.br"
DATAROOT="/home/ctdolc07/moodledata"
BACKUPS="/home/ctdolc07/backups/moodle"

mascarar() {
  sed -E 's/((pass(word|wd)?|secret|token|api[_-]?key|client[_-]?secret|authorization)[A-Za-z_]*[[:space:]]*[=:][[:space:]]*)[^[:space:],;"]+/\1***MASCARADO***/Ig'
}

principal() {
  echo "=== Diagnostico Moodle CTDOL — $(date +'%Y-%m-%d %H:%M:%S %Z') ==="

  echo
  echo "=== INFRAESTRUTURA ==="
  df -h /home 2>/dev/null | tail -n 1 | awk '{printf "  Disco /home: %s usados de %s (%s)\n", $3, $2, $5}'
  echo "  moodledata: $(du -sh "$DATAROOT" 2>/dev/null | cut -f1)"
  echo "  Memoria livre: $(free -m 2>/dev/null | awk '/Mem:/ {print $7" MB disponiveis de "$2" MB"}')"
  echo "  Carga: $(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)"
  ultimo=$(ls -1t "$BACKUPS" 2>/dev/null | head -n 1)
  if [ -n "$ultimo" ]; then
    echo "  Ultimo backup: ha $(( ($(date +%s) - $(stat -c %Y "$BACKUPS/$ultimo")) / 3600 )) h ($(ls -1 "$BACKUPS" 2>/dev/null | wc -l) guardados)"
  else
    echo "  Ultimo backup: NENHUM encontrado (ATENCAO)"
  fi
  echo "  Commit implantado: $(git -C "$REPO_DIR" log -1 --format='%h' 2>/dev/null)"

  echo
  echo "=== HTTP (visao externa) ==="
  for u in "https://edu.ctdol.com.br/" "https://edu.ctdol.com.br/login/index.php"; do
    echo "  $u -> HTTP $(curl -s -o /dev/null -m 30 -w '%{http_code} em %{time_total}s' "$u")"
  done
  # Captura em variavel: "curl | grep -q" com pipefail da falso negativo (SIGPIPE no curl).
  login_html=$(curl -s -m 30 https://edu.ctdol.com.br/login/index.php)
  grep -q "Entrar com Conta CTDOL" <<<"$login_html" \
    && echo "  Botao SSO 'Entrar com Conta CTDOL': presente" || echo "  Botao SSO 'Entrar com Conta CTDOL': AUSENTE"
  echo "  Cabecalhos de seguranca (presente/AUSENTE):"
  cab=$(curl -sI -m 30 https://edu.ctdol.com.br/)
  for h in strict-transport-security x-frame-options x-content-type-options content-security-policy; do
    echo "$cab" | grep -qi "^$h:" && echo "    $h: presente" || echo "    $h: AUSENTE"
  done
  echo "$cab" | grep -qiE '^(server|x-powered-by):.*[0-9]' && echo "    versao de software exposta em cabecalho: ATENCAO"

  echo
  echo "=== ARQUIVOS SENSIVEIS NA RAIZ WEB ==="
  n_achados=$(find "$MOODLE_DIR" -maxdepth 2 -type f \( -name '*.sql' -o -name '*.sql.gz' -o -name '.env' -o -name '*.bak' -o -name '*.mbz' -o -name 'config.php.*' \) 2>/dev/null | wc -l)
  # So o TIPO e a contagem (o nome do arquivo nao sai: o log do Actions e publico).
  for padrao in '*.sql' '*.sql.gz' '.env' '*.bak' '*.mbz' 'config.php.*'; do
    n=$(find "$MOODLE_DIR" -maxdepth 2 -type f -name "$padrao" 2>/dev/null | wc -l)
    [ "$n" -gt 0 ] && echo "    tipo $padrao: $n"
  done
  echo "  Arquivos suspeitos (dump/.env/.bak/.mbz): $n_achados $([ "$n_achados" -eq 0 ] && echo OK || echo 'ATENCAO - ver no servidor')"

  echo
  echo "=== CRON ==="
  echo "  Entradas de crontab do usuario com cron.php: $(crontab -l 2>/dev/null | grep -v '^#' | grep -c 'admin/cli/cron.php')"
  echo "  (0 = cron do Moodle nao agendado nesta conta; conferir tambem no cPanel > Cron Jobs)"

  "$PHP_BIN" "$REPO_DIR/scripts/diagnostico.php" tudo 2>&1

  echo "=== Fim do diagnostico ==="
}

principal 2>&1 | mascarar
