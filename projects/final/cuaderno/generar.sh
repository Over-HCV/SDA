#!/bin/sh
# Regenera los chunks del cuaderno del proyecto desde SDA Lab.
# Correr desde la raíz del repositorio (donde vive .Rprofile):
#   sh projects/final/cuaderno/generar.sh
# Escribe generado.Rmd; clustering-cualitativo.Rmd es la versión
# reescrita a mano con esos mismos chunks, en el mismo orden.
PANELES="f1.fuente.vista_previa,f1.balanceo.frecuencias:tipo,\
f1.analisis.mosaico:leche+tipo,\
f4.diagnostico.scree:metodo=acm,f4.explicabilidad.mapa_2d:metodo=acm,\
f3.analisis.convergencia:metodo=kmodos,f3.analisis.trayectoria:metodo=kmodos,\
f3.consola.estado:metodo=kmodos,f4.explicabilidad.mapa_2d:metodo=kmodos,\
f4.diagnostico.codo:metodo=kmodos,f4.diagnostico.silueta:metodo=kmodos,\
f4.desempeno.grupos:metodo=kmodos,f4.explicabilidad.modos:metodo=kmodos,\
f4.desempeno.cruce_clase:metodo=kmodos,\
f4.diagnostico.dendrograma:metodo=gower+estrategia=jerarquico,\
f4.diagnostico.silueta:metodo=gower+estrategia=jerarquico,\
f4.desempeno.cruce_clase:metodo=gower+estrategia=jerarquico,\
f3.analisis.convergencia:metodo=clases_latentes,\
f4.diagnostico.bic:metodo=clases_latentes,\
f4.explicabilidad.modos:metodo=clases_latentes,\
f4.desempeno.cruce_clase:metodo=clases_latentes,\
f4.explicabilidad.mapa_2d:metodo=kmeans,f4.desempeno.cruce_clase:metodo=kmeans"
Rscript learn/R/lab.R cuaderno "$PANELES" \
  --fuente zoo --clase tipo \
  --reduccion acm --hiper n_componentes=5 \
  --hiper k=7 --hiper escalar=FALSE \
  --excluir plantilla_taller \
  --salida projects/final/cuaderno/generado.Rmd
