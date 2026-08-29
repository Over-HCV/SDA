## Para qué sirve

Juzgar la partición observación por observación, que es lo que la inercia no
puede decir. Contesta la pregunta incómoda: *¿cada punto está donde debería?*

## Qué muestra

Una barra por observación, agrupadas por grupo y ordenadas de mayor a menor
dentro de cada uno. La altura es la silueta:

$$
s(i) = \frac{b(i) - a(i)}{\max\{a(i),\, b(i)\}}
$$

donde $a(i)$ es la distancia media de la observación $i$ a las demás de su
propio grupo, y $b(i)$ la distancia media al grupo vecino más cercano. La línea
punteada es la silueta media de todo el ajuste.

Vale entre −1 y 1: cerca de 1 la observación está cómoda donde está, cerca de 0
está en la frontera, y por debajo de 0 estaría mejor en el grupo vecino.

## Qué buscar

- **Barras negativas.** Son observaciones mal ubicadas. Unas pocas son
  normales; muchas dicen que `k` no es el que corresponde.
- **Un grupo entero por debajo de la media.** Ese grupo no está separado de sus
  vecinos: probablemente sea un pedazo arbitrario de una nube más grande.
- **Grupos de anchos muy distintos.** El ancho de cada bloque es su tamaño. Un
  grupo diminuto con silueta alta puede ser una estructura real pequeña, o un
  puñado de atípicos que k-medias apartó.
- **La silueta media.** Por encima de 0.5 la estructura es clara; entre 0.25 y
  0.5 es débil pero existe; por debajo de 0.25 casi no hay estructura que la
  partición esté capturando.

## Cuándo engaña

**Mide separación, no verdad.** Una silueta alta dice que los grupos están
lejos entre sí en la métrica que usaste. Si esa métrica es la equivocada
—porque no escalaste, o porque las variables relevantes no entraron—, la
silueta alta confirma una partición irrelevante.

**Depende de la escala.** Se calcula sobre la misma matriz que se agrupó. Si
ajustaste sin estandarizar, la variable de rango más grande domina también acá.

**Castiga a los grupos alargados.** Un grupo real con forma de cigarro tiene
distancias internas grandes y sale con silueta baja aunque esté perfectamente
separado. La silueta premia lo esférico, igual que k-medias.

**Con muchas filas se calcula sobre una muestra.** La silueta necesita todas
las distancias entre pares, y eso crece con el cuadrado de `n`. Cuando el
subtítulo dice que hubo muestreo, el número es una estimación y conviene no
citarlo con tres decimales.
