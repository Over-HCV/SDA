## Para qué sirve

Ver la forma de una variable sin la arbitrariedad del número de clases. Es la
que conviene para juzgar si una transformación hizo falta y si funcionó,
porque el cambio de forma se lee sin depender de dónde cayeron los bordes.

## Qué muestra

Una curva suave que estima la densidad de probabilidad de la variable. En vez
de contar por intervalos, pone una campanita —el **núcleo**— sobre cada
observación y las suma todas.

El parámetro que manda es el ancho de banda `h`, no el número de clases:

$$
\hat{f}(x) = \frac{1}{n h} \sum_{i=1}^{n} K\!\left( \frac{x - x_i}{h} \right)
$$

El área bajo la curva vale 1, así que la altura no es una cuenta de casos: es
densidad. Comparar dos densidades de muestras de tamaño distinto es legítimo;
comparar dos histogramas de conteos, no.

## Qué buscar

- **Modas**: los picos son la razón de ser de este gráfico. Dos modas separadas
  y estables al mover `h` son dos poblaciones mezcladas.
- **Asimetría**: la cola más larga dice hacia dónde se estira la variable.
- **Colas**: qué tan rápido cae la curva en los extremos, comparado con la
  campana que uno esperaría si fuera normal.
- **El valor de h**: aparece en el subtítulo. Por defecto sale de la regla de
  Silverman, `h = 0.9 · min(s, RIC/1.34) · n^(−1/5)`, que es un punto de
  partida razonable y nada más.

## Cuándo engaña

**h chico inventa modas; h grande las borra.** Es el mismo dilema del número de
clases del histograma, con otro nombre: sesgo contra varianza. Movelo y fijate
cuáles picos sobreviven. Los que aparecen y desaparecen no son estructura, son
ruido suavizado con distinta fuerza.

**Suaviza más allá del recorrido real.** El núcleo gaussiano tiene colas
infinitas, así que la curva pone densidad en valores imposibles: edades
negativas, porcentajes por encima de 100. Si la variable está acotada, la parte
que se derrama por el borde es un artefacto del método.

**Con pocos datos es casi solo el núcleo.** Con n = 10 estás mirando la forma
de la campanita que elegiste, no la de la variable.
