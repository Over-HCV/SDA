# Árbol de temas — Análisis Estadístico de Datos

Índice maestro en anchura: **todo** lo que sostiene el curso, lo que el curso ve, y hacia dónde apunta. Cada nodo está ordenado de lo más simple a lo más complejo dentro de su lista de hermanos, en todos los niveles.

## Convención

- **Orden visual** = posición en la lista anidada.
- **Orden en disco** = prefijo de tres dígitos del slug (`010`, `020`, `030`…), en saltos de 10.
- Los prefijos son **locales a cada lista de hermanos** y **no se encadenan**: `090-reduccion/020-acp/030-escalamiento`, nunca `9.2.3`. Mover una rama entera no rompe nada por debajo.
- **Regla de inserción**: tema nuevo en medio → prefijo intermedio (`015-…`). Solo si se agota el hueco se renumera **esa** lista de hermanos, jamás el árbol.
- **Símbolo** entre corchetes cuando el tema tiene un objeto matemático distintivo: `Matriz de covarianzas [Σ]`.
- Los nodos sin slug son matices conceptuales del padre: no merecen archivo propio (todavía). Si uno crece, se le da slug y sube a nodo.

## De árbol a diagrama navegable

Cada nodo con slug es un archivo futuro. La ruta se arma concatenando los slugs de sus ancestros:

```mermaid
flowchart TB
    MD["Matriz de datos"] --> VM["Vector de medias"] --> S["Matriz de covarianzas"]
    click MD "./070-multivariado/010-matriz-datos.md"
    click VM "./070-multivariado/020-vector-medias.md"
    click S  "./070-multivariado/030-matriz-covarianzas.md"
```

---

## 010 · Fundamentos matemáticos `010-fundamentos/`

Cimiento. No es "estadística" pero sin esto los métodos multivariados son recetas ciegas.

- Notación y lenguaje `010-notacion`
  - Índices, sumatorias y productorias **[Σ, Π]**
  - Conjuntos, pertenencia y operaciones **[∈, ∪, ∩, ∖]**
  - Funciones, dominio, recorrido, composición **[f: A→B]**
- Vectores `020-vectores`
  - Vector como punto y como flecha **[x ∈ ℝᵖ]**
  - Suma y producto por escalar
  - Producto interno (punto) `010-producto-interno` **[⟨x,y⟩ = xᵀy]**
  - Norma y distancia euclidiana `020-norma` **[‖x‖, d(x,y)]**
  - Ángulo, ortogonalidad y proyección `030-proyeccion` **[cos θ, proj_v(x)]**
  - Combinación lineal, independencia, base y dimensión `040-base-dimension`
  - Espacio generado (span) y subespacios
- Matrices `030-matrices`
  - Matriz como arreglo, como transformación y como tabla de datos **[A (n×p)]**
  - Operaciones: suma, producto, transpuesta `010-operaciones` **[AB, Aᵀ]**
  - Tipos especiales: identidad, diagonal, simétrica, ortogonal `020-tipos` **[I, D, A=Aᵀ, QᵀQ=I]**
  - Traza `030-traza` **[tr(A)]**
  - Determinante e interpretación como volumen `040-determinante` **[|A|]**
  - Rango `050-rango` **[rk(A)]**
  - Inversa y sistemas lineales `060-inversa` **[A⁻¹]**
  - Inversa generalizada (Moore–Penrose) **[A⁺]**
  - Matriz de centrado `070-matriz-centrado` **[H = I − (1/n)11ᵀ]**
- Formas cuadráticas y definitud `040-formas-cuadraticas`
  - Forma cuadrática **[Q(x) = xᵀAx]**
  - Definida positiva, semidefinida, indefinida **[A ≻ 0, A ⪰ 0]**
  - Elipsoides como conjuntos de nivel `010-elipsoides` **[xᵀA⁻¹x = c]**
- Autovalores y autovectores `050-autovalores` **[Av = λv]**
  - Polinomio característico **[|A − λI| = 0]**
  - Multiplicidad, espectro y su interpretación geométrica **[λ₁ ≥ … ≥ λₚ]**
  - Descomposición espectral de matrices simétricas `010-descomposicion-espectral` **[A = PΛPᵀ]**
  - Raíz cuadrada de una matriz y potencias **[A^{1/2}]**
  - Descomposición en valores singulares (SVD) `020-svd` **[X = UDVᵀ]**
- Cálculo para estadística `060-calculo`
  - Derivada e interpretación como tasa de cambio `010-derivada` **[dy/dx]**
  - Derivadas parciales y gradiente `020-gradiente` **[∂f/∂xᵢ, ∇f]**
  - Regla de la cadena
  - Integral definida como área acumulada `030-integral` **[∫ₐᵇ f(x)dx]**
  - Integrales múltiples `040-integrales-multiples` **[∬ f(x,y)dxdy]**
  - Cálculo matricial: derivadas respecto a vectores `050-calculo-matricial` **[∂(xᵀAx)/∂x]**
- Optimización `070-optimizacion`
  - Máximos y mínimos, condiciones de primer y segundo orden **[∇f = 0]**
  - Mínimos cuadrados como problema geométrico `010-minimos-cuadrados` **[mín ‖y − Xβ‖²]**
  - Multiplicadores de Lagrange y optimización con restricción `020-lagrange` **[ℒ = f − λg]**
  - Métodos iterativos: descenso, convergencia local vs. global `030-metodos-iterativos`

---

## 020 · Datos y estadística descriptiva `020-descriptiva/`

- Marco conceptual `010-marco`
  - Población y muestra `010-poblacion-muestra` **[N, n]**
  - Unidad estadística (UE) `020-unidad-estadistica`
  - Variable, dato y medición `030-variable-dato-medicion`
  - Parámetro vs. estadística `040-parametro-estadistica` **[θ vs. θ̂]**
- Clasificación de variables `020-clasificacion`
  - Escala de medición `010-escala`
    - Nominal
    - Ordinal
    - De intervalo
    - De razón
  - Clase `020-clase`
    - Cualitativa (categórica)
    - Cuantitativa discreta
    - Cuantitativa continua
  - Dimensión `030-dimension`
    - Univariada
    - Bivariada
    - Multivariada **[p variables]**
  - Consecuencia: qué operación y qué gráfico permite cada escala
- Estructura del conjunto de datos `030-estructura-datos`
  - Datos ordenados (tidy): fila = UE, columna = variable
  - Tipos de dato y lectura desde archivo
  - Datos faltantes: patrones y primeras decisiones `010-faltantes` **[NA]**
- Resumen tabular univariado `040-tabular`
  - Frecuencia absoluta `010-frecuencia-absoluta` **[nᵢ]**
  - Frecuencia relativa y porcentual `020-frecuencia-relativa` **[fᵢ = nᵢ/n]**
  - Frecuencias acumuladas `030-acumuladas` **[Nᵢ, Fᵢ]**
  - Agrupación en clases: número de intervalos, amplitud, marca de clase `040-agrupacion`
- Resumen numérico univariado `050-numerico`
  - Medidas de centro `010-centro`
    - Moda **[Mo]**
    - Mediana **[Me, Q₂]**
    - Media aritmética **[x̄]**
    - Media ponderada, geométrica y armónica
    - Media recortada y robustez del centro
  - Medidas de localización `020-localizacion`
    - Cuantiles, cuartiles y percentiles **[Qₖ, Pₖ]**
    - Puntaje estandarizado **[z = (x − x̄)/s]**
  - Medidas de dispersión `030-dispersion`
    - Rango **[R]**
    - Rango intercuartílico **[IQR = Q₃ − Q₁]**
    - Desviación media absoluta
    - Varianza muestral y su denominador n−1 **[s²]**
    - Desviación estándar **[s]**
    - Coeficiente de variación **[CV = s/x̄]**
  - Medidas de forma `040-forma`
    - Asimetría (sesgo) **[g₁]**
    - Curtosis **[g₂]**
  - Detección de atipicidades `050-atipicos`
    - Criterio de la cerca: Q₁ − 1.5·IQR, Q₃ + 1.5·IQR
    - Criterio del puntaje z **[|z| > 3]**
    - Atípico ≠ error: qué hacer con uno
- Resumen gráfico univariado `060-graficos`
  - Gráfico de barras (categóricas) `010-barras`
  - Gráfico circular y por qué casi siempre es peor que las barras
  - Histograma `020-histograma`
    - Ancho de banda y número de clases: el mismo dato, dos historias
    - Del histograma a la idea de densidad
  - Polígono de frecuencias y ojiva
  - Diagrama de tallo y hojas
  - Boxplot `030-boxplot` **[Q₁, Me, Q₃]**
    - Resumen de cinco números
    - Bigotes, cercas y puntos atípicos
    - Boxplot comparativo entre grupos
  - Violín y beeswarm: densidad + resumen en un gráfico
  - Gráfico de dispersión `040-dispersion` **[(xᵢ, yᵢ)]**
  - Principios de visualización efectiva `050-principios-visualizacion`

---

## 030 · Probabilidad `030-probabilidad/`

- Experimento aleatorio y espacio muestral `010-espacio-muestral` **[Ω]**
  - Determinístico vs. aleatorio
  - Evento simple y compuesto **[A ⊆ Ω]**
  - Álgebra de eventos: unión, intersección, complemento **[A∪B, A∩B, Aᶜ]**
  - Eventos mutuamente excluyentes **[A∩B = ∅]**
- Reglas de conteo `020-conteo`
  - Principio multiplicativo
  - Permutaciones `010-permutaciones` **[P(n,k)]**
  - Combinaciones `020-combinaciones` **[C(n,k) = (n k)]**
  - Permutaciones con repetición y coeficiente multinomial
- Medida de probabilidad `030-medida-probabilidad` **[P(A)]**
  - Enfoque clásico, frecuentista y subjetivo
  - Axiomas de Kolmogórov `010-axiomas` **[P(A) ≥ 0, P(Ω) = 1, σ-aditividad]**
  - Propiedades derivadas: complemento, monotonía, inclusión–exclusión
  - Regla aditiva **[P(A∪B) = P(A) + P(B) − P(A∩B)]**
- Probabilidad condicional `040-condicional` **[P(A|B)]**
  - Definición y reducción del espacio muestral
  - Regla multiplicativa y regla de la cadena **[P(A∩B) = P(A|B)P(B)]**
  - Independencia de eventos `010-independencia` **[P(A∩B) = P(A)P(B)]**
    - Independencia por pares vs. mutua
  - Ley de probabilidad total `020-probabilidad-total` **[P(A) = Σ P(A|Bᵢ)P(Bᵢ)]**
  - Teorema de Bayes `030-bayes` **[P(B|A) = P(A|B)P(B)/P(A)]**
    - Previa, verosimilitud, posterior
    - Falsos positivos y la trampa de la tasa base

---

## 040 · Variables aleatorias y modelos `040-variables-aleatorias/`

- Variable aleatoria `010-variable-aleatoria` **[X: Ω → ℝ]**
  - Discreta vs. continua
  - Soporte de la distribución
- Distribuciones discretas `020-discretas`
  - Función de masa de probabilidad `010-fmp` **[p(x) = P(X = x)]**
  - Función de distribución acumulada `020-fda` **[F(x) = P(X ≤ x)]**
  - Modelos discretos `030-modelos-discretos`
    - Uniforme discreta
    - Bernoulli **[X ~ Ber(p)]**
    - Binomial **[X ~ Bin(n,p)]**
    - Geométrica y binomial negativa
    - Hipergeométrica
    - Poisson **[X ~ Poi(λ)]**
- Distribuciones continuas `030-continuas`
  - Del histograma a la función de densidad: motivación `010-motivacion-densidad`
  - Función de densidad `020-fdp` **[f(x) ≥ 0, ∫f = 1]**
    - La probabilidad es área, no altura **[P(a<X<b) = ∫ₐᵇ f]**
    - P(X = x) = 0 en el caso continuo
  - Función de distribución acumulada continua `030-fda-continua` **[F(x) = ∫₋∞ˣ f]**
  - Función cuantil (inversa) `040-funcion-cuantil` **[F⁻¹(p)]**
  - Modelos continuos `050-modelos-continuos`
    - Uniforme continua **[U(a,b)]**
    - Exponencial **[Exp(λ)]**
    - Gamma y Beta
    - Normal `010-normal` **[N(μ, σ²)]**
- Esperanza y momentos `040-esperanza-momentos`
  - Valor esperado `010-esperanza` **[E(X) = μ]**
  - Esperanza de una función **[E(g(X))]**
  - Varianza y desviación estándar `020-varianza` **[Var(X) = σ², σ]**
  - Propiedades de E y Var bajo transformaciones lineales **[E(aX+b), Var(aX+b)]**
  - Momentos y momentos centrados **[E(Xᵏ), E((X−μ)ᵏ)]**
  - Función generadora de momentos `030-fgm` **[M_X(t) = E(e^{tX})]**
  - Desigualdad de Chebyshev `040-chebyshev`
- La distribución normal en detalle `050-normal-detalle`
  - Parámetros y forma de campana **[μ, σ²]**
  - Normal estándar y estandarización `010-normal-estandar` **[Z = (X−μ)/σ ~ N(0,1)]**
  - Cálculo de probabilidades y cuantiles **[Φ(z), z_α]**
  - Regla empírica 68–95–99.7
  - Propiedades: simetría, cierre bajo combinaciones lineales
  - Estimación de parámetros bajo normalidad `020-estimacion-normal` **[μ̂ = x̄, σ̂²]**
  - Verificación de normalidad `030-verificacion-normalidad`
    - Gráfico Q–Q normal **[Q–Q plot]**
    - Pruebas: Shapiro–Wilk, Anderson–Darling, Kolmogórov–Smirnov
  - Transformaciones para inducir normalidad **[log, √, Box–Cox]**
- Estimación de la densidad `060-estimacion-densidad`
  - Densidad paramétrica: ajustar una normal a los datos `010-parametrica`
  - Densidad no paramétrica: estimación kernel `020-kernel` **[f̂ₕ(x)]**
    - Función núcleo (gaussiano, epanechnikov, rectangular)
    - Ancho de banda y el sesgo–varianza del suavizado **[h]**
    - Selección automática del ancho de banda (Silverman)
  - Para qué sirve una densidad: comparar grupos, detectar multimodalidad, simular
- Distribuciones derivadas del muestreo normal `070-derivadas`
  - Ji-cuadrado `010-ji-cuadrado` **[χ²_ν]**
  - t de Student `020-t-student` **[t_ν]**
  - F de Fisher `030-f-fisher` **[F_{ν₁,ν₂}]**
  - Relaciones entre ellas y sus grados de libertad **[ν]**

---

## 050 · Pensamiento bivariado y dependencia `050-bivariado/`

- Por qué dos variables no son dos análisis univariados `010-motivacion`
- Distribuciones conjuntas `020-conjunta`
  - Función conjunta discreta y continua `010-conjunta` **[p(x,y), f(x,y)]**
  - Distribuciones marginales `020-marginal` **[f_X(x) = ∫f(x,y)dy]**
  - Distribuciones condicionales `030-condicional` **[f(y|x)]**
  - Independencia de variables aleatorias `040-independencia-vas` **[f(x,y) = f_X(x)f_Y(y)]**
  - Esperanza condicional `050-esperanza-condicional` **[E(Y|X)]**
- Medidas de asociación `030-asociacion`
  - Covarianza `010-covarianza` **[Cov(X,Y) = σ_{XY}]**
    - Signo, magnitud y su dependencia de las unidades
  - Correlación de Pearson `020-pearson` **[ρ, r ∈ [−1,1]]**
    - Solo mide asociación **lineal**
  - Correlación de Spearman y Kendall `030-rangos` **[ρ_s, τ]**
  - Correlación ≠ causalidad `040-correlacion-causalidad`
    - Variable confusora, colisionador, paradoja de Simpson
  - Varianza de una suma **[Var(X+Y) = Var(X) + Var(Y) + 2Cov(X,Y)]**
- Visualización bivariada `040-visualizacion-bivariada`
  - Diagrama de dispersión y sus patrones `010-dispersion-bivariada`
  - Sobreploteo: transparencia, jitter, hexbin
  - Densidad conjunta y curvas de nivel `020-densidad-conjunta`
  - Boxplots agrupados y gráficos condicionados (facetas)
- Asociación entre categóricas `050-categoricas`
  - Tabla de contingencia `010-tabla-contingencia` **[nᵢⱼ]**
  - Perfiles fila y columna
  - Gráfico de mosaico

---

## 060 · Muestreo e inferencia `060-inferencia/`

- El problema inferencial `010-problema-inferencial`
  - De la muestra a la población: inducción bajo incertidumbre
  - Muestra aleatoria e i.i.d. `010-muestra-aleatoria` **[X₁,…,Xₙ ~ iid F]**
  - Diseños de muestreo: simple, estratificado, por conglomerados, sistemático `020-disenos`
  - Sesgo de selección y de no respuesta
- Distribuciones muestrales `020-distribuciones-muestrales`
  - Estadístico como variable aleatoria `010-estadistico` **[T = g(X₁,…,Xₙ)]**
  - Distribución muestral de la media `020-muestral-media` **[X̄ ~ N(μ, σ²/n)]**
  - Error estándar `030-error-estandar` **[SE = σ/√n]**
  - Ley de los grandes números `040-lgn` **[X̄ →ᵖ μ]**
  - Teorema del límite central `050-tlc` **[√n(X̄−μ)/σ →ᵈ N(0,1)]**
    - Qué garantiza y qué no; el papel de n
  - Distribución muestral de la proporción y de la varianza **[p̂, (n−1)s²/σ²]**
- Estimación puntual `030-estimacion-puntual`
  - Estimador vs. estimación `010-estimador` **[θ̂]**
  - Propiedades de los estimadores `020-propiedades`
    - Insesgadez **[E(θ̂) = θ]**
    - Varianza y eficiencia **[Var(θ̂), cota de Cramér–Rao]**
    - Error cuadrático medio: sesgo² + varianza `010-ecm` **[ECM = Sesgo² + Var]**
    - Consistencia **[θ̂ₙ →ᵖ θ]**
    - Suficiencia
    - Robustez
  - Métodos de estimación `030-metodos`
    - Método de los momentos `010-momentos`
    - Máxima verosimilitud `020-maxima-verosimilitud` **[L(θ), ℓ(θ) = log L]**
      - Función de verosimilitud y log-verosimilitud
      - Ecuaciones de verosimilitud **[∂ℓ/∂θ = 0]**
      - Propiedades asintóticas e invarianza
      - Información de Fisher **[I(θ)]**
    - Mínimos cuadrados como caso particular `030-mco`
- Estimación por intervalo `040-intervalos`
  - Interpretación correcta de la confianza `010-interpretacion` **[1 − α]**
  - Cantidad pivotal y construcción general `020-pivotal`
  - IC para la media con σ conocida **[x̄ ± z_{α/2}·σ/√n]**
  - IC para la media con σ desconocida **[x̄ ± t_{α/2,n−1}·s/√n]**
  - IC para la proporción, la varianza y la diferencia de medias
  - Ancho del intervalo, tamaño de muestra y margen de error `030-tamano-muestra`
- Pruebas de hipótesis `050-pruebas-hipotesis`
  - Hipótesis nula y alternativa `010-hipotesis` **[H₀ vs. H₁]**
  - Unilateral vs. bilateral
  - Estadístico de prueba y región de rechazo `020-estadistico-prueba`
  - Errores tipo I y tipo II `030-errores` **[α, β]**
  - Potencia de la prueba `040-potencia` **[1 − β]**
  - Valor p: qué es y qué no es `050-valor-p` **[p-value]**
  - Relación entre IC y prueba de hipótesis
  - Pruebas clásicas `060-pruebas-clasicas`
    - Sobre una media **[t]**
    - Sobre dos medias: independientes y pareadas **[t]**
    - Sobre proporciones **[z]**
    - Sobre varianzas **[χ², F]**
    - Bondad de ajuste e independencia **[χ²]**
  - Significancia estadística ≠ relevancia práctica `070-significancia-vs-relevancia`
    - Tamaño del efecto **[d de Cohen, η²]**
    - Comparaciones múltiples y su corrección **[Bonferroni, FDR]**
- Remuestreo `060-remuestreo`
  - Bootstrap `010-bootstrap`
  - Jackknife
  - Pruebas de permutación `020-permutacion`
  - Validación cruzada como idea inferencial `030-validacion-cruzada`

---

## 070 · Datos multivariados `070-multivariado/`

- Qué es la estadística multivariada `010-que-es`
  - El salto de p = 1 a p > 1: correlación, dimensión y volumen
  - Panorama de técnicas y cuándo usar cada una `010-panorama-tecnicas`
    - Por objetivo: describir, reducir, agrupar, clasificar, predecir
    - Con variable respuesta (dependencia) vs. sin ella (interdependencia)
  - La maldición de la dimensionalidad `020-maldicion-dimensionalidad`
- Organización de los datos `020-organizacion`
  - Matriz de datos `010-matriz-datos` **[X (n×p)]**
  - Fila = observación en ℝᵖ, columna = variable en ℝⁿ
  - Centrado y estandarización `020-centrado-estandarizacion` **[Z = HX D^{−1/2}]**
- Estadísticas descriptivas multivariadas `030-estadisticas`
  - Vector de medias `010-vector-medias` **[x̄ (p×1)]**
    - Centroide de la nube de puntos
  - Matriz de varianzas y covarianzas `020-matriz-covarianzas` **[S, Σ]**
    - Cálculo manual y forma matricial **[S = (1/(n−1))XᵀHX]**
    - Simetría y semidefinitud positiva
  - Matriz de correlación `030-matriz-correlacion` **[R]**
    - Relación con S vía la matriz diagonal de desviaciones
  - Varianza generalizada `040-varianza-generalizada` **[|S|]**
  - Varianza total `050-varianza-total` **[tr(S)]**
- Geometría de los datos multivariados `040-geometria`
  - La nube de puntos y su forma
  - Estructuras de correlación y su efecto en la nube `010-estructuras-correlacion`
    - Independencia, correlación positiva, negativa, colinealidad
  - Elipsoide de concentración `020-elipsoide` **[(x−x̄)ᵀS⁻¹(x−x̄) = c²]**
  - Ejes principales del elipsoide **[λᵢ, vᵢ]**
- Distancias y similitudes `050-distancias`
  - Propiedades de una métrica **[d(x,y) ≥ 0, simetría, desigualdad triangular]**
  - Distancia euclidiana `010-euclidiana` **[d₂]**
  - Distancia de Manhattan y de Minkowski `020-minkowski` **[d₁, d_q]**
  - Distancia de Mahalanobis `030-mahalanobis` **[d²(x,μ) = (x−μ)ᵀΣ⁻¹(x−μ)]**
    - Por qué escala y decorrela; su papel en la detección de atípicos
  - Distancias para variables categóricas y binarias `040-categoricas` **[Jaccard, Gower]**
  - Similitud coseno y correlación como similitud
- Visualización multivariada `060-visualizacion`
  - Matriz de dispersión (pairs) `010-matriz-dispersion`
  - Mapa de calor de la matriz de correlación `020-heatmap-correlacion`
  - Coordenadas paralelas `030-coordenadas-paralelas`
  - Caras de Chernoff, estrellas y perfiles
  - Superficie y curvas de nivel de una densidad bivariada `040-densidad-3d`

---

## 080 · Normal multivariada e inferencia sobre μ `080-normal-multivariada/`

- De la normal univariada a la multivariada `010-de-uni-a-multi`
  - El exponente escalar se vuelve forma cuadrática **[(x−μ)ᵀΣ⁻¹(x−μ)]**
- Modelo matemático `020-modelo` **[X ~ N_p(μ, Σ)]**
  - Parámetros: vector de medias y matriz de covarianzas `010-parametros` **[μ, Σ]**
  - Función de densidad multivariada `020-densidad-multivariada`
  - Constante de normalización y el papel de |Σ| **[(2π)^{−p/2}|Σ|^{−1/2}]**
  - Caso p = 2: densidad, superficie y curvas de nivel `030-caso-bivariado`
  - Contornos elípticos y estructura de correlación `040-contornos`
- Propiedades `030-propiedades`
  - Marginales de una normal multivariada son normales `010-marginales`
  - Condicionales son normales; la media condicional es lineal `020-condicionales` **[E(X₁|X₂)]**
  - Combinaciones lineales son normales `030-combinaciones-lineales` **[aᵀX ~ N]**
  - Incorrelación ⟺ independencia (solo bajo normalidad) `040-incorrelacion-independencia`
  - Forma cuadrática y ji-cuadrado `050-forma-cuadratica` **[(X−μ)ᵀΣ⁻¹(X−μ) ~ χ²_p]**
- Estimación bajo normalidad multivariada `040-estimacion`
  - Máxima verosimilitud de μ y Σ `010-mv-multivariada` **[μ̂ = x̄, Σ̂]**
  - Distribución muestral de x̄ `020-muestral-vector-medias` **[x̄ ~ N_p(μ, Σ/n)]**
  - Distribución de Wishart `030-wishart` **[W_p(n−1, Σ)]**
- Evaluación del supuesto de normalidad multivariada `050-evaluacion-supuesto`
  - Q–Q plot de distancias de Mahalanobis `010-qq-mahalanobis`
  - Normalidad marginal vs. conjunta
  - Detección de atípicos multivariados `020-atipicos-multivariados`
  - Prueba de Mardia (asimetría y curtosis multivariadas)
- Inferencia sobre el vector de medias `060-inferencia-mu`
  - T² de Hotelling para una muestra `010-hotelling-una-muestra` **[T² = n(x̄−μ₀)ᵀS⁻¹(x̄−μ₀)]**
  - Relación entre T² y la F **[T² ~ ((n−1)p/(n−p))F]**
  - Región de confianza elíptica para μ `020-region-confianza`
  - Intervalos simultáneos y de Bonferroni `030-intervalos-simultaneos`
  - T² para dos muestras y matriz combinada `040-hotelling-dos-muestras` **[S_pooled]**
  - Prueba de igualdad de matrices de covarianzas `050-igualdad-covarianzas` **[M de Box]**

---

## 090 · Reducción de dimensionalidad `090-reduccion/`

- Motivación `010-motivacion`
  - Muchas variables correlacionadas ⇒ información redundante
  - Objetivos: resumir, visualizar, descorrelacionar, comprimir
  - Evidenciar el problema multivariado con un ejemplo concreto
- Análisis de componentes principales (ACP) `020-acp`
  - Qué es una componente principal `010-que-es-cp` **[Y₁ = a₁ᵀX]**
  - Las dos lecturas equivalentes `020-dos-lecturas`
    - Máxima varianza proyectada **[máx Var(aᵀX) s.a. ‖a‖ = 1]**
    - Mínimo error de reconstrucción
  - Obtención de los ejes `030-obtencion-ejes`
    - Lagrange sobre la restricción de norma **[ℒ = aᵀSa − λ(aᵀa − 1)]**
    - El problema se vuelve un problema de autovalores **[Sa = λa]**
    - Autovalores = varianzas de las componentes **[Var(Yᵢ) = λᵢ]**
    - Autovectores = direcciones (cargas) **[vᵢ]**
    - Ortogonalidad e incorrelación de las componentes
    - Ejemplo básico calculado a mano `010-ejemplo-manual`
  - Vía SVD y su ventaja numérica `040-acp-svd` **[X = UDVᵀ]**
  - Decisiones prácticas `050-decisiones`
    - ACP sobre S vs. sobre R: el escalamiento de las variables `010-escalamiento` **[S vs. R]**
    - Influencia de los outliers en las componentes `020-outliers`
    - Signo arbitrario de las cargas
  - Cuántas componentes retener `060-numero-componentes`
    - Proporción de varianza explicada `010-varianza-explicada` **[λᵢ/Σλⱼ]**
    - Varianza acumulada y umbral (80–90 %)
    - Gráfico de sedimentación (codo) `020-scree-plot`
    - Criterio de Kaiser **[λᵢ > 1]**
    - Validación cruzada
  - Interpretación de resultados `070-interpretacion`
    - Cargas (loadings) y qué significa una componente `010-cargas`
    - Puntuaciones (scores) de las observaciones `020-scores`
    - Calidad de representación y contribución **[cos², contrib]**
    - Círculo de correlaciones `030-circulo-correlaciones`
    - Biplot: variables y observaciones en el mismo plano `040-biplot`
    - Primer plano factorial como mapa de lectura `050-plano-factorial`
  - Límites del ACP `080-limites`
    - Solo captura estructura lineal
    - Componente con mayor varianza ≠ componente más útil
    - Pérdida de interpretabilidad de las variables originales
- Métodos emparentados `030-emparentados`
  - Análisis factorial `010-analisis-factorial` **[X = ΛF + ε]**
    - Factores comunes, cargas, unicidades y comunalidades
    - Rotación (varimax, oblimin)
    - ACP vs. AF: en qué se diferencian de verdad
  - Escalamiento multidimensional (MDS) `020-mds`
    - Clásico (coordenadas principales) y no métrico
  - Análisis de correlación canónica `030-correlacion-canonica` **[ρ_c]**
  - Reducción no lineal: kernel PCA, t-SNE, UMAP `040-no-lineal`

---

## 100 · Agrupamiento (clustering) `100-agrupamiento/`

- Planteamiento `010-planteamiento`
  - Aprendizaje no supervisado: no hay etiqueta verdadera
  - Qué es un buen grupo: cohesión interna y separación externa
  - El papel decisivo de la distancia y del escalamiento previo `010-preprocesamiento`
- K-medias `020-kmeans`
  - Idea: centroides y asignación al más cercano `010-idea` **[μ_k]**
  - Medición de la calidad de la partición `020-calidad-particion`
    - Suma de cuadrados intra-grupo **[W = Σ_k Σ_{i∈C_k} ‖xᵢ − μ_k‖²]**
    - Suma de cuadrados entre grupos **[B]**
    - Descomposición de la inercia total `010-inercia` **[T = W + B]**
  - Algoritmo de Lloyd `030-algoritmo`
    - Inicialización de centroides
    - Paso de asignación
    - Paso de actualización
    - Criterio de parada y convergencia a óptimo local
  - K-means en más de dos dimensiones y su lectura en el plano factorial `040-alta-dimension`
  - Sensibilidad a la inicialización y `nstart` `050-inicializacion` **[k-means++]**
  - Selección de K `060-seleccion-k`
    - Guía visual: primer plano factorial `010-guia-visual`
    - Codo sobre la inercia intra-grupo `020-codo` **[W(K)]**
    - Criterio basado en d² y ganancia marginal `030-criterio-d2`
    - Silueta `040-silueta` **[s(i)]**
    - Estadístico gap
  - Supuestos y fallos: grupos esféricos, tamaños similares, sensibilidad a atípicos `070-supuestos`
  - Variantes: K-medoides (PAM), K-modes `080-variantes`
- Agrupamiento jerárquico `030-jerarquico`
  - Aglomerativo (abajo→arriba) vs. divisivo `010-tipos`
  - Matriz de distancias `020-matriz-distancias` **[D (n×n)]**
  - Criterios de enlace `030-enlace`
    - Simple (vecino más cercano)
    - Completo (vecino más lejano)
    - Promedio (UPGMA)
    - Centroide
    - Ward `010-ward` **[mínima pérdida de inercia]**
  - Dendrograma y su lectura `040-dendrograma`
  - Corte del dendrograma para obtener K grupos `050-corte`
  - Coeficiente cofenético y estabilidad `060-cofenetico`
- Otros enfoques `040-otros-enfoques`
  - Basado en densidad: DBSCAN `010-dbscan` **[ε, minPts]**
  - Basado en modelo: mezclas gaussianas y EM `020-mezclas-gaussianas` **[GMM]**
  - Agrupamiento espectral
- Validación de los grupos `050-validacion`
  - Índices internos: silueta, Calinski–Harabasz, Davies–Bouldin `010-indices-internos`
  - Índices externos: Rand ajustado `020-indices-externos` **[ARI]**
  - Estabilidad ante remuestreo
  - Tendencia al agrupamiento: ¿hay grupos siquiera? **[estadístico de Hopkins]**
  - Caracterización e interpretación sustantiva de los grupos `030-caracterizacion`
- Correlación espacial y dependencia entre observaciones `060-correlacion-espacial` **[I de Moran]**

---

## 110 · Clasificación `110-clasificacion/`

Puente natural desde el agrupamiento: aquí sí hay etiqueta conocida.

- Marco `010-marco`
  - Supervisado vs. no supervisado
  - Clases, predictores y regla de decisión `010-regla-decision` **[δ(x)]**
  - Costos de mala clasificación y probabilidades previas `020-costos-previas` **[π_k]**
- Clasificadores basados en distribución `020-basados-distribucion`
  - Regla de Bayes óptima `010-regla-bayes` **[P(k|x) ∝ π_k f_k(x)]**
  - Análisis discriminante lineal `020-lda` **[Σ común]**
    - Función discriminante de Fisher `010-fisher` **[máx separación entre/dentro]**
    - Frontera lineal y su geometría
  - Análisis discriminante cuadrático `030-qda` **[Σ_k distintas]**
  - Naive Bayes `040-naive-bayes`
- Clasificadores basados en regresión `030-basados-regresion`
  - Regresión logística `010-logistica` **[logit(p) = Xβ]**
    - Función logística y odds ratio **[OR = e^β]**
    - Estimación por máxima verosimilitud
  - Regresión logística multinomial y ordinal `020-multinomial`
- Clasificadores no paramétricos `040-no-parametricos`
  - K vecinos más cercanos `010-knn` **[k-NN]**
  - Árboles de clasificación `020-arboles`
  - Ensambles: bagging, random forest, boosting `030-ensambles`
  - Máquinas de soporte vectorial `040-svm`
- Evaluación del desempeño `050-evaluacion`
  - Matriz de confusión `010-matriz-confusion` **[VP, FP, VN, FN]**
  - Exactitud, sensibilidad, especificidad, precisión `020-metricas` **[Acc, Sen, Esp, VPP]**
  - Curva ROC y área bajo la curva `030-roc` **[AUC]**
  - Desbalance de clases y sus trampas `040-desbalance`
  - Validación cruzada y error de generalización `050-validacion-cruzada`
  - Sobreajuste y el compromiso sesgo–varianza `060-sesgo-varianza`

---

## 120 · Regresión lineal `120-regresion/`

- Propósito y motivación `010-motivacion`
  - Describir, explicar y predecir: tres objetivos distintos
  - Variable respuesta y variables explicativas `010-respuesta-explicativas` **[Y, X]**
  - Relación determinística vs. estadística
- Metodología del modelamiento `020-metodologia`
  - Identificación `010-identificacion`
  - Estimación `020-estimacion`
  - Validación `030-validacion`
  - Uso `040-uso`
- Regresión lineal simple `030-simple`
  - Modelo poblacional `010-modelo` **[Y = β₀ + β₁X + ε]**
  - Interpretación de intercepto y pendiente `020-interpretacion-coeficientes` **[β₀, β₁]**
  - Estimación por mínimos cuadrados `030-mco`
    - Criterio: minimizar la suma de cuadrados de los residuos **[mín Σeᵢ²]**
    - Ecuaciones normales y solución cerrada `010-ecuaciones-normales` **[β̂₁ = S_{xy}/S_{xx}]**
    - Motivación geométrica: proyección ortogonal `020-geometria`
  - Propiedades de los estimadores MCO `040-propiedades-mco`
    - Insesgadez y teorema de Gauss–Markov **[BLUE]**
    - Error estándar de los coeficientes **[SE(β̂)]**
  - Modelo ajustado, valores predichos y residuos `050-ajustado-residuos` **[ŷᵢ, eᵢ = yᵢ − ŷᵢ]**
  - Descomposición de la variabilidad `060-descomposicion` **[SCT = SCR + SCE]**
  - Coeficiente de determinación `070-r2` **[R²]**
    - Qué mide, qué no mide, y por qué siempre sube al agregar variables
  - Inferencia sobre los coeficientes `080-inferencia-coeficientes`
    - Prueba t sobre β₁ **[H₀: β₁ = 0]**
    - Intervalo de confianza para β₁
    - Significancia global del modelo **[F]**
    - Simulación para evaluar la significancia `010-simulacion`
  - Predicción `090-prediccion`
    - Intervalo de confianza para la media condicional **[E(Y|x₀)]**
    - Intervalo de predicción para una nueva observación **[ŷ₀]**
    - El peligro de extrapolar
- Regresión lineal múltiple `040-multiple`
  - Modelo en forma matricial `010-modelo-matricial` **[Y = Xβ + ε]**
  - Estimador MCO matricial `020-estimador-matricial` **[β̂ = (XᵀX)⁻¹XᵀY]**
  - Matriz sombrero y valores predichos `030-matriz-sombrero` **[H = X(XᵀX)⁻¹Xᵀ]**
  - Interpretación *ceteris paribus* de cada coeficiente `040-interpretacion`
  - R² ajustado `050-r2-ajustado` **[R̄²]**
  - Prueba F global y pruebas parciales `060-pruebas-f` **[F, F parcial]**
  - Variables explicativas categóricas `070-categoricas`
    - Variables indicadoras (dummies) `010-dummies` **[D ∈ {0,1}]**
    - Categoría de referencia y la trampa de la dummy
  - Interacciones y términos polinómicos `080-interacciones` **[X₁X₂, X²]**
  - Transformaciones de variables `090-transformaciones` **[log, √, Box–Cox]**
- Supuestos y diagnóstico `050-diagnostico`
  - Los supuestos del modelo `010-supuestos`
    - Linealidad
    - Independencia de los errores
    - Homocedasticidad **[Var(ε) = σ²I]**
    - Normalidad de los errores **[ε ~ N(0, σ²)]**
    - Predictores no colineales y medidos sin error
  - Análisis de residuos `020-analisis-residuos`
    - Residuos vs. valores ajustados
    - Q–Q plot de residuos
    - Escala–localización
    - Residuos estandarizados y estudentizados **[rᵢ]**
  - Heterocedasticidad: detección y remedio `030-heterocedasticidad` **[Breusch–Pagan, White]**
  - Autocorrelación de los errores `040-autocorrelacion` **[Durbin–Watson]**
  - Observaciones influyentes `050-influyentes`
    - Apalancamiento (leverage) **[hᵢᵢ]**
    - Distancia de Cook **[Dᵢ]**
    - DFFITS y DFBETAS
  - Multicolinealidad `060-multicolinealidad`
    - Síntomas: signos absurdos, errores estándar inflados
    - Factor de inflación de la varianza `010-vif` **[VIF]**
    - Número de condición y correlación entre predictores
    - Remedios: eliminar, combinar, usar componentes principales, regularizar
- Selección de modelos `060-seleccion`
  - Criterios de información `010-criterios` **[AIC, BIC]**
  - Selección paso a paso: adelante, atrás, mixta `020-stepwise`
  - Validación cruzada para selección `030-cv`
  - Parsimonia y el riesgo del dragado de datos (p-hacking)
- Extensiones `070-extensiones`
  - Regresión regularizada `010-regularizacion`
    - Ridge **[L², λΣβ²]**
    - Lasso **[L¹, λΣ|β|]**
    - Elastic net
  - Regresión con componentes principales y PLS `020-pcr-pls`
  - Modelos lineales generalizados `030-glm` **[g(μ) = Xβ]**
  - Regresión robusta y cuantílica `040-robusta`
  - Regresión no paramétrica: LOESS y splines `050-no-parametrica`
  - Regresión multivariada (respuesta vectorial) `060-multivariada` **[Y (n×m)]**

---

## 130 · Análisis de varianza `130-anova/`

- Planteamiento `010-planteamiento`
  - Comparar más de dos medias: por qué no sirven múltiples pruebas t `010-problema-multiple`
  - Factor, niveles (tratamientos) y unidades experimentales `020-factor-niveles`
  - Variabilidad entre grupos vs. dentro de grupos: la idea central `030-idea-central`
- Herramientas previas `020-herramientas`
  - Grados de libertad: qué son realmente `010-grados-libertad` **[gl]**
  - Cuadrados medios como varianzas estimadas `020-cuadrados-medios` **[CM = SC/gl]**
  - Estadístico F como razón de varianzas `030-estadistico-f` **[F = CME/CMD]**
  - Distribución F bajo H₀ y región de rechazo
- ANOVA a una vía `030-una-via`
  - Modelo de medias y modelo de efectos `010-modelo` **[yᵢⱼ = μ + τᵢ + εᵢⱼ]**
  - Hipótesis **[H₀: μ₁ = μ₂ = … = μ_k]**
  - Descomposición de la suma de cuadrados `020-descomposicion` **[SCT = SCE + SCD]**
  - Tabla ANOVA `030-tabla-anova` **[Fuente, SC, gl, CM, F, p]**
  - Analogía con la regresión lineal `040-analogia-regresion`
    - ANOVA como regresión con predictores indicadores
    - Ajuste del modelo con variable categórica `010-ajuste-categorica`
  - Resumen de la variabilidad observada y su lectura `050-lectura-variabilidad`
  - Medidas de tamaño del efecto `060-tamano-efecto` **[η², ω²]**
- Supuestos y verificación `040-supuestos`
  - Independencia de las observaciones
  - Normalidad dentro de cada grupo `010-normalidad`
  - Homocedasticidad entre grupos `020-homocedasticidad` **[Levene, Bartlett]**
  - Robustez del ANOVA ante violaciones; diseños balanceados
  - Alternativas no paramétricas `030-no-parametricas` **[Kruskal–Wallis, Welch]**
- Comparaciones múltiples `050-comparaciones-multiples`
  - El problema de la tasa de error por familia `010-error-familia` **[FWER]**
  - Tukey HSD `020-tukey`
  - Bonferroni, Scheffé, Dunnett `030-otros-metodos`
  - Contrastes planeados vs. exploratorios `040-contrastes`
- Diseños con más estructura `060-disenos`
  - ANOVA a dos vías `010-dos-vias` **[yᵢⱼₖ = μ + αᵢ + βⱼ + (αβ)ᵢⱼ + ε]**
    - Efectos principales
    - Interacción y su gráfico `010-interaccion`
  - Bloques completos al azar `020-bloques`
  - Cuadrado latino y diseños factoriales `030-factoriales`
  - Efectos fijos vs. aleatorios; modelos mixtos `040-efectos-aleatorios`
  - Medidas repetidas `050-medidas-repetidas`
  - ANCOVA: covariables continuas `060-ancova`
- MANOVA `070-manova`
  - Respuesta multivariada y por qué no basta un ANOVA por variable `010-motivacion`
  - Descomposición matricial de la variabilidad `020-descomposicion-matricial` **[H, E]**
  - Estadísticos de prueba `030-estadisticos` **[Λ de Wilks, traza de Pillai, Lawley–Hotelling, Roy]**
  - Supuestos: normalidad multivariada e igualdad de matrices de covarianzas
  - Seguimiento: ANOVAs univariados y análisis discriminante

---

## 140 · Tablas de contingencia y correspondencias `140-contingencia/`

- Datos categóricos cruzados `010-datos-categoricos`
  - Tabla de contingencia r×c `010-tabla` **[nᵢⱼ]**
  - Frecuencias observadas y esperadas `020-esperadas` **[eᵢⱼ = nᵢ₊n₊ⱼ/n]**
  - Perfiles fila, perfiles columna y perfil medio `030-perfiles`
- Inferencia sobre independencia `020-independencia`
  - Prueba ji-cuadrado de independencia `010-chi-cuadrado` **[χ² = Σ(o−e)²/e]**
  - Prueba de homogeneidad y prueba de bondad de ajuste `020-homogeneidad-bondad`
  - Residuos estandarizados: dónde está la asociación `030-residuos`
  - Prueba exacta de Fisher (muestras pequeñas) `040-fisher`
  - Medidas de asociación `050-medidas` **[V de Cramér, φ, OR]**
- Análisis de correspondencias `030-correspondencias`
  - Distancia ji-cuadrado entre perfiles `010-distancia-chi` **[d_χ²]**
  - Inercia y su descomposición `020-inercia` **[Φ² = χ²/n]**
  - Coordenadas fila y columna, y la propiedad baricéntrica `030-coordenadas`
  - Mapa factorial conjunto y su interpretación `040-mapa-factorial`
  - Análisis de correspondencias múltiple `050-acm` **[ACM]**
- Modelos para conteos `040-modelos-conteos`
  - Regresión de Poisson `010-poisson`
  - Modelos log-lineales `020-log-lineales`

---

## 150 · Hacia dónde sigue `150-extensiones/`

Punteros, no desarrollo. Marcan los bordes del mapa para saber que existen.

- Inferencia bayesiana `010-bayesiana` **[p(θ|x) ∝ p(x|θ)p(θ)]**
- Estadística no paramétrica y libre de distribución `020-no-parametrica`
- Series de tiempo `030-series-tiempo` **[ARIMA]**
- Análisis de supervivencia `040-supervivencia` **[S(t)]**
- Diseño de experimentos `050-diseno-experimentos`
- Inferencia causal `060-causalidad` **[do(x)]**
- Datos funcionales `070-datos-funcionales`
- Aprendizaje estadístico y modelos predictivos `080-aprendizaje-estadistico`
- Datos no estructurados: texto, imagen, redes `090-no-estructurados`
