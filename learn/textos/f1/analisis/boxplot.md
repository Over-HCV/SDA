## Qué muestra

El resumen de cinco números: mínimo dentro de la cerca, primer cuartil,
mediana, tercer cuartil y máximo dentro de la cerca. La caja va de Q1 a Q3, así
que encierra el 50 % central de los datos, y la línea de adentro es la mediana.

Los bigotes llegan hasta la observación más lejana que todavía cae dentro de
1,5 veces el rango intercuartílico:

```
cerca inferior = Q1 − 1.5·RIC        cerca superior = Q3 + 1.5·RIC
```

Lo que queda afuera se dibuja punto por punto. Son los **atípicos de Tukey**, y
son una convención, no un diagnóstico.

## Qué buscar

- **Posición de la mediana dentro de la caja**: si está pegada a un borde, la
  distribución es asimétrica.
- **Largo relativo de los bigotes**: el más largo apunta hacia la cola.
- **Cuántos puntos quedan afuera** y qué tan lejos. Uno muy separado del resto
  vale más atención que quince apenas pasada la cerca.
- **Ancho de la caja**: es el RIC, la medida de dispersión que no se deja
  arrastrar por los extremos.

## Cuándo engaña

**Esconde las modas.** Una distribución con dos picos y otra con uno solo
pueden dar cajas idénticas. El boxplot resume posiciones, no forma. Por eso
está al lado del histograma y no en su lugar.

**"Atípico" acá significa "pasó de 1,5·RIC", nada más.** En una variable con
cola derecha larga —ingresos, tiempos de espera— es normal que haya decenas de
puntos afuera y ninguno es un error. Marcarlos no es motivo para borrarlos.

**Con n chico los cuartiles son inestables.** Por debajo de unas 20
observaciones, agregá los puntos encima de la caja: es más honesto mostrar el
dato que su resumen.
