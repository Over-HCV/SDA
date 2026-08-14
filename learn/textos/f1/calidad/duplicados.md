## Para qué sirve

Saber si las filas repetidas son un error de carga o una característica del
dato, antes de tocar nada. La misma repetición puede ser un cruce mal hecho o
un panel con varias observaciones por unidad, y la diferencia cambia el
análisis entero.

## Qué muestra

Qué filas se repiten y cuántas veces aparece cada combinación. Se puede mirar
la fila entera o solo un subconjunto de columnas —lo segundo es lo que sirve
para detectar claves repetidas.

## Qué buscar

- **Duplicados exactos de la fila completa**: casi siempre un error de unión o
  de exportación. Rara vez son datos legítimos.
- **Repeticiones de la clave pero no del resto**: dos registros del mismo sujeto
  con valores distintos. Ahí hay que decidir cuál vale, no borrar el segundo.
- **Un puñado de combinaciones con conteo altísimo**: suele ser un valor por
  defecto que se grabó muchas veces (ceros, "sin dato", la primera opción del
  formulario).
- **Duplicados concentrados en un tramo**: apunta a una carga repetida.

## Cuándo engaña

**En datos agregados repetirse es lo normal.** Si cada fila es una transacción,
que dos sean idénticas no dice nada. Este panel solo tiene sentido cuando la
fila representa una unidad que debería ser única.

**La comparación es literal.** `"Bogotá"` y `"bogota "` son filas distintas para
el conteo aunque sean el mismo lugar. Los duplicados por diferencia de mayúsculas,
tildes o espacios no aparecen acá; eso se arregla normalizando el texto antes.

**Nada se borra solo.** El panel marca; la eliminación es una acción explícita y
queda registrada en las transformaciones del dataset, que es como después se
puede reconstruir qué pasó.
