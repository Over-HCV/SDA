## Qué es

Una rotación de los ejes. Los datos no cambian: cambia desde dónde se los mira.
Las **componentes principales** son direcciones nuevas, perpendiculares entre
sí, ordenadas de mayor a menor varianza capturada. La primera es la dirección
en la que la nube de puntos está más estirada.

Formalmente: se busca el vector `a` de norma 1 que maximiza la varianza
proyectada.

$$
\text{maximizar } \operatorname{Var}\!\left( a^{\mathsf{T}} X \right)
\quad \text{sujeto a} \quad \lVert a \rVert = 1
$$

Con multiplicadores de Lagrange eso se convierte en $S a = \lambda a$ — un problema
de autovalores. Los autovectores son las direcciones, los autovalores son las
varianzas.

## Por qué es necesaria

Porque con `p` variables correlacionadas hay información repetida, y esa
redundancia hace tres daños concretos:

1. **No se puede ver.** Más de tres dimensiones no se dibujan. El ACP da el
   mejor plano posible para mirar la nube.
2. **Rompe la regresión.** Predictores colineales inflan los errores estándar
   hasta volver los coeficientes ininterpretables.
3. **Cuesta caro.** Almacenar y calcular sobre 50 columnas que en realidad
   dicen lo que dirían 5.

El ACP responde a la pregunta: *¿cuántas dimensiones hacen falta de verdad?*

## Las dos lecturas, que son la misma

- **Máxima varianza**: quedarse con las direcciones donde los datos más varían.
- **Mínimo error de reconstrucción**: quedarse con el subespacio que menos
  deforma la nube al proyectarla.

Son equivalentes. Que lo sean no es casualidad: el teorema de Pitágoras
descompone la distancia total en proyección más residuo, así que maximizar una
parte es minimizar la otra.

## La decisión que más cambia el resultado

**Sobre S o sobre R.** Descomponer la matriz de covarianzas `S` usa las
variables tal como vienen: la de mayor varianza domina las primeras
componentes. Si una variable está en pesos y otra en años, la primera
componente será básicamente "pesos".

Descomponer la matriz de correlación `R` equivale a estandarizar antes: todas
las variables pesan igual.

No hay respuesta universal. Si las unidades son comparables y sus escalas
significan algo, usá `S`. Si no, usá `R`. Lo que no se puede es no decidir.

## Cuántas componentes se quedan

Tres reglas, y ninguna gana:

- **Umbral acumulado.** La primera `k` con la que el acumulado pasa el 80 %. Es
  la más usada y la más arbitraria: el 80 viene de la costumbre.
- **Kaiser.** Retener mientras $\lambda_j > 1$. El 1 es la varianza de una
  variable estandarizada: una componente que no llega hace menos que una
  variable sola. Solo significa algo sobre `R`; sobre `S` el corte pasa a ser la
  media de los valores propios.
- **Codo.** El vértice del quiebre del scree. Es la más frágil: sirve para
  confirmar, no para decidir sola.

Casi siempre dan el mismo número. Cuando no, **la discrepancia es el resultado**:
dice que la curva no tiene forma y que no hay pocas dimensiones que resuman
estos datos. Por eso las tres se muestran juntas en vez de elegir una por
adelantado.

## Contribución y calidad, que son preguntas distintas

Las cargas dicen con qué signo entra cada variable. Faltan dos números para
interpretar sin equivocarse:

- **Contribución** — $100 \cdot v_{ij}^2$, que reparte 100 dentro de cada
  componente. Contesta *¿quién manda en este eje?* La referencia es `100/p`.
- **Calidad de representación** — $\cos^2_{ij} = r^2(x_i, \mathrm{CP}_j)$, y su
  suma sobre los dos ejes del plano. Contesta *¿se ve esta variable acá?* Es la
  longitud de la flecha del círculo, al cuadrado.

Una variable puede estar perfectamente representada y aportar poco a cada eje, y
al revés. Confundirlas es leer el círculo al revés: una flecha corta no es una
variable sin importancia, es una variable que vive en las componentes que no
estás mirando.

Lo mismo vale por filas. Dos observaciones pueden caer en el mismo punto del
plano viniendo de lados opuestos del espacio: su `cos²` es bajo y el dibujo las
está mintiendo. Y una fila con contribución alta a la primera componente es un
atípico influyente, con número, antes de sospecharlo mirando.

## Individuos y variables suplementarias

Una fila que **no** participó de la maximización se puede proyectar igual:

$$
z_{\text{nuevo}} = \left( \frac{x_{\text{nuevo}} - \bar{x}}{s} \right) V
$$

La media, la desviación y las cargas son **las del ajuste**, no las del dato
nuevo. Recalcular el centro sobre el suplementario lo pondría en otro espacio y
lo dibujaría igual, que es la única forma de equivocarse acá.

Sirve para preguntar *¿dónde caería esto?* sin contaminar la respuesta: un carro
de 2014 medido con los ejes de 1974 dice cuánto se aparta de lo que su perfil
predecía. Por columnas es lo mismo: una variable que no entró se correlaciona
con las puntuaciones y se dibuja en el círculo, punteada.

## Las puntuaciones son variables nuevas

Las componentes **no están correlacionadas entre sí**, y eso no es un detalle
estético: es lo que arregla la colinealidad que rompía la regresión. Pocas
variables, ninguna redundante.

De ahí sale el uso industrial del método: paso intermedio. Regresión sobre
componentes principales, o *feature engineering* antes de cualquier otro modelo.
El lab las devuelve al almacén como un dataset, para que vuelvan a entrar por
la fase 1.

Lo que **no** es: un método para hacer grupos. El diagrama de dispersión de los
dos primeros ejes invita a dibujar círculos alrededor de las nubes, y el primer
eje recorre más variabilidad que el segundo, así que las distancias que se ven
están deformadas. Para grupos hay métodos de grupos.

## Cuándo falla

- **Estructura no lineal.** El ACP solo encuentra planos. Si los datos viven en
  una espiral, va a ver una nube redonda. Para eso están kernel PCA, t-SNE y UMAP.
- **Atípicos.** La varianza es una media de cuadrados: un punto lejano puede
  torcer la primera componente él solo. Mirá las distancias de Mahalanobis antes.
- **Confundir varianza con utilidad.** La componente de mayor varianza no es
  necesariamente la más útil para predecir. Para clasificar, la dirección
  discriminante puede ser la última componente.
- **Interpretabilidad.** Una componente es una combinación de todas las
  variables originales. Ganás dimensiones y perdés nombres.

## En R

```r
ajuste <- prcomp(X, scale. = TRUE)   # scale.=TRUE es "usar R en vez de S"
summary(ajuste)                      # proporción de varianza explicada
ajuste$rotation                      # cargas: los autovectores
ajuste$x                             # puntuaciones: las observaciones rotadas
```

## Para seguir

Análisis factorial es su primo, y la diferencia real no es técnica sino de
propósito: el ACP resume lo observado, el AF postula factores latentes que
causan lo observado.

Si las variables son cualitativas, el método no es este: es el
[ACM](acm.md), que descompone la matriz de Burt en vez de la de covarianzas. La
filosofía es idéntica —pocos ejes que resuman la asociación— y el semáforo de
supuestos de la fase 2 nombra la ruta cuando encuentra columnas que el ACP deja
fuera.
