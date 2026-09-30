#!/usr/bin/env bash
# ==============================================================================
# descomissionar_erp.sh — Desativação Segura do ERPNext na VPS
# Remove os contêineres Docker residuais e desativa o proxy reverso do Apache
# ==============================================================================
set -euo pipefail

REPO_DIR="/home/ctdolc07/infra-educacao"
ERP_DIR="/home/ctdolc07/erp.ctdol.com.br"

echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] Descomissionando ERPNext..."

# 1. Se houver contêineres antigos rodando no Docker, derrubar
if command -v docker &> /dev/null; then
  echo "==> Verificando contêineres Docker do ERP..."
  cd "$REPO_DIR"
  if [ -f "docker-compose.yml" ]; then
    docker compose down -v || true
  fi
fi

# 2. Desativar o proxy reverso do Apache no subdomínio erp
if [ -f "$ERP_DIR/.htaccess" ]; then
  echo "==> Desativando proxy reverso do Apache em $ERP_DIR/.htaccess..."
  mv "$ERP_DIR/.htaccess" "$ERP_DIR/.htaccess.disabled_$(date +%Y%m%d)" || true
  
  # Criar página de aviso estática
  cat << 'HTML' > "$ERP_DIR/index.html"
<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="utf-8"><title>ERP CTDOL - Descomissionado</title></head>
<body style="font-family:sans-serif;text-align:center;padding:50px;">
  <h2>Serviço Descomissionado</h2>
  <p>O ambiente ERP foi desativado em conformidade com o plano estratégico CTDOL.</p>
</body>
</html>
HTML
fi

echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] ERPNext desativado com sucesso!"
