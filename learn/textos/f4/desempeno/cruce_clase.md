## Para qué sirve

Medir la partición contra una clase que se conoce pero que el método NO vio.
Es validación externa: la única forma de saber si los grupos encontrados se
parecen a una clasificación que ya tiene sentido (en Zoo, `tipo`).

## Qué muestra

Una fila por grupo y una columna por clase real. El número es cuántas
observaciones de esa clase cayeron en ese grupo; el color, qué proporción del
grupo son. En el subtítulo van dos resúmenes:

- **ARI** (índice de Rand ajustado, Hubert y Arabie): cuenta los pares de
  observaciones que las dos particiones dejan juntos o separados, corregido
  por el acuerdo que se esperaría al azar con los mismos tamaños,

$$
\mathrm{ARI} = \frac{\sum_{ij}\binom{n_{ij}}{2} - E}
{\tfrac12\left[\sum_i\binom{a_i}{2} + \sum_j\binom{b_j}{2}\right] - E},
\qquad
E = \frac{\sum_i\binom{a_i}{2}\,\sum_j\binom{b_j}{2}}{\binom{n}{2}}
$$

  Vale 1 si las dos particiones coinciden, 0 si el acuerdo es el del azar, y
  puede ser negativo.
- **Pureza**: la fracción de observaciones que caen en la clase mayoritaria de
  su grupo.

La clase de referencia se declara con rol `respuesta` en el Diccionario (o con
`--clase` en la consola). Nunca entra al ajuste: se adjunta después.

### Dos métodos entre sí

La "clase" puede ser la partición de otro método: es la tabla
`table(K_means, Jerarquico)` de la sesión 5, y el ARI pasa a medir
**concordancia** en vez de acierto. Por consola:

    Rscript learn/R/lab.R panel f4.desempeno.cruce_clase --metodo kmodos \
      --comparar gower --hiper estrategia=jerarquico --hiper k=7 \
      --fuente zoo --clase tipo

Con `--comparar kmodos --semilla_comparar 456` (o
`--inicializacion_comparar aleatoria`) es la prueba de estabilidad: el mismo
método con otro arranque. Las filas son el método de `--metodo`; las columnas,
el de `--comparar`.

## Qué buscar

- **Filas concentradas.** La numeración de los grupos es arbitraria, así que no
  se busca una diagonal: se busca que cada fila tenga casi todo en una columna.
- **Una clase repartida en varias filas.** El método la parte en subgrupos:
  puede ser un `k` grande o una clase heterogénea de verdad (los
  invertebrados de Zoo no se parecen entre sí).
- **Dos clases en una misma fila.** El método no las distingue con estas
  variables: reptiles y anfibios comparten casi todos los atributos.
- **ARI contra pureza.** Si la pureza es alta y el ARI bajo, probablemente hay
  muchos grupos chicos y puros: la pureza sube sola al subir `k`, el ARI no.

## Cuándo engaña

**La clase real no es la única partición válida.** Un ARI bajo puede ser un
método que encontró otra estructura, igual de real, que no es la taxonomía. Un
murciélago agrupado con las aves por volar no es un error del método.

**Con clases muy desbalanceadas el ARI se mueve poco.** En Zoo los mamíferos
son el 40 %: acertarlos pesa mucho más que acertar los cuatro anfibios.

**Si la clase entró al ajuste, el número no vale nada.** Agrupar con `tipo`
entre las variables y después medir contra `tipo` es hacer trampa con la
respuesta. Al adjuntar la referencia se emite un aviso si esa columna está
entre las del ajuste.
