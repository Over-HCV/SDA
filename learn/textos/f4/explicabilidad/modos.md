## Para qué sirve

Contestar qué es cada grupo cuando las variables son categorías. Con factores
no hay centroide que promediar, pero sí la frecuencia de cada categoría dentro
del grupo, y la más frecuente (el **modo**) es el representante natural del
grupo: es lo que k-modos usa en lugar de la media.

## Qué muestra

Una columna por grupo y una fila por categoría, agrupadas por variable. Cada
celda es la proporción del grupo que cae en esa categoría:

$$
\hat{\pi}_{g}(v = c) = \frac{\#\{i \in g : x_{iv} = c\}}{n_g}
$$

así que dentro de cada grupo las celdas de una misma variable suman 100. El
recuadro marca el modo del grupo en esa variable. Con clases latentes las
celdas no son frecuencias observadas sino las probabilidades que estimó el
modelo, que son su resultado.

## Qué buscar

- **Filas que cambian de grupo a grupo.** Una variable cuyo modo es distinto
  entre grupos es la que los separa. `leche = si` en un solo grupo dice que ese
  grupo son los mamíferos sin que el algoritmo haya visto la clase.
- **Filas iguales en todos los grupos.** Si `domestico = no` es el modo de
  todos, la variable no distingue a nadie aunque su celda sea oscura. Un grupo
  se describe por dónde se aparta de la muestra.
- **Modos débiles.** Un recuadro sobre 55 % es un empate casi perfecto: el
  representante del grupo en esa variable es poco más que una moneda.
- **Grupos que comparten todos los modos.** Dos columnas idénticas son un
  grupo partido en dos: probablemente sobra un `k`.

## Cuándo engaña

**El modo esconde la mezcla.** Un grupo con 51 % de `vuela = si` y otro con
100 % tienen el mismo modo y son grupos muy distintos. Por eso se pinta la
proporción y no solo el recuadro.

**Las categorías raras no ganan nunca.** Una categoría con pocas
observaciones (seis patas, cinco patas) casi nunca es modo de nada, aunque sea
justo la que define a un grupo pequeño. Mirá el color de la fila, no solo los
recuadros.

**Describe, no explica.** Que el grupo 1 sea `pelo = si, leche = si` es una
descripción de la partición, no una prueba de que la partición sea la
correcta. La validación contra la clase real está en Desempeño.
