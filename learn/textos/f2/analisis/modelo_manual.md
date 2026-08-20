## Para qué sirve

Ser vos el optimizador. Movés el eje a mano, ves el error subir y bajar, y
descubrís por experiencia lo que la fase 3 va a hacer iterando. Después, cuando
la máquina lo haga sola, ya sabés qué está buscando.

## Qué muestra

La nube de dos variables con un eje encima, el que vos elegiste con el ángulo.
Cada segmento gris va de un punto a su pie sobre el eje: es lo que se pierde al
proyectar ese punto. La suma de esos segmentos al cuadrado es el **error de
reconstrucción**.

El subtítulo trae los dos números a la vez: qué proporción de varianza capta el
eje y cuánta se queda fuera.

## Qué buscar

- **Girá el eje y mirá los dos números moverse en sentidos opuestos.** Cuando la
  varianza captada sube, el error baja, y viceversa. Siempre. Esa es la lección
  central del ACP: maximizar varianza y minimizar error de reconstrucción son
  la misma cosa, porque el teorema de Pitágoras reparte la distancia total
  entre proyección y residuo.
- **Buscá el mínimo a mano.** Cuando los segmentos grises están lo más cortos
  posible en conjunto, encontraste la primera componente. Comparalo con el
  máximo de la curva del panel de al lado: es el mismo ángulo.
- **Los segmentos largos.** Son las observaciones peor representadas por este
  eje. Si unas pocas tienen segmentos enormes, mirá si son atípicos antes de
  seguir.
- **La dirección con los segmentos más largos.** Es la última componente: lo que
  el resumen tira a la basura.

## Cuándo engaña

**Los segmentos no son distancias verticales.** Son perpendiculares al eje, no
paralelas al eje Y. Esa es la diferencia entre el ACP y una regresión: la
regresión minimiza el error en `y` dado `x`, el ACP minimiza la distancia al
subespacio. Por eso la recta del ACP y la recta de regresión no coinciden.

**El dibujo usa la escala de los datos crudos.** Si una variable va de 0 a 1 y
la otra de 0 a 1000, el eje se ve pegado a la segunda. No es un defecto del
gráfico: es el motivo por el que existe la decisión entre R y S.

**Encontrar el mínimo a ojo con dos variables es fácil; con quince, imposible.**
Ahí está el valor del optimizador, y por eso este panel es un puente y no un
sustituto.
