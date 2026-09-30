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

echo "==> Validando status do sistema..."
bash "$REPO_DIR/scripts/status_moodle.sh"

echo "==> [$(date +'%Y-%m-%d %H:%M:%S')] Deploy concluído com sucesso!"
