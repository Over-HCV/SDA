#!/usr/bin/env bash
#
# nuevo-tema.sh — crea projects/NN-<slug>/ a partir de projects/_template/
#
# Uso (desde la raiz del proyecto SDA/):
#   ./projects/nuevo-tema.sh 02 dbscan "DBSCAN sobre charcoal" 18
#
# Argumentos:
#   $1  NN      numero de proyecto, dos digitos (02, 03, ...)
#   $2  slug    identificador corto en kebab-case (dbscan, tsne, manova)
#   $3  titulo  titulo legible, entre comillas   (opcional)
#   $4  fila    numero de fila en libs/topics-map.md (opcional)
#
# Que hace:
#   1. Copia projects/_template/ a projects/NN-slug/
#   2. Reemplaza __SLUG__ / __NN__ / __TITULO__ / __FILA__ en todos los archivos
#   3. Verifica que los .R parseen
#
# No toca renv: si tu tema necesita un paquete nuevo, instalalo y corre
# renv::snapshot() vos mismo.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "uso: $0 NN slug [\"titulo\"] [fila]" >&2
  echo "ej : $0 02 dbscan \"DBSCAN sobre charcoal\" 18" >&2
  exit 1
fi

NN="$1"
SLUG_CORTO="$2"
TITULO="${3:-TODO titulo}"
FILA="${4:-TODO}"

# Raiz del repo = directorio padre de este script.
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLANTILLA="$RAIZ/projects/_template"
SLUG="${NN}-${SLUG_CORTO}"
DESTINO="$RAIZ/projects/$SLUG"

if [[ ! -d "$PLANTILLA" ]]; then
  echo "error: no existe $PLANTILLA" >&2
  exit 1
fi

if [[ -e "$DESTINO" ]]; then
  echo "error: $DESTINO ya existe. Borralo o usa otro NN/slug." >&2
  exit 1
fi

cp -R "$PLANTILLA" "$DESTINO"
rm -f "$DESTINO"/outputs/* 2>/dev/null || true

# Sustitucion de marcadores. -i '' es la forma de BSD sed (macOS);
# en GNU sed seria -i sin argumento, por eso se detecta.
if sed --version >/dev/null 2>&1; then
  SED_INPLACE=(sed -i)
else
  SED_INPLACE=(sed -i '')
fi

while IFS= read -r -d '' archivo; do
  "${SED_INPLACE[@]}" \
    -e "s|__SLUG__|${SLUG}|g" \
    -e "s|__NN__|${NN}|g" \
    -e "s|__TITULO__|${TITULO}|g" \
    -e "s|__FILA__|${FILA}|g" \
    "$archivo"
done < <(find "$DESTINO" -type f \( -name '*.R' -o -name '*.md' \) -print0)

echo "creado: projects/$SLUG"
echo

# Verificacion: que todos los .R parseen antes de devolver el control.
echo "verificando sintaxis..."
fallo=0
for f in "$DESTINO"/R/*.R; do
  if Rscript -e "invisible(parse('$f'))" >/dev/null 2>&1; then
    echo "  ok    $(basename "$f")"
  else
    echo "  FALLA $(basename "$f")"
    fallo=1
  fi
done

if [[ $fallo -ne 0 ]]; then
  echo "error: hay archivos que no parsean" >&2
  exit 1
fi

cat <<EOF

Siguiente:
  1. Busca los TODO:
       grep -rn TODO projects/$SLUG
  2. Corre el placeholder para confirmar que el cableado funciona:
       Rscript projects/$SLUG/R/test_headless.R
  3. Reemplaza modelo.R con tu tema (fila $FILA de libs/topics-map.md).
  4. Levanta la app:
       Rscript -e 'shiny::runApp("projects/$SLUG/R/app.R", launch.browser=TRUE)'
EOF
