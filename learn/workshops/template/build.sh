#!/usr/bin/env bash
# build.sh — pipeline de talleres AED: .qmd -> .tex (editable) -> .pdf (plantilla UR)
#
# Uso, desde la carpeta del taller (learn/workshops/taller-XX):
#   ../template/build.sh              render (si falta) + pdf
#   ../template/build.sh render       solo genera <nombre>.tex desde el .qmd
#   ../template/build.sh pdf          solo compila el .tex existente (latexmk/xelatex)
#   ../template/build.sh render --force   regenera aunque exista (¡pisa ediciones manuales!)
#
# El .tex generado queda en la raíz del taller y es editable a mano: pdf no lo
# toca, así que podés pulir texto LaTeX y recompilar sin perder cambios.

set -euo pipefail

STAGE="${1:-all}"
shift || true
FORCE=0
for a in "$@"; do [ "$a" = "--force" ] && FORCE=1; done

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export R_LIBS_USER="$TEMPLATE_DIR/../../../renv/library/macos/R-4.6/aarch64-apple-darwin23"
export CHROMIUM_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# \input, gráficos (ur-logo, mitthesis.cls, common/) y bibliografía viven en template/
export TEXINPUTS=".:$TEMPLATE_DIR:$TEMPLATE_DIR/common:$TEMPLATE_DIR/fontsets:"
export BIBINPUTS="$TEMPLATE_DIR:$TEMPLATE_DIR/bib:"
export BSTINPUTS="$BIBINPUTS"

# El qmd del taller: se excluyen los scratch *-qmd.qmd que deja quarto al
# renderizar un .Rmd con el mismo stem.
QMD="$(ls -1 *.qmd 2>/dev/null | grep -v -- '-qmd\.qmd$' | head -1 || true)"
[ -n "$QMD" ] || { echo "✗ No hay ningún .qmd en $(pwd)"; exit 1; }
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
  *) echo "uso: $0 [all|render|pdf] [--force]  (desde la carpeta del taller)"; exit 1 ;;
esac
