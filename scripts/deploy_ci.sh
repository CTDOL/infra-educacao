#!/usr/bin/env bash
# ==============================================================================
# deploy_ci.sh — Script de Deploy Automatizado (Forced Command via CI/CD)
# Executado na VPS pelo pipeline do GitHub Actions sob o usuário ctdolc07
# ==============================================================================
set -euo pipefail

REPO_DIR="${REPO_DIR:-/home/ctdolc07/infra-educacao}"
cd "$REPO_DIR"

# --- Etapa 1: sincroniza o repositorio e REEXECUTA este script ----------------
# O "git merge" pode reescrever este proprio arquivo enquanto o bash o le, e o
# processo em curso continuaria com a versao antiga (passos novos nao rodariam).
# O "exec" recarrega o arquivo ja atualizado. Mantenha esta etapa curta e estavel.
if [ "${CTDOL_DEPLOY_ETAPA:-1}" = "1" ]; then
  echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] Iniciando deploy do Moodle CTDOL..."
  echo "==> Sincronizando com a branch main..."
  git fetch origin main
  git merge --ff-only origin/main
  chmod +x "$REPO_DIR"/scripts/*.sh
  CTDOL_DEPLOY_ETAPA=2 exec bash "$REPO_DIR/scripts/deploy_ci.sh"
fi

# --- Etapa 2: passos de deploy (ja com a versao atualizada do script) ---------

echo "==> Executando backup preventivo..."
bash "$REPO_DIR/scripts/backup_moodle.sh"

# --- Sincronizacao de customizacoes (theme/ctdol e local/*) -> Moodle ---------
PHP_BIN="/usr/local/bin/ea-php83"
MOODLE_DIR="/home/ctdolc07/edu.ctdol.com.br"
RSYNC_OPTS=(-a --delete "--chmod=D755,F644")

echo "==> Sincronizando tema theme/ctdol..."
rsync "${RSYNC_OPTS[@]}" "$REPO_DIR/theme/ctdol/" "$MOODLE_DIR/theme/ctdol/"

# Plugins locais: cada pasta local/<plugin>/ vai para o mesmo nome no Moodle.
# --delete atua somente dentro de cada plugin, nunca na raiz de local/ do Moodle.
for plugin_dir in "$REPO_DIR"/local/*/; do
  [ -d "$plugin_dir" ] || continue
  name="$(basename "$plugin_dir")"
  echo "==> Sincronizando plugin local/$name..."
  rsync "${RSYNC_OPTS[@]}" "$plugin_dir" "$MOODLE_DIR/local/$name/"
done

echo "==> Aplicando upgrade do Moodle e limpando caches..."
"$PHP_BIN" "$MOODLE_DIR/admin/cli/upgrade.php" --non-interactive
"$PHP_BIN" "$MOODLE_DIR/admin/cli/purge_caches.php"

echo "==> Publicando atalhos curtos de cursos..."
bash "$REPO_DIR/scripts/publicar_atalhos.sh" || echo "AVISO: atalhos com pendencias (nao bloqueia o deploy)."

echo "==> Aplicando configuracoes de site (tema e login) quando houver nova versao..."
bash "$REPO_DIR/scripts/aplicar_config_site.sh" || echo "AVISO: config de site nao aplicada/revertida (nao bloqueia o deploy)."

echo "==> Validando status do sistema..."
bash "$REPO_DIR/scripts/status_moodle.sh"

echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] Deploy concluído com sucesso!"
