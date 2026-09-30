#!/usr/bin/env bash
# Biblioteca comum dos scripts CTDOL/Moodle (apenas "source", nao executar).
# Todos os valores podem ser sobrescritos via variavel de ambiente.

PHP_BIN="${PHP_BIN:-/usr/local/bin/ea-php83}"
MOODLE_DIR="${MOODLE_DIR:-/home/ctdolc07/edu.ctdol.com.br}"
MOODLEDATA_DIR="${MOODLEDATA_DIR:-/home/ctdolc07/moodledata}"
MOODLE_URL="${MOODLE_URL:-https://edu.ctdol.com.br/}"
KEYCLOAK_REALM_URL="${KEYCLOAK_REALM_URL:-https://sso.ctdol.com.br/realms/moodle}"
BACKUP_DIR="${BACKUP_DIR:-/home/ctdolc07/backups/moodle}"
LOG_DIR="${LOG_DIR:-/home/ctdolc07/logs}"
DB_NAME_DEFAULT="ctdolc07_moodle"

C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_RST=$'\033[0m'
[ -t 1 ] || { C_RED=""; C_GRN=""; C_YEL=""; C_RST=""; }

ok()   { echo "${C_GRN}[ OK ]${C_RST} $*"; }
warn() { echo "${C_YEL}[WARN]${C_RST} $*"; WARNINGS=$(( ${WARNINGS:-0} + 1 )); }
fail() { echo "${C_RED}[FAIL]${C_RST} $*"; FAILURES=$(( ${FAILURES:-0} + 1 )); }
info() { echo "[ .. ] $*"; }
die()  { echo "${C_RED}[ERRO]${C_RST} $*" >&2; exit 1; }

require_moodle() {
  [ -x "$PHP_BIN" ] || die "PHP nao encontrado em $PHP_BIN (rode na VPS)."
  [ -f "$MOODLE_DIR/config.php" ] || die "config.php ausente em $MOODLE_DIR."
}

# Le credenciais do banco a partir do config.php real (sem hardcode/expor senha).
# Define: DB_HOST DB_NAME DB_USER DB_PASS DB_PREFIX
load_db_config() {
  local out
  out=$("$PHP_BIN" -r '
    define("CLI_SCRIPT", true); define("ABORT_AFTER_CONFIG", true);
    require $argv[1];
    echo implode("\n", [$CFG->dbhost, $CFG->dbname, $CFG->dbuser, $CFG->dbpass, $CFG->prefix]);
  ' "$MOODLE_DIR/config.php" 2>/dev/null) || die "Falha ao ler config.php via PHP."
  { IFS= read -r DB_HOST; IFS= read -r DB_NAME; IFS= read -r DB_USER; IFS= read -r DB_PASS; IFS= read -r DB_PREFIX; } <<<"$out"
  DB_NAME="${DB_NAME:-$DB_NAME_DEFAULT}"
  # Arquivo de credenciais temporario (evita senha na linha de comando/ps).
  DB_CNF="$(mktemp)"; chmod 600 "$DB_CNF"
  printf '[client]\nhost=%s\nuser=%s\npassword=%s\n' "$DB_HOST" "$DB_USER" "$DB_PASS" >"$DB_CNF"
  trap 'rm -f "$DB_CNF"' EXIT
}
