## Para qué sirve

Comprobar la propiedad que hace útil al ACP más allá del dibujo: las
componentes no comparten información. Es la única vista del diagnóstico que no
juzga el ajuste contra un umbral, sino contra un hecho.

## Qué muestra

La matriz de correlaciones entre las componentes retenidas, con el mismo mapa de
calor que usás en ① Datos para las variables originales. Tiene que ser la
identidad: unos en la diagonal, ceros en todo lo demás.

$$
\operatorname{Cor}(Z_i, Z_j) = 0 \quad \text{para todo } i \neq j
$$

No es un resultado empírico, es una consecuencia de la construcción: los
vectores propios de una matriz simétrica son ortogonales entre sí, y proyectar
sobre direcciones ortogonales da puntuaciones no correlacionadas.

## Qué buscar

- **Que sea la identidad.** Si lo es, el ajuste está bien y podés usar las
  puntuaciones como variables nuevas sin pensarlo.
- **El contraste con el mapa de calor de tus datos.** Ahí había bloques rojos y
  azules; acá no hay nada fuera de la diagonal. Esa es la operación completa del
  ACP vista en dos imágenes: entraron variables redundantes, salieron variables
  independientes.
- **Algo fuera de la diagonal.** No es una interpretación distinta, es un error:
  el ajuste no convergió o la matriz que se descompuso no era la que creías.

## Cuándo engaña

**No correlacionadas no es independientes.** La correlación mide relación
lineal. Dos componentes pueden tener correlación exactamente cero y estar
ligadas por una relación curva; si los datos originales no eran normales
multivariados, eso pasa de verdad.

**Cero correlación no es cero información compartida.** Las componentes no se
solapan linealmente, y eso es lo que arregla la colinealidad de una regresión.
No garantiza que cada componente signifique algo por separado.

**Que la diagonal esté perfecta no dice que `k` sea el correcto.** Esta vista es
cierta con una componente y con todas. Cuántas quedarse lo contestan el scree y
las reglas de al lado.
