## Qué es

Un reparto de las observaciones en `k` grupos cuando las variables son
**categorías** (sí/no, color, especie, número de patas como código), donde cada
grupo se representa por su **moda** —la categoría más frecuente de cada
variable dentro del grupo— y cada observación pertenece a la moda con la que
menos discrepa.

Lo que el algoritmo minimiza es el **costo**, la disimilitud intra-grupo:

$$
C = \sum_{l=1}^{k} \; \sum_{i \in G_l} d(x_i, m_l),
\qquad
d(x, m) = \sum_{j=1}^{p} \mathbb{1}\left[x_j \neq m_j\right]
$$

`d` es el **emparejamiento simple**: cuántas variables tienen categorías
distintas. Va de 0 (idénticas) a `p` (no comparten nada).

## Por qué k-medias no sirve acá

K-medias necesita dos cosas que las categorías no tienen:

- **Una resta.** La distancia euclidiana mide $(x_j - \mu_j)^2$, y "pez" menos
  "ave" no es un número. Codificar las categorías como 1, 2, 3 inventa un orden
  y unas distancias que nadie midió: con esa codificación un reptil queda "más
  cerca" de un pez que de un mamífero solo por el número que le tocó.
- **Un promedio.** El centroide de un grupo con 60 % de animales con pelo
  tendría `pelo = 0.6`, un animal que no existe. Con la matriz indicadora (una
  columna 0/1 por categoría) la cuenta sale, pero el centro sigue siendo una
  mezcla y las variables con muchas categorías pesan más que las binarias.

K-modas cambia exactamente esas dos piezas: la resta por **¿coinciden?** y la
media por **la moda**.

## Por qué la moda

Dentro de un grupo fijo, el costo se separa variable por variable:

$$
\sum_{i \in G} d(x_i, m) = \sum_{j=1}^{p} \sum_{i \in G} \mathbb{1}\left[x_{ij} \neq m_j\right]
= \sum_{j=1}^{p} \left( |G| - n_{j}(m_j) \right)
$$

donde $n_j(c)$ es cuántos miembros del grupo tienen la categoría `c` en la
variable `j`. Cada término se minimiza por separado, y $|G| - n_j(c)$ es mínimo
cuando $n_j(c)$ es máximo: **la categoría más frecuente**. Es el mismo argumento
que hace de la media el minimizador de los cuadrados, con otra pérdida.

La moda puede no ser única (dos categorías con la misma frecuencia). El costo
no cambia con la elección, así que el laboratorio la resuelve siempre por el
**primer nivel** del factor: arbitrario, pero reproducible.

## El algoritmo de Huang

1. **Arrancar**: elegir `k` modas iniciales que sean filas distintas.
2. **Asignar**: cada observación a la moda más cercana.
3. **Actualizar**: en el artículo de Huang (1998) la moda de los dos grupos
   tocados se recalcula *cada vez* que una fila cambia de grupo, no al final
   del barrido. Para que eso sea barato se llevan las frecuencias de cada
   categoría por grupo: mover una fila es restar uno en una tabla y sumar uno
   en otra.

Repetir los barridos hasta que nadie cambie de grupo.

**Ninguno de los dos pasos puede subir `C`**: una fila solo se mueve si queda
estrictamente más cerca de otra moda, y la moda recalculada es la óptima del
grupo. Por eso la curva de convergencia de la fase 3 solo baja, y por eso
termina, casi siempre en pocas iteraciones.

Un grupo nunca se vacía: su último miembro no se va, y si un arranque deja un
grupo sin nadie se le da la fila peor explicada de otro grupo.

## Las tres inicializaciones

| Arranque | Cómo elige | Qué cambia con la semilla |
|---|---|---|
| Huang | sortea categorías según su frecuencia y toma la fila real más parecida | todo |
| Cao | la fila más "densa" primero, después densidad × distancia a las ya elegidas | nada: es determinista |
| aleatoria | `k` filas distintas al azar | todo |

Con Cao los reinicios arrancan igual y terminan igual: diez reinicios cuestan
diez veces y no agregan nada. Es la forma de ver que la variación entre
reinicios venía del arranque y no del algoritmo.

## Relación con k-medias

| | k-medias | k-modas |
|---|---|---|
| datos | numéricos | categóricos |
| distancia | euclidiana al cuadrado | emparejamiento simple |
| representante | media (centroide) | moda |
| objetivo | inercia intra-grupo $W$ | disimilitud intra-grupo $C$ |
| arranque inteligente | k-means++ | Huang, Cao |

Para datos mixtos existe k-prototipos (Huang, 1998, el mismo artículo), que
suma las dos distancias con un peso $\gamma$ entre ellas.

## Cuándo falla

- **Empates por todas partes.** `d` toma solo los valores 0, 1, …, `p`. Con
  pocas variables, muchas filas quedan a la misma distancia de dos modas y la
  asignación depende de una regla de desempate, no de los datos. Con `p` chico
  los grupos son frágiles.
- **Dependencia del arranque.** Igual que k-medias, converge a un óptimo local.
  Los reinicios y la comparación de reinicios de la fase 3 son el remedio; con
  Zoo, semillas distintas terminan en costos distintos.
- **Menor costo no es mejor partición.** En Zoo con `k = 7`, el arranque que
  llega al costo más bajo no es el que mejor recupera la clase real (`tipo`).
  El costo mide cohesión, no verdad.
- **Variables binarias asimétricas.** En `venenoso`, dos animales que *no* son
  venenosos coinciden igual que dos que sí lo son, y lo primero no dice casi
  nada. El emparejamiento simple trata el "no" compartido como evidencia; el
  índice de Jaccard (o Gower con binarias asimétricas) no lo hace.
- **Pierde el orden.** Una variable ordinal (talla S < M < L) se trata como
  nominal: S y L discrepan exactamente lo mismo que S y M.
- **Todas las variables pesan igual.** Una variable con siete categorías y una
  binaria aportan como máximo 1 cada una al costo, aunque la primera lleve más
  información.

## En R

```r
# En el laboratorio, escrito a mano y con traza:
ajuste <- ajustar_kmodos(zoo, columnas = setdiff(names(zoo), c("animal", "tipo")),
                         k = 7, inicializacion = "Huang", reinicios = 10)
ajuste$costo        # C
ajuste$modos        # una fila por grupo, una categoría por variable
table(zoo$tipo, ajuste$grupos)

# Fuera del laboratorio:
set.seed(42)
klaR::kmodes(datos_categoricos, modes = 7, iter.max = 100)
```

`tipo` se deja afuera a propósito: es la respuesta. Meterla como variable es
agrupar con la solución en la mano.
