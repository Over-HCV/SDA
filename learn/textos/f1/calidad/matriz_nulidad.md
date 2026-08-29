## Para qué sirve

Decidir cómo tratar los faltantes, que es una de las decisiones que más cambia
los resultados. Borrar filas, imputar o modelar la ausencia son caminos
distintos que llevan a números distintos, el dibujo de esta card es lo que
dice cuál corresponde.

## Qué muestra

Una celda por cada par (fila, columna) del dataset: pintada si el valor falta,
gris si existe. Lo relevante no son las celdas sueltas, sino el **dibujo** que
forman.

De ahí se definen los tres mecanismos de ausencia:

- **MCAR** — Falta al azar, sin relación con nada. Como si fuera sal y pimienta
  repartida parejamente.
- **MAR** — La ausencia depende de otras variables observadas. Se ven bandas
  que coinciden con grupos de filas.
- **MNAR** — La ausencia depende del propio valor que falta. (Acá no se ve) Debe razonarse desde cómo se recogieron los datos.

## Qué buscar

- **Bandas horizontales**: filas que fallan en varias columnas a la vez. Suelen
  ser registros incompletos de origen.
- **Columnas casi enteras pintadas**: variables que se empezaron a medir tarde,
  o variables/preguntas opcionales.
- **Faltantes que coinciden entre dos columnas**: se recogieron juntas y
  faltaron juntas. Imputarlas por separado inventa combinaciones imposibles.
- **El pie del gráfico**: cuántas filas quedan completas. Ese número es el n
  real de cualquier método que no tolere faltantes.

## Cuándo engaña

**Solo se dibujan las primeras filas.** Con datasets grandes se muestra un
tramo, así que un patrón que aparezca al final del archivo podría no verse acá.
La tabla por columna sí está calculada sobre el total.

**El orden de las filas es el del archivo.** Si ya vino ordenado por fecha o
país, las bandas pueden ser artefacto de ese orden y no de un mecanismo.

**No distingue `faltante` de "cero" ni de `no aplica`.** Si el archivo trae
`-99` o una cadena vacía y nadie las declaró como faltantes, esta matriz las ve
como datos presentes y perfectos.
