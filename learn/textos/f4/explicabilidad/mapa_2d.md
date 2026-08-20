## Para qué sirve

Ver la nube de datos. Con más de tres variables no se puede dibujar nada; el
ACP da el mejor plano posible para mirarla, y esto es ese plano.

## Qué muestra

Cada punto es una observación en sus coordenadas sobre dos componentes: sus
puntuaciones. Las líneas en cero son el centro de la nube, porque las
puntuaciones están centradas por construcción.

Si elegiste una columna con rol de grupo, el color la usa. El color no
participó del ajuste: el ACP no sabía que existía.

## Qué buscar

- **Separación por color.** Si los grupos se separan, las variables que
  entraron al ACP contienen información sobre esa clasificación. Y como el
  método no vio las etiquetas, es un hallazgo de verdad, no una circularidad.
- **Grupos que no se separan.** También informa: significa que la mayor
  variabilidad de estos datos no tiene que ver con esa columna. Probá otras
  componentes antes de descartarlo.
- **Forma de la nube.** Redonda es lo esperable en el plano de las dos primeras
  componentes. Un arco o una herradura es una firma clásica de estructura no
  lineal, y ahí el ACP se está quedando corto.
- **Puntos aislados.** Atípicos multivariados: lejos del centro en el plano
  aunque quizá normales en cada variable por separado.
- **Rachas o escalones.** Si los puntos se agrupan en franjas, suele haber una
  variable discreta dominando la componente.

## Cuándo engaña

**Es una sombra.** Estás mirando una proyección: dos puntos pegados en el plano
pueden estar lejísimos en las dimensiones que no se dibujan. Cuánto confiar en
este dibujo lo dice el scree: si CP1 y CP2 acumulan 90 %, mucho; si acumulan
35 %, poco.

**Las escalas de los dos ejes no son comparables.** CP1 tiene por construcción
más varianza que CP2, así que la nube se ve más ancha que alta. Eso es
información, no distorsión — pero no leas "está más disperso a la derecha".

**Ver grupos no es que haya grupos.** El ojo humano agrupa nubes aleatorias sin
esfuerzo. Si te importa la separación, medila: para eso está el agrupamiento de
la sesión 5, con sus índices.

**La herradura no siempre es estructura.** El efecto arco aparece también por
razones puramente algebraicas cuando hay un gradiente fuerte. Es un patrón
conocido, no un descubrimiento.
