## Para qué sirve

Decidir si la transformación se queda o se descarta, mirando lo que hizo en
vez de suponerlo. Una transformación que no mejora la forma solo agrega un
paso que después hay que deshacer para poder interpretar el resultado.

## Qué muestra

La misma variable dos veces: como venía y como quedó después de aplicar la pila
de transformaciones. Dos histogramas lado a lado, cada uno con su propia
escala.

El subtítulo trae la asimetría (g₁) antes y después, que es el número que
resume qué hizo la transformación:

$$
\begin{aligned}
g_1 &> 0 && \text{cola a la derecha} \\
g_1 &\approx 0 && \text{simétrica} \\
g_1 &< 0 && \text{cola a la izquierda}
\end{aligned}
$$

## Qué buscar

- **La cola**: si entró con cola derecha larga y salió simétrica, el log o la
  raíz hicieron su trabajo.
- **g₁ antes contra g₁ después**: es la medida objetiva de ese cambio.
- **Modas que se separan**: comprimir la cola a veces revela dos grupos que
  estaban aplastados contra el eje.
- **Acumulación en un extremo**: si después de transformar quedó un pico contra
  el borde, la transformación fue demasiado fuerte.

## Cuándo engaña

**Los ejes no son comparables y eso es a propósito.** Cada panel usa su propia
escala porque después de un log las unidades cambiaron. Se compara la FORMA, no
la posición ni el ancho.

**Transformar cambia lo que significan los resultados.** Una media de logaritmos
no es el logaritmo de la media; un coeficiente sobre la variable transformada se
interpreta en porcentaje, no en unidades. Eso viaja hasta la fase 4 y nadie lo
recuerda si no queda anotado.

**Con valores no positivos hay un desplazamiento previo.** El log y la raíz no
existen en cero o negativo, así que la columna se corre sumando el mínimo más
uno, y el panel lo avisa. Ese desplazamiento es una decisión, no un detalle:
cambia la interpretación de todo lo que venga después.

**Simetría no es normalidad.** Una distribución puede quedar simétrica y seguir
teniendo colas pesadas. El Q-Q es quien contesta eso.
