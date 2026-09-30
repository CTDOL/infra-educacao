#!/usr/bin/env bash
# Purge de todos os caches do Moodle via CLI (PHP 8.3 do cPanel).
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"
require_moodle
info "purgando caches..."
"$PHP_BIN" "$MOODLE_DIR/admin/cli/purge_caches.php" && ok "caches purgados" || die "purge falhou"
