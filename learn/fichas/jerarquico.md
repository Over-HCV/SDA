## Qué es

Un agrupamiento que no elige `k` de entrada. Arranca con cada observación
sola y, en cada paso, **fusiona los dos grupos más cercanos**. Después de
`n − 1` fusiones queda uno solo, y el historial completo es un árbol: el
**dendrograma**. Cortarlo a cierta altura da `k` grupos.

Lo único que hay que decidir es qué quiere decir "los dos grupos más cercanos".
Eso es el **enlace**:

| Enlace | Distancia entre los grupos A y B | Lo que produce |
|---|---|---|
| simple (`single`) | el par más cercano | cadenas; aísla poco |
| completo (`complete`) | el par más lejano | grupos compactos |
| promedio (`average`) | la media de todos los pares | intermedio; aparta atípicos |
| centroide (`centroid`) | entre sus medias | puede tener inversiones |
| Ward (`ward.D2`) | cuánto sube la inercia al fusionarlos | grupos esféricos, como k-medias |

El promedio, que es el del Taller 02, se escribe

$$
d(A, B) = \frac{1}{|A|\,|B|} \sum_{i \in A} \sum_{j \in B} d(x_i, x_j)
$$

y Ward fusiona el par que menos sube la inercia intra-grupo:

$$
\Delta W(A, B) = \frac{|A|\,|B|}{|A| + |B|} \lVert \mu_A - \mu_B \rVert^2
$$

## Por qué es necesaria

Porque k-medias necesita `k` antes de empezar, y depende de dónde arrancó. El
jerárquico es **determinista** —sin semilla— y devuelve todas las
particiones a la vez: elegir `k` es mirar el árbol, no reajustar.

Y porque el árbol cuenta más que los grupos: qué países se parecen primero,
cuáles se juntan recién al final, cuál queda solo hasta la última fusión.

## Lo que hace el algoritmo

1. Calcular las distancias entre todos los pares de observaciones.
2. Fusionar los dos grupos más cercanos según el enlace.
3. Actualizar las distancias del grupo nuevo con los demás.
4. Repetir hasta que quede uno.

En la fase 3 la traza es ese historial: una iteración por fusión, con la
altura a la que se juntaron y la inercia que queda. No hay tolerancia ni
techo de iteraciones: son exactamente `n − 1` pasos.

## Juzgar el árbol

- **Correlación cofenética.** La altura a la que el árbol junta dos
  observaciones es su distancia cofenética; correlacionarla con la distancia
  original dice cuánto distorsiona el árbol. Por encima de 0.8 lo representa
  bien.
- **Dónde cortar.** Donde las ramas son largas: un salto grande entre una
  fusión y la siguiente separa grupos que estaban lejos.
- **Silueta.** La misma que en k-medias, sobre la partición cortada y con la
  misma distancia que usó el árbol.

## Cuándo falla

- **Las fusiones no se deshacen.** Un error temprano se arrastra hasta arriba.
- **Memoria.** Guarda las `n(n−1)/2` distancias: con miles de filas no entra.
  Para eso está k-medias.
- **Atípicos.** Con enlace promedio o simple quedan como grupos de uno, y el
  corte en `k` gasta un grupo en cada uno. Mirarlos es un resultado; dejarlos
  dentro puede no serlo.
- **Sin escalar.** La variable de mayor rango decide todas las distancias.
- **Ward con Manhattan.** Ward está pensado para la distancia euclídea; con
  otra métrica corre, pero la inercia deja de ser lo que minimiza.

## En R

```r
d <- dist(scale(X), method = "euclidean")
arbol <- hclust(d, method = "average")
grupos <- cutree(arbol, k = 3)
plot(arbol, cex = 0.6); rect.hclust(arbol, k = 3)
cor(cophenetic(arbol), d)   # correlacion cofenetica
```

`method = "ward.D2"` y no `"ward.D"`: el segundo aplica Ward a distancias sin
elevar al cuadrado, que no es el criterio de Ward.
