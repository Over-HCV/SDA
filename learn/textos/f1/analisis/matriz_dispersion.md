## Qué muestra

Todas las parejas de variables numéricas a la vez, en una rejilla. La celda de
la fila `i` y la columna `j` es la dispersión de la variable `i` contra la `j`.
La diagonal cruza cada variable consigo misma, así que es una recta perfecta y
solo sirve de referencia.

Es el primer vistazo a p > 2: en un solo golpe se ve qué pares tienen
estructura y cuáles no.

## Qué buscar

- **Qué celdas tienen forma**: nubes alargadas, curvas, grupos separados.
- **Simetría de la rejilla**: la celda (i, j) es la (j, i) reflejada. Si una te
  parece más legible que su espejo, es solo el eje.
- **Columnas enteras sin estructura**: esa variable no se relaciona con nada de
  lo que hay en el panel.
- **Bloques de celdas parecidas**: variables que miden lo mismo. Es el aviso
  temprano de redundancia que el ACP después va a explotar.
- **No linealidades**: una U o una curva en una celda invalida leer esa relación
  con un solo coeficiente.

## Cuándo engaña

**No escala.** Con 6 variables son 36 celdas y ya cuesta; con 15 son 225 y no se
ve nada. Por eso el panel corta en unas pocas variables: para más, el mapa de
calor de correlaciones resume mejor, a costa de perder la forma.

**Cada celda es un gráfico chiquito con las trampas de un gráfico grande.** El
sobreploteo, la escala y los atípicos siguen ahí, con menos píxeles para
delatarse. Lo que se detecta acá se confirma abriendo ese par en la pestaña
bivariada.

**La escala libre por faceta exagera lo plano.** Cada celda usa su propio
recorrido, así que una relación débil puede parecer nítida solo porque el eje
se ajustó a ella.
