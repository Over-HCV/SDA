## Qué es

Un reparto de las observaciones en `k` grupos, donde cada grupo se representa
por su **centroide** (la media de sus miembros) y cada punto pertenece al
centroide más cercano.

Lo que el algoritmo minimiza es la **inercia intra-grupo**:

```
W = Σₖ Σ_{i ∈ Cₖ} ‖xᵢ − μₖ‖²
```

## Por qué es necesaria

Porque a veces no hay etiquetas. Nadie te dice cuántos tipos de país hay en el
panel de charcoal ni cuáles son: la estructura, si existe, está en los datos y
hay que sacarla.

Y porque agrupar es el paso previo a casi todo lo demás: caracterizar los
grupos encontrados suele ser el resultado sustantivo del análisis, no un medio.

## El algoritmo de Lloyd, que es de dos pasos

1. **Asignar**: cada punto al centroide más cercano.
2. **Actualizar**: cada centroide a la media de los puntos que le tocaron.

Repetir hasta que nadie cambie de grupo.

**Ninguno de los dos pasos puede subir `W`.** Por eso la curva de convergencia
solo baja, y por eso el algoritmo siempre termina. Vale la pena verlo paso a
paso en la fase 3: los centroides caminan y se frenan.

## La trampa: converger no es acertar

Que `W` deje de bajar significa que llegaste a un **óptimo local**, no al
global. Con una inicialización desafortunada el algoritmo se estanca en un
reparto malo y se queda ahí, perfectamente convergido.

Los dos remedios son el mismo remedio con distinta cara:

- `nstart > 1`: correr varias veces desde puntos distintos y quedarse con la
  mejor.
- `k-means++`: elegir centroides iniciales separados entre sí en vez de al azar.

En la fase 3, "Sensibilidad a la semilla" superpone N reinicios. Si todos caen
en el mismo `W`, hay una estructura real. Si se dispersan, no la hay o `k` está
mal elegido.

## Elegir k

No hay un criterio que decida solo. Hay cuatro que, juntos, orientan:

| Criterio | Qué mira | Qué le falta |
|---|---|---|
| Plano factorial | la nube proyectada, a ojo | subjetivo, y solo 2 de `p` dimensiones |
| Codo de `W(K)` | dónde deja de valer la pena partir | el codo muchas veces no existe |
| Silueta | cohesión contra separación, punto a punto | penaliza grupos alargados |
| Estadístico gap | compara contra datos sin estructura | caro de calcular |

Antes de todos ellos: **¿hay grupos siquiera?** El estadístico de Hopkins
contesta esa pregunta, y muchas veces la respuesta es no.

## Cuándo falla

- **Grupos no esféricos.** K-medias usa distancia euclidiana a un centro, así
  que solo puede encontrar bolas. Grupos alargados o en forma de luna los parte
  mal. Para eso están DBSCAN y el espectral.
- **Tamaños muy distintos.** Tiende a partir el grupo grande y a fusionar los
  chicos, porque eso baja más `W`.
- **Sin escalar.** La variable con más varianza domina la distancia. Escalar
  antes no es opcional.
- **Atípicos.** Un punto lejano arrastra su centroide. K-medoides (PAM) es
  la variante robusta.

## En R

```r
set.seed(42)
ajuste <- kmeans(scale(X), centers = 3, nstart = 25, algorithm = "Lloyd")
ajuste$tot.withinss   # W
ajuste$cluster        # a qué grupo fue cada observación
ajuste$centers        # los centroides, en la escala escalada
```

`nstart = 25` no es un adorno: con `nstart = 1` el resultado depende de la
suerte, y cambia cada vez que corrés sin fijar semilla.
