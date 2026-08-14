## Qué muestra

Cuántas observaciones caen en cada intervalo de la variable. La altura de cada
barra es una frecuencia; el ancho, un tramo del recorrido.

Es el primer retrato de una variable continua y el antecedente directo de la
idea de **densidad**: si en vez de contar dividís por el total y por el ancho
del intervalo, el área total pasa a valer 1 y ya estás mirando una densidad
empírica.

## Qué buscar

- **Centro**: ¿dónde está el grueso de los datos? ¿Coincide con la media?
- **Dispersión**: ¿ancho o angosto respecto al recorrido posible?
- **Forma**: ¿simétrico o con cola a un lado? Una cola derecha larga es la
  firma de variables que no pueden ser negativas (ingresos, tiempos, conteos),
  y suele pedir una transformación logarítmica.
- **Modas**: ¿un pico o varios? Dos picos casi siempre significan que hay dos
  poblaciones mezcladas, y ese es un hallazgo, no un defecto.
- **Huecos y paredes**: un vacío en medio, o un corte abrupto en un valor
  redondo, suelen delatar cómo se recogió el dato, no cómo se comporta.

## Cuándo engaña

**El número de clases cambia la historia.** Es la trampa central de este
gráfico y por eso el control está a la vista. Con pocas barras todo parece una
campana suave; con muchas, todo parece ruido dentado. Ninguna de las dos
versiones es "la verdadera": son la misma tabla de datos leída con distinta
resolución.

Movelo. Si una moda secundaria aparece y desaparece según el número de clases,
no confíes en ella todavía — comparala con la densidad kernel, que suaviza sin
depender de dónde caen los bordes.

**El origen de los intervalos también importa.** Dos histogramas con el mismo
ancho de clase pero desplazados medio intervalo pueden verse distintos. La
densidad kernel no tiene ese problema, porque no tiene bordes.

**Con pocos datos no dice casi nada.** Por debajo de unas 30 observaciones, la
forma es principalmente azar. Ahí conviene un diagrama de puntos o el de tallo
y hojas, que no esconden ninguna observación.
