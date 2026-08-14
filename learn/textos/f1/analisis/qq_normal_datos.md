## Para qué sirve

Comprobar la normalidad de una variable con más resolución que un histograma,
sobre todo en las colas. Es donde se distingue si el problema son unos pocos
valores extremos o la forma completa, y esa diferencia decide si alcanza con
recortar o hay que cambiar de método.

## Qué muestra

Los cuantiles observados de la variable contra los que tendría si fuera normal.
Cada punto es una observación: en el eje horizontal, el valor que le tocaría
bajo una normal; en el vertical, el que de verdad tiene.

Si la variable es normal, los puntos caen sobre la recta de referencia, que
pasa por el primer y el tercer cuartil. Los desvíos se leen por su forma, no
por su tamaño.

## Qué buscar

- **S acostada**: asimetría. Si los puntos se despegan hacia arriba en la
  derecha, hay cola derecha larga.
- **Extremos que se van hacia afuera en los dos lados**: colas pesadas, más
  masa lejos del centro de la que una normal admite.
- **Extremos que se aplanan**: colas livianas, distribución más corta que la
  normal.
- **Escalones horizontales**: la variable está discretizada o redondeada.
- **Uno o dos puntos muy lejos de la recta al final**: atípicos, no forma.

## Cuándo engaña

**La prueba y el gráfico se contradicen a propósito, y el gráfico tiene razón
más veces.** Con n grande, Shapiro-Wilk rechaza la normalidad por desvíos
minúsculos que no afectan a ningún método; con n chico, no rechaza nada porque
no tiene potencia. El subtítulo trae la prueba y el p, pero la decisión se toma
mirando la nube.

**Casi ningún método pide que los DATOS sean normales.** La regresión pide
normalidad de los *residuos*, no de las variables. Este Q-Q sirve para conocer
la forma de la variable y decidir una transformación, no para aprobar o
reprobar un modelo que todavía no existe.

**Con n < 20 la nube es tan errática que casi nada se puede concluir.** Se
espera ver zigzag; no lo leas como estructura.
