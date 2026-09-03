## Para qué sirve

Quedarse con las filas que responden la pregunta. "Los registros recolectados
a mediodía" son las filas con `Hora = "12:00"`; el resto existe, pero no
pertenece a la pregunta, y mezclarlo cambia medias, cajas y correlaciones.

El filtro no destruye nada: los datos crudos siguen guardados aparte y la pila
guarda la receta, no el resultado. Deshacer la última entrada revive las filas
exactas que había antes.

## Qué muestra

Tres números: cuántas filas había al cargar, cuántas quedan ahora y cuántas
quedaron fuera. Debajo, la pila completa en orden — filtros y transformaciones
conviven, porque la pila se reaplica siempre desde los datos crudos y el orden
en que se añadieron es el orden en que se ejecutan.

## Qué buscar

- **Que "filas ahora" sea el número que la pregunta espera.** Para el Taller 01
  con `Hora = "12:00"` deben quedar 118 filas de 4543: si sale otro número, el
  filtro quedó mal armado y todo lo que sigue hereda el error.
- **Filtros que dejan columnas de grupo vacías.** Un municipio que no reporta
  a mediodía desaparece del dataset filtrado: sus cajas y sus puntos también.
- **Filas con NA en la columna filtrada.** Quedan fuera del filtro y el panel
  lo avisa: "no pasó el filtro" y "faltaba el dato" son cosas distintas.
