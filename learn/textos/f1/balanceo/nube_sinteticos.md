## Para qué sirve

Ver qué se fabricó al rebalancear, para no confundirlo con datos. Es la card
que evita el error más caro del remuestreo: creer que ahora hay más
información que antes, cuando lo único que hay son más filas.

## Qué muestra

La nube de dos variables después de rebalancear, con las filas remuestreadas
marcadas con otro símbolo. Es la prueba visual de qué se hizo: los puntos con
cruz son copias de puntos que ya estaban, no observaciones nuevas.

## Qué buscar

- **Dónde caen las cruces**: exactamente encima de puntos originales. Eso es lo
  que significa sobre-muestrear.
- **Cuántas hay** (está en el subtítulo): la proporción de filas repetidas dice
  cuánto se estiró la clase minoritaria.
- **Zonas vacías que siguen vacías**: repetir no cubre regiones donde nunca
  hubo datos. La frontera entre clases sigue estimada con la misma información
  de antes.
- **Con sub-muestreo, qué desapareció**: comparalo con la nube original; los
  huecos son datos reales que se tiraron.

## Cuándo engaña

**Repetir puntos parece agregar evidencia y no agrega ninguna.** Al modelo le
llega una clase con más peso, y a cualquier validación que no separe copias del
original le llega la misma fila a los dos lados: el desempeño sale inflado y no
hay métrica que lo delate.

**El gráfico ve dos dimensiones y el remuestreo pasó en todas.** Dos puntos
pueden verse encimados acá y ser distintos en las otras variables.

**Un método basado en distancias sufre con las copias.** Puntos idénticos tienen
distancia cero entre sí, y eso distorsiona k-NN, k-medias y todo lo que dependa
de vecindades.
