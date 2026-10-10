#!/usr/bin/env bash
# projects/final/figuras.sh
#
# Responsabilidad: producir TODAS las figuras de la presentación con el lab
# (learn/R/lab.R), una línea por figura. Ninguna se dibuja a mano: cada PNG es
# el mismo ggplot que muestra la app para ese artefacto, guardado con
# `panel <clave> ... --salida archivo.png`.
#
# Uso, desde la raíz del repo:   bash projects/final/figuras.sh
#
# Todas sobre Zoo con `tipo` como clase de referencia (nunca entra al ajuste)
# y k = 7 salvo donde se dice. Los tamaños están pensados para una diapositiva
# 16:9: 8 x 4.5 in a pantalla completa, 6 x 4.5 en media columna.

set -euo pipefail

if [[ ! -f learn/R/lab.R ]]; then
  echo "corré esto desde la raíz del repo: bash projects/final/figuras.sh" >&2
  exit 1
fi

SALIDA=projects/final/figuras
mkdir -p "$SALIDA"

ZOO="--fuente zoo --clase tipo"
K7="--hiper k=7"
ANCHA="--ancho 8 --alto 4.5 --dpi 200"
MEDIA="--ancho 6 --alto 4.5 --dpi 200"
ARBOL="--ancho 10 --alto 5.5 --dpi 200"
GOWER_JER="--metodo gower --hiper estrategia=jerarquico"
TANDEM="--reduccion acm --hiper n_componentes=5 --hiper escalar=FALSE"

lab() { Rscript learn/R/lab.R "$@"; }

# --- Parte 1: los datos ------------------------------------------------------
# Frecuencias de la clase real (la que se guarda para el anexo).
lab panel f1.balanceo.frecuencias tipo $ZOO \
  --salida "$SALIDA/zoo-frecuencias.png" $MEDIA
# Pelo x leche: la asociación de la diapositiva ("vienen de la misma fuente").
lab panel f1.analisis.mosaico pelo leche $ZOO \
  --salida "$SALIDA/zoo-asociacion.png" $ANCHA
# Primer plano del ACM, coloreado por la clase real (diagnóstico, no ajuste).
lab panel f4.explicabilidad.mapa_2d --metodo acm --color tipo $ZOO \
  --salida "$SALIDA/zoo-acm-mapa.png" $ANCHA

# --- Parte 2: k-modas --------------------------------------------------------
lab panel f3.analisis.convergencia --metodo kmodos $K7 $ZOO \
  --salida "$SALIDA/kmodos-traza.png" $ANCHA
lab panel f4.explicabilidad.modos --metodo kmodos $K7 $ZOO \
  --salida "$SALIDA/kmodos-modos.png" --ancho 8 --alto 5.5 --dpi 200
# El codo cualitativo: costo (desacuerdos con el modo) para k = 1..10.
lab panel f4.diagnostico.codo --metodo kmodos $K7 --k_max 10 $ZOO \
  --salida "$SALIDA/kmodos-codo.png" $MEDIA
# La inicialización: k-modas con Huang contra k-modas con arranque aleatorio.
lab panel f4.desempeno.cruce_clase --metodo kmodos --inicializacion Huang $K7 \
  --comparar kmodos --inicializacion_comparar aleatoria $ZOO \
  --salida "$SALIDA/kmodos-estabilidad.png" $MEDIA

# --- Parte 3: jerárquico sobre Gower -----------------------------------------
lab panel f4.diagnostico.dendrograma $GOWER_JER --hiper enlace=complete $K7 $ZOO \
  --salida "$SALIDA/gower-dendrograma-completo.png" $ARBOL
lab panel f4.diagnostico.dendrograma $GOWER_JER --hiper enlace=average $K7 $ZOO \
  --salida "$SALIDA/gower-dendrograma.png" $ARBOL
lab panel f4.diagnostico.dendrograma $GOWER_JER --hiper enlace=single $K7 $ZOO \
  --salida "$SALIDA/gower-dendrograma-simple.png" $ARBOL
# Concordancia: el table(K_means, Jerarquico) de la sesión 5, con su ARI.
lab panel f4.desempeno.cruce_clase --metodo kmodos $K7 \
  --comparar gower --hiper estrategia=jerarquico --hiper enlace=average $ZOO \
  --salida "$SALIDA/concordancia.png" $ANCHA

# --- Parte 4: clases latentes, tándem y anexo --------------------------------
# k = 4: el que elige el BIC (la diapositiva lo dice), así la línea punteada
# del k elegido cae sobre el mínimo.
lab panel f4.diagnostico.bic --metodo clases_latentes --hiper k=4 $ZOO \
  --salida "$SALIDA/lca-bic.png" $ANCHA
lab panel f4.explicabilidad.mapa_2d --metodo clases_latentes --hiper k=4 $ZOO \
  --salida "$SALIDA/lca-mapa.png" $ANCHA
lab panel f4.explicabilidad.mapa_2d --metodo kmeans $TANDEM $K7 $ZOO \
  --salida "$SALIDA/tandem-mapa.png" $MEDIA
# El mejor ARI de la tabla del anexo: Gower jerárquico promedio contra tipo.
lab panel f4.desempeno.cruce_clase $GOWER_JER --hiper enlace=average $K7 $ZOO \
  --salida "$SALIDA/validacion-ari.png" $MEDIA

# distancias-ejemplo.png: el lab no tiene todavía un panel de disimilitudes
# entre filas, así que no se produce (la diapositiva muestra su recuadro).

echo "figuras en $SALIDA:"
ls -1 "$SALIDA"
