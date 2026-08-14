## Qué muestra

Cada observación es una línea que atraviesa todos los ejes; cada eje es una
variable. Donde la dispersión muestra dos variables, esto muestra todas —a
costa de que las relaciones haya que leerlas entre ejes vecinos.

El eje vertical no está en las unidades originales: las variables se normalizan
antes, porque si no, la de mayor recorrido aplasta a las demás y el gráfico
queda plano. El subtítulo dice qué normalización se usó.

## Qué buscar

- **Haces de líneas paralelas entre dos ejes**: relación positiva entre esas dos
  variables.
- **Cruces en forma de X entre dos ejes**: relación negativa.
- **Grupos de líneas que viajan juntas todo el recorrido**: subpoblaciones. Con
  el color por grupo se confirma en un vistazo.
- **Líneas que se despegan del haz en un solo eje**: atípicos univariados.
- **Líneas que nunca están en el extremo pero siempre por fuera del haz**:
  atípicos multivariados, los que solo Mahalanobis detecta.

## Cuándo engaña

**El orden de los ejes decide qué se ve.** Solo se leen las relaciones entre
ejes ADYACENTES; un par que quedó en las puntas opuestas es invisible. Reordenar
los ejes es parte de usar el gráfico, no un capricho.

**Normalizar oculta las magnitudes.** Dos variables que ocupan el mismo alto
pueden ir de 0 a 1 y de 0 a un millón. Sirve para comparar forma, no tamaño.
Con min-máx, además, un solo valor extremo comprime todo el resto contra el
piso.

**Con muchas filas se convierte en un bloque de tinta.** La transparencia ayuda;
por encima de unos pocos miles conviene mirar una muestra —el badge te dice si
ya estás mirando una.
