#!/usr/bin/env bash
# ==============================================================================
# aplicar_config_site.sh — Aplica config/site-settings.conf no Moodle (tema e login)
#
# - Aplica uma vez por SETTINGS_VERSION (estado em ~/.ctdol_site_settings_version);
#   --force reaplica.
# - Verifica o resultado pela pagina publica e REVERTE sozinho se falhar:
#     tema  : o CSS do tema precisa carregar (200) e conter a cor primaria;
#     login : o botao "Entrar com Conta CTDOL" precisa continuar na tela.
# - Nao altera 'auth' nem o plugin auth_oauth2 (Keycloak).
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHP_BIN="${PHP_BIN:-/usr/local/bin/ea-php83}"
MOODLE_DIR="${MOODLE_DIR:-/home/ctdolc07/edu.ctdol.com.br}"
SITE_URL="${SITE_URL:-https://edu.ctdol.com.br}"
SETTINGS_FILE="${SETTINGS_FILE:-$REPO_DIR/config/site-settings.conf}"
STATE_FILE="${STATE_FILE:-$HOME/.ctdol_site_settings_version}"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

cfg_get() { "$PHP_BIN" "$MOODLE_DIR/admin/cli/cfg.php" --name="$1" 2>/dev/null || true; }
cfg_set() { "$PHP_BIN" "$MOODLE_DIR/admin/cli/cfg.php" --name="$1" --set="$2" >/dev/null; }
purge()   { "$PHP_BIN" "$MOODLE_DIR/admin/cli/purge_caches.php" >/dev/null; }

[ -f "$SETTINGS_FILE" ] || { echo "ERRO: $SETTINGS_FILE inexistente." >&2; exit 1; }
# Leitura restrita (sem 'source'): apenas as tres chaves esperadas.
SETTINGS_VERSION=""; THEME=""; SHOW_LOGIN_FORM=""
while IFS='=' read -r chave valor; do
  case "$chave" in
    SETTINGS_VERSION) SETTINGS_VERSION="$valor" ;;
    THEME)            THEME="$valor" ;;
    SHOW_LOGIN_FORM)  SHOW_LOGIN_FORM="$valor" ;;
  esac
done < <(grep -E '^(SETTINGS_VERSION|THEME|SHOW_LOGIN_FORM)=' "$SETTINGS_FILE")

[[ "$SETTINGS_VERSION" =~ ^[0-9]+$ ]]        || { echo "ERRO: SETTINGS_VERSION invalida." >&2; exit 1; }
[[ "$THEME" =~ ^[a-z0-9_]+$ ]]               || { echo "ERRO: THEME invalido." >&2; exit 1; }
[[ "$SHOW_LOGIN_FORM" =~ ^[01]$ ]]           || { echo "ERRO: SHOW_LOGIN_FORM deve ser 0 ou 1." >&2; exit 1; }
[ -d "$MOODLE_DIR/theme/$THEME" ]            || { echo "ERRO: tema '$THEME' nao instalado em $MOODLE_DIR/theme." >&2; exit 1; }

APLICADA=0; [ -f "$STATE_FILE" ] && APLICADA="$(cat "$STATE_FILE")"
if [ "$FORCE" -eq 0 ] && [ "$APLICADA" -ge "$SETTINGS_VERSION" ] 2>/dev/null; then
  echo "Config de site ja aplicada (versao $APLICADA); nada a fazer."
  exit 0
fi
echo "Aplicando config de site versao $SETTINGS_VERSION (aplicada: $APLICADA)..."

# ---- Tema -------------------------------------------------------------------
tema_anterior="$(cfg_get theme)"
if [ "$tema_anterior" != "$THEME" ]; then
  cfg_set theme "$THEME"; purge
  css_url="$(curl -fsS -m 30 "$SITE_URL/login/index.php" | grep -o "https\?://[^\"']*theme/styles.php/$THEME/[^\"']*" | head -1 | sed 's/&amp;/\&/g')" || css_url=""
  if [ -n "$css_url" ] && curl -fsS -m 60 "$css_url" 2>/dev/null | grep -qi '0b2545'; then
    echo "OK: tema '$THEME' ativo e CSS carregando."
  else
    echo "FALHA: CSS do tema '$THEME' nao carregou; revertendo para '${tema_anterior:-boost}'." >&2
    cfg_set theme "${tema_anterior:-boost}"; purge
    exit 1
  fi
else
  echo "OK: tema '$THEME' ja estava ativo."
fi

# ---- Formulario de login manual ---------------------------------------------
form_anterior="$(cfg_get showloginform)"; form_anterior="${form_anterior:-1}"
if [ "$form_anterior" != "$SHOW_LOGIN_FORM" ]; then
  cfg_set showloginform "$SHOW_LOGIN_FORM"; purge
  pagina="$(curl -fsS -m 30 "$SITE_URL/login/index.php")" || pagina=""
  ok=1
  grep -q 'Entrar com Conta CTDOL' <<<"$pagina" || ok=0            # botao SSO precisa continuar
  # O formulario de visitante (guestlogin) tem <input hidden name="username" value="guest">; por isso
# o teste usa o campo visivel id="username" do formulario de login manual.
  if [ "$SHOW_LOGIN_FORM" = "0" ]; then grep -q 'id="username"' <<<"$pagina" && ok=0; fi
  if [ "$ok" -eq 1 ]; then
    echo "OK: showloginform=$SHOW_LOGIN_FORM e botao SSO presente."
  else
    echo "FALHA: verificacao do login; revertendo showloginform=$form_anterior." >&2
    cfg_set showloginform "$form_anterior"; purge
    exit 1
  fi
else
  echo "OK: showloginform=$SHOW_LOGIN_FORM ja estava aplicado."
fi

echo "$SETTINGS_VERSION" > "$STATE_FILE"
echo "Config de site versao $SETTINGS_VERSION aplicada."
