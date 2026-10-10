## Para qué sirve

Elegir `k`. Es la única decisión que k-medias no toma por vos, y este gráfico
es donde se toma: cuánto baja la inercia al permitir un grupo más, y a partir
de dónde deja de valer la pena.

## Qué muestra

Para cada `k` de 2 al máximo que pediste (de 1, con factores), la inercia
intra-grupo del mejor ajuste con ese `k`:

$$
W(k) = \sum_{j=1}^{k} \sum_{i \in C_j} \lVert x_i - \mu_j \rVert^2
$$

Cada punto es un ajuste completo, con la misma semilla, el mismo optimizador y
los mismos reinicios que el ajuste que estás mirando. La línea punteada
vertical marca el `k` que elegiste.

### Con variables cualitativas

Sobre factores no hay centroide ni inercia, así que la curva mide el costo que
cada método sabe medir, desde `k = 1` (todos en un solo grupo):

- **k-modas**: el total de desacuerdos con el modo de su grupo, que es lo que
  el algoritmo minimiza. Con `k = 1` es el desacuerdo con el modo global.
- **Gower** (PAM o jerárquico): la $d$ de la partición de la sesión 5 sobre la
  matriz de Gower del ajuste,

$$
d = \sum_{k=1}^{K} \frac{1}{n_k} \sum_{i<j \in G_k} d(z_i, z_j)
$$

  que con la euclídea al cuadrado es exactamente la $W(k)$ de arriba.

Se dibuja el **costo**, igual que la inercia, y el subtítulo da la reducción
del curso: cuánto bajó respecto de `k = 1`, en porcentaje. La curva del
cuaderno (`dist_tot − Σ withinss`) es esa misma resta sin dividir, vista al
revés: sube donde esta baja.

## Qué buscar

- **El codo.** El `k` donde la curva pasa de caer en picada a caer despacio.
  Antes del codo, cada grupo nuevo separa estructura; después, parte grupos que
  ya estaban bien.
- **Que baje mucho de 2 a 3.** Un salto grande en el primer tramo dice que hay
  al menos esa cantidad de estructura.
- **Cuánta inercia queda explicada en tu `k`.** El subtítulo lo dice. Con menos
  del 50 % la partición está describiendo poco.
- **Una curva casi recta.** No hay codo porque no hay estructura de grupos: los
  datos son una nube y cualquier `k` la corta igual de arbitrariamente.

## Cuándo engaña

**La inercia siempre baja.** Con `k = n` cada punto es su propio grupo y `W`
vale cero. Que la curva descienda no es un hallazgo; el hallazgo es dónde deja
de descender rápido, y eso es un juicio, no un mínimo que se pueda calcular.

**El codo se ve donde uno quiere verlo.** Con datos reales el quiebre rara vez
es nítido, y dos personas razonables eligen `k` distinto mirando la misma
curva. Contrastalo con la silueta: son criterios distintos, y cuando coinciden
la decisión es mucho más firme.

**Cada punto es un ajuste, con su propia suerte.** Si corriste con un solo
reinicio, algún `k` pudo caer en un óptimo local y meter un escalón que no es
real. Con más reinicios la curva se alisa, y eso no es cosmética: es que el
número que estás leyendo dejó de depender del arranque.

**No mide si los grupos significan algo.** `W` baja igual partiendo estructura
real que partiendo ruido. Mirá el perfil de los grupos antes de creerles.
