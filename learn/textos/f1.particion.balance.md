## Qué muestra

La distribución de una columna dentro de cada parte de la partición. Es la
comprobación de la estratificación: si se pidió estratificar, las barras de
entrenamiento y prueba deberían tener casi la misma altura por clase.

## Qué buscar

- **Proporciones parecidas entre partes**: es lo que la estratificación
  promete. Si no se estratificó, mirá igual: el azar puede haber dejado un
  desbalance grande sin avisar.
- **Clases que desaparecen de una parte**: fatal. Un clasificador que nunca vio
  una clase no la puede predecir, y una métrica calculada sin ella no significa
  nada.
- **Diferencias en las clases raras**: es donde el azar pega más fuerte. Con 12
  casos de una clase repartidos al azar, 9 y 3 es un resultado perfectamente
  probable.

## Cuándo engaña

**Estratificar por una columna no equilibra las demás.** Las partes quedan
comparables en la variable elegida y pueden ser muy distintas en todas las
otras. Es una garantía puntual, no general.

**Con muchas clases chicas la estratificación se queda sin margen.** No hay
manera de repartir tres observaciones en cinco pliegues conservando la
proporción; el algoritmo hace lo que puede y no falla.

**Que las proporciones coincidan no vuelve válida la partición.** Si las filas
no son independientes —series de tiempo, medidas repetidas del mismo sujeto—,
un balance perfecto convive con una evaluación inflada.
