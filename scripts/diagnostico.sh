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
  echo "  Ultimo backup: ${ultimo:-nenhum encontrado} ($(ls -1 "$BACKUPS" 2>/dev/null | wc -l) arquivos)"
  echo "  Commit implantado: $(git -C "$REPO_DIR" log -1 --format='%h %s' 2>/dev/null)"

  echo
  echo "=== HTTP (visao externa) ==="
  for u in "https://edu.ctdol.com.br/" "https://edu.ctdol.com.br/login/index.php"; do
    echo "  $u -> HTTP $(curl -s -o /dev/null -m 30 -w '%{http_code} em %{time_total}s' "$u")"
  done
  curl -s -m 30 https://edu.ctdol.com.br/login/index.php | grep -q "Entrar com Conta CTDOL" \
    && echo "  Botao SSO 'Entrar com Conta CTDOL': presente" || echo "  Botao SSO 'Entrar com Conta CTDOL': AUSENTE"
  echo "  Cabecalhos de seguranca:"
  curl -sI -m 30 https://edu.ctdol.com.br/ | grep -iE '^(strict-transport-security|x-frame-options|x-content-type-options|content-security-policy|server|x-powered-by):' | sed 's/^/    /'

  echo
  echo "=== ARQUIVOS SENSIVEIS NA RAIZ WEB ==="
  achados=$(find "$MOODLE_DIR" -maxdepth 2 -type f \( -name '*.sql' -o -name '*.sql.gz' -o -name '.env' -o -name '*.bak' -o -name '*.mbz' -o -name 'config.php.*' \) 2>/dev/null | head -n 10)
  echo "${achados:-  nenhum encontrado}"

  "$PHP_BIN" "$REPO_DIR/scripts/diagnostico.php" tudo 2>&1

  echo "=== Fim do diagnostico ==="
}

principal 2>&1 | mascarar
