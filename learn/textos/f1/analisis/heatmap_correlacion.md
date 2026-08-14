## Para qué sirve

Encontrar de un vistazo qué variables sobran por redundantes y decidir si hace
falta reducir dimensión. Es el paso previo natural al ACP: si acá no aparecen
bloques de color, el ACP no va a tener mucho que comprimir.

## Qué muestra

La matriz de correlaciones `R` pintada: una celda por par de variables, color
según el coeficiente. Azul es correlación positiva, rojo negativa, gris cerca
de cero. La diagonal vale 1 siempre y no informa nada.

Con el reordenamiento activo, las variables se agrupan por parecido en vez de
por orden alfabético, y entonces los **bloques** saltan a la vista.

## Qué buscar

- **Bloques azules fuera de la diagonal**: grupos de variables que miden casi lo
  mismo. Es redundancia, y es exactamente lo que el ACP va a comprimir.
- **Variables sin ninguna celda intensa**: aportan información propia; son
  candidatas a quedarse tal cual.
- **Pares con `|r|` por encima de 0,9**: colinealidad casi exacta. En regresión
  múltiple eso infla los errores estándar y da coeficientes con signo absurdo.
- **Cambios de signo dentro de un bloque**: una variable invertida respecto a
  sus compañeras (un "menor es mejor" mezclado con "mayor es mejor").

## Cuándo engaña

**Resume cada relación en un número y pierde la forma.** Dos celdas con r = 0,3
pueden venir de una nube difusa o de una curva clarísima con una parte
descendente. La matriz de dispersión conserva la forma; este mapa la cambia por
capacidad de escala.

**Pearson solo ve rectas.** Si sospechás relaciones monótonas pero curvas,
cambiá el método a Spearman: los bloques pueden reorganizarse por completo.

**El orden reordenado no es una jerarquía.** El agrupamiento sirve para leer,
no para concluir. Cambiar la distancia o el método de enlace cambia el orden
sin cambiar un solo dato.

**Los faltantes se manejan par a par.** Cada celda puede estar calculada con un
subconjunto distinto de filas, así que dos celdas de la misma matriz no siempre
hablan de la misma gente.
