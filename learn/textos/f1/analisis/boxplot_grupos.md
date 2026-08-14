## Para qué sirve

Decidir si vale la pena correr una prueba de diferencia de medias antes de
correrla. Si las cajas se solapan casi por completo, el ANOVA rara vez va a
encontrar algo; si están claramente separadas, ya sabés el resultado y la
prueba solo le pone un número.

## Qué muestra

La misma variable numérica partida por un factor: una caja por grupo, en el
mismo eje. Es la versión visual de la pregunta que después contesta el ANOVA —
*¿las medias de estos grupos son distintas, o lo que veo cabe dentro del ruido?*

Con el violín activado, cada caja lleva detrás la forma de su densidad. La caja
dice dónde está el centro y cuánto se dispersa; el violín dice si esa
dispersión es una campana, una meseta o dos picos.

## Qué buscar

- **Separación entre cajas contra el largo de cada una**: si los desplazamientos
  entre grupos son chicos comparados con la altura de las cajas, ninguna prueba
  va a encontrar gran cosa. Ese cociente es, en esencia, el estadístico F.
- **Cajas de alturas muy distintas**: es heterocedasticidad, y es justo el
  supuesto que el ANOVA clásico pide y que Welch relaja.
- **Grupos con pocos datos**: una caja construida con cinco observaciones se
  ve igual de sólida que una de quinientas. El n va aparte, en la tabla.
- **Orden**: si el factor es ordinal, ¿hay tendencia monótona o solo diferencias
  sueltas?

## Cuándo engaña

**El gráfico no dice cuántos hay en cada grupo.** Dos cajas del mismo tamaño
pueden venir de n = 8 y n = 800. La comparación visual sugiere una precisión
que no existe; la tabla de al lado tiene el n de cada grupo.

**Comparar muchos grupos invita a la pesca.** Con diez cajas, alguna va a
parecer distinta por azar. Esa es exactamente la razón de las comparaciones
múltiples corregidas (Tukey) en la fase 4.

**Grupos desbalanceados desequilibran la lectura.** La caja del grupo grande es
estable y la del chico se mueve con cada observación; las dos se dibujan igual.
