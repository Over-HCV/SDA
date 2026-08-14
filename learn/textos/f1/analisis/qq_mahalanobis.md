## Para qué sirve

Decidir si la nube entera se comporta como una normal multivariada, no solo
cada variable por separado. Cada variable puede pasar su propio Q-Q y la
conjunta fallar igual: es el chequeo que corresponde antes de cualquier método
basado en la matriz de covarianzas.

## Qué muestra

El Q-Q normal, pero para todas las variables a la vez. En lugar de un valor por
observación se usa su distancia de Mahalanobis al centro de la nube:

$$
d^2(x) = (x - \bar{x})^{\mathsf{T}}\, S^{-1}\, (x - \bar{x})
$$

La covarianza inversa es lo que la distingue de la distancia euclídea: divide
por la forma de la nube, así que una unidad cuenta más en las direcciones donde
hay poca variación.

Si los datos son normales de `p` dimensiones, esas distancias se reparten como
una χ² con `p` grados de libertad, y los puntos caen sobre la diagonal.

## Qué buscar

- **Alejamiento en la punta superior derecha**: atípicos multivariados. Son la
  razón de ser del gráfico: filas normales en cada variable por separado y
  absurdas en conjunto.
- **Curvatura global hacia arriba**: colas más pesadas que la normal
  multivariada.
- **Escalones**: variables discretas metidas en el cálculo.
- **Cuántos puntos pasan el corte** (está en el subtítulo): con el 97,5 %
  esperás un 2,5 % arriba solo por azar. Diez veces eso ya no es azar.

## Cuándo engaña

**El centro y la covarianza los fijan los propios datos, atípicos incluidos.**
Un punto muy lejano infla `S` en su dirección y termina disimulándose a sí
mismo. Es el efecto de enmascaramiento, y es el motivo de que existan MCD y las
versiones robustas.

**Sin covarianza invertible no hay distancia.** Con colinealidad exacta —una
columna que es suma de otras, o más variables que filas— `S` es singular y el
panel devuelve vacío en vez de inventar una pseudoinversa que nadie pidió.

**Atípico no es error.** Marca "raro respecto a este modelo de nube". Puede ser
un dato mal tipeado o el caso más interesante del conjunto; el gráfico no
distingue, y borrar por costumbre es la peor salida.
