## Qué es

Un modelo de **mezcla** para variables cualitativas. Se supone que la población
está hecha de $K$ clases que no se observan, y que cada clase tiene su propia
tabla de probabilidades para cada variable. Una observación $x_i$ con $J$
variables tiene probabilidad

$$
P(x_i) = \sum_{c=1}^{K} \pi_c \prod_{j=1}^{J} \prod_{r=1}^{R_j} \theta_{jrc}^{\,[x_{ij} = r]}
$$

donde $\pi_c$ es el peso de la clase $c$ (cuánta población le toca),
$\theta_{jrc}$ es la probabilidad de que alguien de la clase $c$ responda la
categoría $r$ en la variable $j$, y $[x_{ij} = r]$ vale 1 si eso ocurrió y 0 si
no. Cada bloque suma uno: $\sum_r \theta_{jrc} = 1$.

## De las mezclas gaussianas a las de multinomiales

En clase se vio la mezcla gaussiana: cada grupo es una campana
$\mathcal{N}(\mu_c, \Sigma_c)$ y la densidad de una observación es
$\sum_c \pi_c \, \phi(x_i; \mu_c, \Sigma_c)$. El análisis de clases latentes es
**el mismo modelo con otra pieza dentro**: donde había una normal multivariada
hay un producto de multinomiales, una por variable.

| | Mezcla gaussiana | Clases latentes |
|---|---|---|
| Datos | numéricos | categorías |
| Lo que describe una clase | media $\mu_c$ y covarianza $\Sigma_c$ | una tabla $\theta_{\cdot\cdot c}$ por variable |
| Dependencia dentro de la clase | la que diga $\Sigma_c$ | ninguna (independencia local) |
| Algoritmo | EM | EM |
| Elegir $K$ | BIC | BIC |

Que $\Sigma_c$ sea diagonal en la gaussiana es exactamente la misma suposición
que la independencia local acá.

## El supuesto que lo sostiene: independencia local

Dentro de cada clase, las variables son independientes. Toda la asociación que
se ve en los datos —que los animales con pelo dan leche, que los que tienen
plumas ponen huevos— se explica **solo** porque pertenecen a la misma clase.
Saber la clase basta; una vez sabida, conocer una variable no dice nada de otra.

Es un supuesto fuerte, y es el que hace al modelo estimable: sin él, cada clase
necesitaría una tabla conjunta de $\prod_j R_j$ celdas.

## El EM, paso a paso

La verosimilitud es una suma dentro de un logaritmo y no tiene máximo en forma
cerrada. EM la sube alternando dos pasos que sí la tienen.

**Paso E**: con los parámetros actuales, la probabilidad posterior de que la
observación $i$ venga de la clase $c$ (la regla de Bayes):

$$
\tau_{ic} = \frac{\pi_c \prod_j \theta_{j x_{ij} c}}{\sum_{l=1}^{K} \pi_l \prod_j \theta_{j x_{ij} l}}
$$

**Paso M**: con esas posteriores como pesos, los parámetros son proporciones
ponderadas:

$$
\pi_c = \frac{1}{n} \sum_{i=1}^{n} \tau_{ic}
\qquad
\theta_{jrc} = \frac{\sum_i \tau_{ic} \, [x_{ij} = r]}{\sum_i \tau_{ic}}
$$

Es k-modos con **asignación blanda**: en vez de mandar cada fila entera a una
clase, se reparte entre todas según $\tau_{ic}$, y cada clase cuenta sus
categorías con esos pesos.

Ninguno de los dos pasos puede bajar la log-verosimilitud
$\ell = \sum_i \log P(x_i)$. Por eso la curva de convergencia de la fase 3 solo
**sube**, y si alguna vez baja es un error del código, no del modelo.

Dos detalles de la implementación del laboratorio:

- El paso E se calcula en logaritmos con el truco *log-sum-exp*: el producto de
  dieciséis probabilidades es tan chico que, sin él, el cociente da $0/0$.
- $\theta_{jrc} = 0$ está permitido —ningún pez tiene plumas— y se mantiene
  exacto. Solo dentro del logaritmo se usa un piso de $10^{-300}$ para que
  $0 \cdot \log 0$ no dé `NaN`. No se suaviza con Laplace, porque eso cambiaría
  el óptimo.

## Asignación blanda contra dura

El resultado principal no es una partición sino la matriz $\tau$ de $n \times K$.
La partición se obtiene asignando cada fila a su clase más probable (MAP), y la
**entropía relativa**

$$
E = 1 - \frac{-\sum_i \sum_c \tau_{ic} \log \tau_{ic}}{n \log K}
$$

dice qué tan nítida quedó: 1 si cada fila cae entera en una clase, 0 si todas
las posteriores son uniformes. Una $E$ alta mide nitidez, no acierto: un modelo
sobreajustado también es nítido.

## Elegir K con el BIC

La verosimilitud siempre sube con $K$, así que compararla cruda elige siempre
el modelo más grande. El BIC la castiga por los parámetros que cuesta:

$$
\text{BIC} = -2\,\ell + m \log n
\qquad
m = (K - 1) + K \sum_{j=1}^{J} (R_j - 1)
$$

Se elige el $K$ de **menor** BIC. $K = 1$ es el modelo de independencia total y
es la vara: si el BIC no baja al pasar de 1 a 2, no hay clases que encontrar.
El AIC ($-2\ell + 2m$) castiga menos y suele pedir más clases.

## Cuándo falla

- **Independencia local violada.** Si dos variables están ligadas por algo
  distinto de la clase, el modelo solo puede explicar esa asociación partiendo
  una clase en dos, y el BIC pide más clases de las que hay. En el zoológico,
  *pelo* y *leche* van casi siempre juntas (39 de los 41 animales que dan
  leche tienen pelo): mientras las dos queden dentro de la misma clase no hay
  problema, pero son en la práctica una sola variable contada dos veces, y pesan doble en la
  definición de las clases.
- **Máximos locales.** La superficie tiene muchos. En el zoológico con
  $K = 3$, distintos arranques terminan en decenas de valores distintos de
  $\ell$. `reinicios` no es un adorno: se queda con el arranque de mayor
  verosimilitud, y la sensibilidad a la semilla de la fase 3 muestra cuántos
  llegan al mismo lugar.
- **Cambio de etiquetas (*label switching*).** La verosimilitud no cambia si se
  permutan las clases, así que "clase 2" no significa nada por sí sola. El
  laboratorio las ordena por tamaño, de mayor a menor, y permuta pesos,
  probabilidades, posteriores y traza a la vez.
- **Celdas ralas y soluciones de frontera.** Con pocas observaciones por clase,
  muchas $\theta$ terminan en 0 o en 1 exactos. No es un error, pero esos
  parámetros están en el borde del espacio, los errores estándar dejan de
  valer, y el conteo de $m$ del BIC sobrestima los parámetros que de verdad se
  estimaron.
- **Pocas filas, muchos parámetros.** Con 16 variables cada clase cuesta 20
  parámetros en el zoológico; con $K = 5$ ya son 104 para 101 animales. El
  modelo sigue siendo **identificable** —la condición necesaria es
  $m < \prod_j R_j - 1$, y con 16 variables sobra— pero la estimación es
  frágil. Con dos variables binarias, en cambio, la condición falla y el
  laboratorio se niega a ajustar.

## En R

```r
library(poLCA)
# poLCA quiere las categorías como enteros 1..R
codigos <- as.data.frame(lapply(zoo[variables], as.integer))
ajuste <- poLCA(cbind(pelo, plumas, huevos, leche) ~ 1, codigos,
                nclass = 4, nrep = 20, verbose = FALSE)
ajuste$llik       # log-verosimilitud
ajuste$bic        # BIC
ajuste$P          # pesos de las clases
ajuste$probs      # θ, una matriz por variable
ajuste$posterior  # la asignación blanda
```

`nrep = 20` cumple el mismo papel que `nstart` en `kmeans()`. poLCA usa las
filas con faltantes (las salta dentro del producto); el laboratorio las
descarta, así que con datos incompletos los dos ajustes no coinciden.
