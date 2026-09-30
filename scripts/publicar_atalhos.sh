#!/usr/bin/env bash
# ==============================================================================
# publicar_atalhos.sh — Atalhos curtos de cursos: edu.ctdol.com.br/<shortname>
# Para cada courses/<shortname>/course.json com "shortlink": true cria
# $MOODLE_DIR/<shortname>/index.php que redireciona (302) para
# /course/info.php?name=<shortname> (pagina publica com previa Open Graph).
#
# Idempotente e conservador:
#  - nunca sobrescreve pasta existente que nao tenha o marcador CTDOL-SHORTLINK;
#  - nunca usa nomes reservados do Moodle;
#  - remove apenas atalhos proprios (com marcador) cujo curso deixou de pedir shortlink;
#  - nao edita .htaccess nem configuracao do Apache.
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHP_BIN="${PHP_BIN:-/usr/local/bin/ea-php83}"
MOODLE_DIR="${MOODLE_DIR:-/home/ctdolc07/edu.ctdol.com.br}"
MARCADOR="CTDOL-SHORTLINK"
# Nomes de pastas/rotas do Moodle (e afins) que nunca podem virar atalho.
RESERVADOS=" admin analytics auth availability backup badges blocks blog cache calendar cohort comment communication competency completion contentbank course customfield enrol error files filter grade group h5p help install lang lib local login media message mnet mod my notes payment pix plagiarism portfolio privacy question rating report reportbuilder repository rss search tag theme user webservice cgi-bin "
CONFLITOS=0

[ -d "$MOODLE_DIR" ] || { echo "ERRO: MOODLE_DIR inexistente: $MOODLE_DIR" >&2; exit 1; }

# shortnames com "shortlink": true
SLUGS=()
while IFS= read -r linha; do
  [ -n "$linha" ] && SLUGS+=("$linha")
done < <("$PHP_BIN" -r '
  foreach (glob($argv[1] . "/courses/*/course.json") ?: [] as $f) {
      $m = json_decode(file_get_contents($f));
      if ($m && !empty($m->shortlink) && !empty($m->shortname)) { echo $m->shortname, "\n"; }
  }' "$REPO_DIR")

conteudo() {
  cat <<'PHP'
<?php
// CTDOL-SHORTLINK — gerado por scripts/publicar_atalhos.sh (nao editar).
header('Location: /course/info.php?name=' . rawurlencode(basename(__DIR__)), true, 302);
exit;
PHP
}

for slug in ${SLUGS[@]+"${SLUGS[@]}"}; do
  if ! [[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "AVISO: shortname invalido para atalho: $slug"; CONFLITOS=$((CONFLITOS + 1)); continue
  fi
  if [[ "$RESERVADOS" == *" $slug "* ]]; then
    echo "AVISO: '$slug' e nome reservado do Moodle; atalho nao criado."; CONFLITOS=$((CONFLITOS + 1)); continue
  fi
  destino="$MOODLE_DIR/$slug"
  if [ -e "$destino" ] && ! { [ -d "$destino" ] && grep -q "$MARCADOR" "$destino/index.php" 2>/dev/null; }; then
    echo "AVISO: '$destino' ja existe e nao e um atalho CTDOL; nao alterado."; CONFLITOS=$((CONFLITOS + 1)); continue
  fi
  mkdir -p "$destino"; chmod 755 "$destino"
  tmp="$(mktemp "$destino/.index.XXXXXX")"
  conteudo > "$tmp"
  chmod 644 "$tmp"
  mv -f "$tmp" "$destino/index.php"
  echo "OK: https://edu.ctdol.com.br/$slug/ -> /course/info.php?name=$slug"
done

# Remove atalhos proprios (com marcador) que nao sao mais pedidos.
for idx in "$MOODLE_DIR"/*/index.php; do
  [ -f "$idx" ] || continue
  grep -q "$MARCADOR" "$idx" || continue
  pasta="$(dirname "$idx")"; nome="$(basename "$pasta")"
  if [[ " ${SLUGS[*]-} " != *" $nome "* ]]; then
    rm -f "$idx" && rmdir "$pasta" 2>/dev/null && echo "REMOVIDO: atalho obsoleto /$nome/" || true
  fi
done

[ "$CONFLITOS" -eq 0 ] || { echo "Concluido com $CONFLITOS aviso(s)."; exit 1; }
echo "Atalhos em dia."
