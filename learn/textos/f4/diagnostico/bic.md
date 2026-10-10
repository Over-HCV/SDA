## Para qué sirve

Elegir cuántos grupos con un criterio que tiene un mínimo de verdad. En un
modelo de mezclas (clases latentes, mezclas gaussianas) la verosimilitud
siempre sube al agregar un grupo, y el BIC le resta lo que cuesta en
parámetros: el `k` que lo minimiza es el que mejor equilibra ajuste y
complejidad.

## Qué muestra

Dos curvas contra `k`, ajustando el modelo una vez por cada `k`:

$$
\mathrm{BIC} = -2\,\ell(\hat\theta) + m \log n,
\qquad
\mathrm{AIC} = -2\,\ell(\hat\theta) + 2m
$$

donde $\ell$ es la log-verosimilitud y $m$ el número de parámetros libres. Con
clases latentes sobre $p$ variables de $R_j$ categorías,
$m = (k - 1) + k\sum_j (R_j - 1)$. El círculo marca el mínimo de cada curva y
la línea punteada el `k` con que se ajustó la corrida.

## Qué buscar

- **El mínimo del BIC.** Es la sugerencia del criterio. Si cae en el borde
  del rango probado, el rango era corto.
- **BIC y AIC en desacuerdo.** El AIC penaliza menos y casi siempre pide más
  grupos. Cuando discrepan, el BIC suele ser el más conservador y el AIC el
  que mejor predice; la discrepancia en sí es información.
- **Una curva plana cerca del mínimo.** Varios `k` casi empatados: la
  elección entre ellos la decide la interpretación (los modos), no el número.

## Cuándo engaña

**Mínimos locales.** El EM arranca de un punto y puede quedarse en un óptimo
local; un BIC que sube y baja en zigzag delata `k` mal ajustados, no una
estructura. Más arranques lo arreglan.

**Con n chico penaliza fuerte.** Con 101 animales y muchas categorías, cada
grupo nuevo cuesta decenas de parámetros, y el BIC puede quedarse por debajo
de las siete clases reales aunque existan.

**Supone el modelo.** Las clases latentes suponen independencia de las
variables DENTRO de cada grupo. Si dos atributos van siempre juntos (`pelo` y
`leche`), el modelo necesita grupos extra para explicar esa asociación, y el
BIC los pide.
