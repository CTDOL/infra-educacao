#!/usr/bin/env bash
# ==============================================================================
# deploy_ci.sh — Script de Deploy Automatizado (Forced Command via CI/CD)
# Executado na VPS pelo pipeline do GitHub Actions sob o usuário ctdolc07
# ==============================================================================
set -euo pipefail

REPO_DIR="/home/ctdolc07/infra-educacao"
cd "$REPO_DIR"

echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] Iniciando deploy do Moodle CTDOL..."

echo "==> Sincronizando com a branch main..."
git fetch origin main
git merge --ff-only origin/main

chmod +x "$REPO_DIR"/scripts/*.sh

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

echo "==> Validando status do sistema..."
bash "$REPO_DIR/scripts/status_moodle.sh"

echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] Deploy concluído com sucesso!"
