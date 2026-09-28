## Para qué sirve

Decidir cuántas componentes se quedan sin que la decisión dependa de qué regla
oíste primero. Las tres que se usan en la práctica están acá, con el número que
cada una propone y por qué.

## Qué muestra

Una fila por regla, con el `k` que sugiere y el detalle del que sale.

- **Umbral acumulado.** La primera componente con la que el acumulado pasa el
  umbral del control (80 % por costumbre). Es la más usada y la más arbitraria.
- **Kaiser.** Quedarse con las componentes de valor propio mayor que 1. El 1 es
  la varianza de una variable estandarizada: una componente que no llega a eso
  hace menos que una variable sola, así que no vale la pena cambiar de espacio
  por ella.

$$
\text{Kaiser: retener } j \text{ mientras } \lambda_j > 1
$$

- **Codo.** El vértice del quiebre, medido con la segunda diferencia de los
  valores propios: dónde cambia más la pendiente de la curva del scree.

$$
\text{codo} = \arg\max_j \left( \lambda_{j+2} - 2\lambda_{j+1} + \lambda_j \right) + 1
$$

Las tres aparecen además como líneas rotuladas sobre el gráfico de
sedimentación, para verlas en su sitio.

## Qué buscar

- **Que coincidan.** Cuando las tres dan el mismo número, la decisión está
  tomada y no hay nada que discutir. En `mtcars` estandarizado las tres dicen 2.
- **Cuánto se separan cuando no coinciden.** Una diferencia de uno es normal y
  la elección la hace el objetivo del análisis. Una diferencia de cuatro dice
  que la curva no tiene forma: no hay pocas dimensiones que resuman esto.
- **Kaiser contra el umbral.** Si Kaiser propone menos que el 80 %, hay muchas
  componentes pequeñas repartiendo varianza; si propone más, hay un bloque de
  componentes medianas y ninguna domina.
- **El codo, al final.** Es la más frágil de las tres: úsala para confirmar, no
  para decidir sola.

## Cuándo engaña

**Ninguna de las tres es un resultado.** Son heurísticas, y la discrepancia
entre ellas es información: esconderla eligiendo una regla por adelantado es
peor que verla.

**El 1 de Kaiser solo significa algo sobre R.** Si descomponiste la covarianza,
los valores propios están en las unidades de tus variables y compararlos con 1
no dice nada. Ahí el corte pasa a ser la media de los valores propios, y el
detalle de la fila lo avisa.

**En un ACM los tres números se ven pesimistas.** La inercia total de un ACM es
`J/Q − 1` y no depende de los datos, así que los porcentajes salen bajos por
construcción. Por eso Kaiser corta en `1/Q` —que resulta ser la media— y no en
1. Las correcciones de Benzécri y Greenacre atacan justamente eso, y quedan
fuera del curso.

**El codo con una caída muy abrupta señala una componente de más.** Marca la
primera componente ya plana, que es una más de las que uno retendría a ojo.
