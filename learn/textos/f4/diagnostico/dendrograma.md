## Para qué sirve

Ver la partición entera y no solo su corte. El jerárquico no produce `k`
grupos: produce un árbol con todas las particiones posibles, de `n` grupos de
uno a un solo grupo, y este gráfico es ese árbol. El corte en `k` es una
lectura que vos elegís.

## Qué muestra

Cada observación es una hoja, abajo. Cada unión horizontal es una fusión, y su
altura es la distancia entre los dos grupos que se juntaron, medida con el
enlace que elegiste. Con enlace promedio, por ejemplo:

$$
d(A, B) = \frac{1}{|A|\,|B|} \sum_{i \in A} \sum_{j \in B} d(x_i, x_j)
$$

La línea punteada horizontal es el corte: lo que queda por debajo son los `k`
grupos, cada uno de su color y dentro de su rectángulo. Lo gris, por encima,
son las fusiones que el corte decidió no hacer. El subtítulo trae la
correlación cofenética, que dice cuánto respeta el árbol las distancias
originales.

## Qué buscar

- **Una rama larga justo encima del corte.** Los grupos se juntan mucho más
  arriba de donde se formaron: el corte separa cosas que estaban lejos, y ese
  `k` tiene respaldo.
- **Ramas cortas alrededor del corte.** Subir o bajar la línea un poco cambia
  los grupos: el `k` es arbitrario.
- **Hojas que se unen al final, solas.** Con enlace promedio o simple, un
  atípico se queda aparte hasta las últimas fusiones y termina siendo un grupo
  de uno. Es un hallazgo sobre esa observación, no sobre la estructura.
- **Escalones parejos y un solo grupo enorme.** El efecto cadena del enlace
  simple: el árbol va sumando observaciones de a una y no forma grupos.

## Cuándo engaña

**El enlace decide la forma.** Ward y el completo producen grupos compactos y
de tamaño parecido; el simple encadena; el promedio queda en el medio y aparta
a los atípicos. El mismo dato da árboles distintos, y ninguno es "el" árbol.
Compará al menos dos antes de interpretar.

**Las fusiones no se deshacen.** Una observación que se juntó temprano con el
grupo equivocado queda ahí para siempre: el algoritmo no revisa. k-medias sí
reasigna, y por eso las dos particiones pueden diferir aunque `k` sea el mismo.

**La escala manda.** Sin estandarizar, la variable de rango más grande decide
todas las distancias, y con ellas todas las alturas.

**El orden horizontal de las hojas no significa nada.** Cada unión se puede
girar sin cambiar el árbol: dos hojas vecinas pueden estar lejísimos. Lo que se
lee es la altura a la que se juntan.

**Con el centroide la altura puede bajar.** Una fusión por debajo de la
anterior (una inversión) es una propiedad de ese enlace, no un error de dibujo.

**Con Gower + PAM no hay árbol.** PAM parte por medoides, de una vez, y no
deja historial de fusiones: el panel lo dice en vez de quedar en blanco. Para
ver el dendrograma de Gower, elegí la estrategia jerárquica.
