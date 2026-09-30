#!/usr/bin/env bash
# Derruba o ERPNext legado na VPS. DESTRUTIVO: "down -v" apaga volumes (dados do ERP).
# Uso: bash scripts/descomissionar_erp.sh [--yes]
# Idempotente: pode ser reexecutado sem efeito colateral.
set -uo pipefail
ERP_COMPOSE_DIR="${ERP_COMPOSE_DIR:-$HOME/infra-educacao}"
ERP_WEB_DIR="${ERP_WEB_DIR:-$HOME/erp.ctdol.com.br}"

echo "ATENCAO: remove containers e VOLUMES do ERPNext e desativa o proxy em $ERP_WEB_DIR."
echo "Faca backup dos volumes antes se houver qualquer dado a preservar."
if [ "${1:-}" != "--yes" ]; then
  read -r -p "Digite DESCOMISSIONAR para continuar: " ans
  [ "$ans" = "DESCOMISSIONAR" ] || { echo "Abortado."; exit 1; }
fi

# 1. Docker (o docker-compose.yml foi removido do repo; usa arquivo legado local ou historico git)
if command -v docker >/dev/null; then
  if [ -f "$ERP_COMPOSE_DIR/docker-compose.yml" ]; then
    (cd "$ERP_COMPOSE_DIR" && docker compose down -v --remove-orphans) || echo "aviso: compose down falhou"
  else
    echo "docker-compose.yml nao esta mais presente em $ERP_COMPOSE_DIR; removendo por nome/rotulo."
    ids=$(docker ps -aq --filter "name=erp" --filter "name=frappe" 2>/dev/null)
    [ -n "$ids" ] && docker rm -f $ids
  fi
else
  echo "docker nao instalado; passo ignorado."
fi

# 2. .htaccess de proxy reverso
if [ -f "$ERP_WEB_DIR/.htaccess" ]; then
  mv "$ERP_WEB_DIR/.htaccess" "$ERP_WEB_DIR/.htaccess.desativado.$(date +%Y%m%d%H%M%S)" && echo "proxy desativado."
else
  echo ".htaccess ja ausente/desativado."
fi

# 3. Recarga segura do Apache (WHM/cPanel; exige root)
if [ -x /scripts/restartsrv_httpd ]; then
  /scripts/restartsrv_httpd || echo "aviso: falha ao recarregar Apache (precisa ser root)"
else
  echo "aviso: /scripts/restartsrv_httpd indisponivel (rode como root)."
fi
echo "Concluido. Remova tambem o DNS/subdominio erp.ctdol.com.br no cPanel/Cloudflare se nao for mais usado."
