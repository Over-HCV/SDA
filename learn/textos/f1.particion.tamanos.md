## Qué muestra

Cuántas filas quedaron en cada parte: entrenamiento y prueba en un holdout, o
los k pliegues en validación cruzada. La barra es proporcional y trae el conteo
y el porcentaje adentro.

Partir no copia los datos: lo que se guarda es un vector que dice a qué parte va
cada fila, más la semilla. Con esos dos elementos la partición se reproduce
exactamente en otra máquina, o desde `Rscript` sin abrir la app.

## Qué buscar

- **El tamaño de la parte de prueba**: es el que determina la precisión de la
  evaluación final. Con 20 filas de prueba, cualquier métrica tiene una barra de
  error enorme y ninguna comparación entre modelos significa nada.
- **Pliegues del mismo tamaño**: en k-fold deberían ser casi iguales; una
  diferencia grande apunta a un k mal elegido para el n disponible.
- **La semilla**: está registrada. Sin ella no hay reproducibilidad.

## Cuándo engaña

**Un reparto correcto no garantiza partes comparables.** Los tamaños pueden ser
perfectos y la distribución de la variable de interés, muy distinta entre
partes. Eso lo contesta el panel de balance por partición, no este.

**Partir al azar supone que las filas son intercambiables.** Con series de
tiempo no lo son: entrenar con el futuro y evaluar con el pasado infla el
resultado y es un error que ninguna métrica delata. Ahí se parte por tiempo.

**Con datos agrupados —varias filas por sujeto— el azar rompe el grupo.** Filas
del mismo sujeto a los dos lados hacen que la prueba deje de ser independiente,
y la evaluación sale demasiado buena.

**Más entrenamiento no siempre es mejor.** Subir a 90/10 da un modelo apenas
mejor y una evaluación mucho peor. Es un canje, no una optimización.
