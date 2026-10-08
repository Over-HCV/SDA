## Para qué sirve

Juzgar el árbol antes de juzgar sus grupos. Un dendrograma resume las
`n(n−1)/2` distancias entre pares en apenas `n − 1` alturas, y algo se pierde
en el camino. Este gráfico dice cuánto.

## Qué muestra

Un punto por par de observaciones. En el eje horizontal, la distancia original
entre ellas; en el vertical, la **distancia cofenética**: la altura a la que el
árbol las junta por primera vez. El subtítulo trae la correlación entre las
dos columnas, calculada sobre todos los pares:

$$
r_c = \operatorname{cor}\big(d(x_i, x_j),\; h(i, j)\big)
$$

## Qué buscar

- **Una correlación alta.** Por encima de 0.8 el árbol representa bien las
  distancias; por debajo de 0.7 conviene desconfiar de lo que dibuja.
- **Escalones horizontales.** Muchos pares a distancias distintas comparten la
  misma altura: es la fusión que los juntó. Escalones anchos arriba son normales
  —ahí se juntan grupos enteros—; escalones anchos abajo dicen que el árbol
  junta temprano cosas que estaban lejos.
- **Comparar enlaces.** El enlace promedio suele dar la cofenética más alta,
  porque es justamente un promedio de distancias. Ward suele dar menos y grupos
  más útiles: la correlación no es el único criterio.

## Cuándo engaña

**Mide fidelidad, no grupos.** Una cofenética alta dice que el árbol respeta
las distancias, no que los datos tengan grupos: un árbol fiel a una nube sin
estructura sigue siendo una nube sin estructura.

**Un atípico la infla.** Una observación muy lejana aporta `n − 1` pares con
distancia grande y altura grande, y esos pares solos empujan la correlación
hacia arriba. Mirá si la nube de abajo, sin ellos, también sube en línea.

**Con muchas filas se dibuja una muestra.** La correlación es siempre la de
todos los pares; cuando el subtítulo dice que se dibuja una parte, es solo el
gráfico el que está muestreado.
