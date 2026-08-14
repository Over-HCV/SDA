## Para qué sirve

Ver si dos variables cualitativas están asociadas, que es lo que después
contesta con un número la prueba χ². En una tabla de contingencia grande los
conteos no se leen de un vistazo; las áreas sí.

## Qué muestra

El cruce de dos variables cualitativas. El ancho de cada columna es la
frecuencia de esa categoría de la primera variable; el alto de cada bloque, la
proporción de la segunda **dentro** de esa columna. El área de un bloque es su
frecuencia conjunta.

El color no es la frecuencia: es el **residuo estandarizado**, cuánto se aparta
esa celda de lo que se esperaría si las dos variables fueran independientes.

$$
\begin{aligned}
\text{esperado}(i,j) &= \frac{\text{fila}(i) \cdot \text{columna}(j)}{n} \\[4pt]
\text{residuo}(i,j) &= \frac{\text{observado} - \text{esperado}}{\sqrt{\text{varianza del esperado}}}
\end{aligned}
$$

Azul es más de lo esperado, rojo es menos, gris es lo esperado.

## Qué buscar

- **Bloques de color fuerte**: ahí está la asociación. Un residuo por encima de
  2 en valor absoluto ya destaca.
- **Filas de bloques desalineadas**: si los cortes horizontales de cada columna
  están a distinta altura, la distribución de la segunda variable cambia según
  la primera. Eso es asociación.
- **Cortes alineados en todas las columnas**: independencia.
- **El p del subtítulo**, más la V de Cramér: la prueba dice si hay señal, la V
  dice si es grande (0 sin relación, 1 relación perfecta).

## Cuándo engaña

**Un bloque grande no prueba nada por sí solo.** Puede serlo simplemente porque
su fila y su columna son grandes. Lo que se lee es el color, no el tamaño: esa
es toda la razón de que el residuo esté en la paleta.

**Con celdas casi vacías la prueba se debilita.** Si algún esperado queda por
debajo de 5, la aproximación ji-cuadrado deja de ser confiable y el panel lo
avisa. Ahí conviene agrupar categorías o usar una prueba exacta.

**Con muchas categorías es ilegible.** Por encima de unas seis por lado, pasá a
la tabla de contingencia con residuos: los números se leen y los bloques de dos
milímetros no.
