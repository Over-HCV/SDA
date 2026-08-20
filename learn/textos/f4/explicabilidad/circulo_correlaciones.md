## Para qué sirve

Ver de un vistazo qué variables están bien representadas en el plano que estás
mirando, cuáles dicen lo mismo entre sí, y cuáles son independientes. Es el
resumen visual de la interpretación.

## Qué muestra

Cada variable es una flecha desde el origen. Sus coordenadas son las
correlaciones con las dos componentes:

```
r(xᵢ, CPⱼ) = vᵢⱼ · √λⱼ
```

Sobre la matriz de correlación esas coordenadas están acotadas por 1, así que
todas las flechas caben dentro del círculo unidad. El círculo dibujado es ese
límite.

## Qué buscar

- **Longitud de la flecha.** Es qué tan bien representada está la variable en
  este plano. Una flecha que casi toca el círculo está bien explicada por estas
  dos componentes; una corta vive en las componentes que no estás mirando.
- **Ángulo entre dos flechas.** Es la correlación entre esas variables,
  aproximadamente: juntas significa que dicen lo mismo, opuestas que dicen lo
  contrario, en ángulo recto que son independientes.
- **Flechas apuntando al mismo lado que un eje.** Esas son las que le dan
  nombre a la componente.
- **Grupos de flechas.** Un ramillete apretado es un bloque de variables
  redundantes: candidatas a quedarse con una sola.

## Cuándo engaña

**El ángulo solo aproxima la correlación si las dos flechas son largas.** Con
flechas cortas el ángulo es casi ruido: la proyección tiró casi toda la
información de esas variables y lo que queda no representa su relación real.

**Solo se ven dos componentes.** Dos variables pueden verse pegadas en el plano
CP1–CP2 y estar lejos en CP3. Cambiá los ejes antes de concluir.

**Sobre S el círculo no aplica.** Si descomponiste la covarianza en vez de la
correlación, las coordenadas no están acotadas por 1 y el círculo unidad no
significa nada. El gráfico lo dice en el subtítulo en vez de dibujar un marco
que engaña.

**La correlación es lineal.** Dos variables con una relación fuerte pero curva
aparecen en ángulo recto, como si fueran independientes. Esa es la limitación
del ACP entero, no de este dibujo.
