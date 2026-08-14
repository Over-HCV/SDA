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
