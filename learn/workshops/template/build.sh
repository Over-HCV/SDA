#!/usr/bin/env bash
# build.sh — pipeline de talleres AED: .qmd -> .tex (editable) -> .pdf (plantilla UR)
#
# Uso:
#   ../template/build.sh                    render (si falta) + pdf, en esta carpeta
#   ../template/build.sh render             solo genera <nombre>.tex desde el .qmd
#   ../template/build.sh pdf                solo compila el .tex (latexmk/xelatex)
#   ../template/build.sh render --force     regenera aunque exista (¡pisa ediciones manuales!)
#   template/build.sh all taller-02         desde workshops/: la carpeta del taller
#   template/build.sh all taller-02/x.qmd   un archivo concreto (si hay varios)
#
# El cuaderno se busca en la carpeta del taller: si solo hay un .Rmd (lo que
# entrega SDA Lab cuando no se marca la plantilla) se copia a .qmd, porque
# quarto únicamente dibuja los diagramas mermaid desde .qmd. Con más de un
# candidato no se adivina: se listan y se pide elegir.
#
# El .tex generado queda en la raíz del taller y es editable a mano: pdf no lo
# toca, así que podés pulir texto LaTeX y recompilar sin perder cambios.

set -euo pipefail

STAGE="all"
DESTINO=""
FORCE=0
for a in "$@"; do
  case "$a" in
    all|render|pdf) STAGE="$a" ;;
    --force)        FORCE=1 ;;
    -*)             echo "✗ opción desconocida: $a"; exit 1 ;;
    *)              DESTINO="$a" ;;
  esac
done

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export R_LIBS_USER="$TEMPLATE_DIR/../../../renv/library/macos/R-4.6/aarch64-apple-darwin23"
export CHROMIUM_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# \input, gráficos (ur-logo, mitthesis.cls, common/) y bibliografía viven en template/
export TEXINPUTS=".:$TEMPLATE_DIR:$TEMPLATE_DIR/common:$TEMPLATE_DIR/fontsets:"
export BIBINPUTS="$TEMPLATE_DIR:$TEMPLATE_DIR/bib:"
export BSTINPUTS="$BIBINPUTS"

# --- Dónde trabajar y con qué cuaderno ---------------------------------------
QMD=""
if [ -n "$DESTINO" ] && [ -f "$DESTINO" ]; then
  cd "$(dirname "$DESTINO")"
  QMD="$(basename "$DESTINO")"
elif [ -n "$DESTINO" ]; then
  [ -d "$DESTINO" ] || { echo "✗ no existe: $DESTINO"; exit 1; }
  cd "$DESTINO"
fi

# Se excluyen los scratch *-qmd.qmd que deja quarto al renderizar un .Rmd con
# el mismo stem.
buscar() { ls -1 *."$1" 2>/dev/null | grep -v -- '-qmd\.qmd$' || true; }

if [ -z "$QMD" ]; then
  CANDIDATOS="$(buscar qmd)"
  if [ -z "$CANDIDATOS" ]; then
    RMD="$(buscar Rmd)"
    [ -n "$RMD" ] || { echo "✗ No hay ningún .qmd ni .Rmd en $(pwd)"; exit 1; }
    [ "$(echo "$RMD" | wc -l)" -eq 1 ] || {
      echo "✗ Hay varios .Rmd; elegí uno:"; echo "$RMD" | sed 's/^/    /'; exit 1; }
    QMD="${RMD%.Rmd}.qmd"
    cp "$RMD" "$QMD"
    echo "→ $RMD copiado a $QMD (quarto solo dibuja mermaid desde .qmd)"
  else
    [ "$(echo "$CANDIDATOS" | wc -l)" -eq 1 ] || {
      echo "✗ Hay varios .qmd en $(pwd); pasá cuál:"
      echo "$CANDIDATOS" | sed 's/^/    /'; exit 1; }
    QMD="$CANDIDATOS"
  fi
fi

NAME="${QMD%.qmd}"
TEX="$NAME.tex"
PDF="build/$NAME.pdf"

render() {
  if [ -f "$TEX" ] && [ "$FORCE" -ne 1 ]; then
    echo "→ $TEX ya existe (ediciones manuales preservadas); usar --force para regenerar"
    return
  fi
  echo "→ quarto render $QMD --to latex"
  quarto render "$QMD" --to latex
  # quarto puede desambiguar el nombre (<stem>-qmd.tex si coexiste un .Rmd):
  # se renombra al nombre canónico del taller.
  GENERATED="$(ls -t "$NAME"*.tex 2>/dev/null | head -1 || true)"
  if [ -n "$GENERATED" ] && [ "$GENERATED" != "$TEX" ]; then
    mv -f "$GENERATED" "$TEX"
  fi
  echo "✓ generado $TEX (editable) — figuras en ${NAME}_files/"
}

pdf() {
  [ -f "$TEX" ] || { echo "✗ falta $TEX (corré primero: ../template/build.sh render)"; exit 1; }
  mkdir -p build
  echo "→ latexmk -pdfxe $TEX"
  latexmk -pdfxe -interaction=nonstopmode -outdir=build "$TEX"
  echo "✓ $PDF"
}

case "$STAGE" in
  render) render ;;
  pdf)    pdf ;;
  all)    [ -f "$TEX" ] || render; pdf ;;
esac
