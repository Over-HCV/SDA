# SDA Lab — esquema del aplicativo

Vista en anchura completa de `learn/`: qué existe en cada pantalla, qué acciones
ofrece, qué diagramas muestra y qué datos cruzan de una fase a la siguiente.

Documento de diseño. **Sin código implementado** — revisar y se ajusta antes
de implementar.

---

## 0 · Premisas

### 0.1 Principio rector

> Feedback-loop closure efectivo: **entrada → proceso → resultado**
> visibles al mismo tiempo, en la misma pantalla, sin scroll y sin recargar.

Esto no es un adorno de UX: es la **invariante de layout** de toda la app. Cada vista de método tiene tres zonas simultáneas. Si un cambio de input no mueve algo visible en menos de un segundo, la vista está mal diseñada.

```
┌─ ENTRADAS ────────┬─ PROCESOS ─────────────┬─ RESULTADOS ──────────────┐
│ controles         │ qué está calculando   │ gráficos + métricas         │
│ (sliders, selects)│ ahora mismo:          │ que cambian al mover       │
│                   │ fórmula, paso del     │ un control                 │
│                   │ algoritmo, iteración  │ (why is important)         │
│                   │ el por qué es útil    │                            │
└───────────────────┴───────────────────────┴────────────────────────────┘
```

### 0.2 Las 4 fases y una traducción

Tus 4 fases se conservan como columna vertebral. La fase 3 se renombra:

| Tu nombre | Nombre en la app | Por qué |
|---|---|---|
| Knowledge | **1 · Datos** | Todo lo que se le hace a los datos, en orden |
| Modeling | **2 · Modelado** | Especificar la familia de hipótesis y sus hiperparámetros |
| Setup  | **3 · Ajuste** | No training pues en `prcomp`/`lm`/`aov` no hay épocas |
| Evaluation | **4 · Evaluación** | Componer los tres anteriores, correr y analizar |

**Importante.** Barra de progreso, curva de pérdida,
decaimiento, épocas. En estadística multivariada clásica se llama **iteración del optimizador**. Sí es observable:

| Método | Optimizador real | Qué desciende | Hiperparámetro vivo |
|---|---|---|---|
| k-medias | Lloyd | inercia intra-grupo `W` | inicialización, `nstart` |
| GMM | EM | log-verosimilitud (sube) | tolerancia, `k` |
| LASSO / Ridge | descenso por coordenadas | desviación penalizada | `λ`, `α` |
| Reg. logística | IRLS / Newton–Raphson | log-verosimilitud | tolerancia, `maxit` |
| PCA | iteración de potencia / SVD | error de reconstrucción | nº de componentes |
| MDS no métrico | SMACOF | *stress* | dimensiones, iteraciones |
| Box–Cox | perfil de verosimilitud | −loglik(λ) | rango de `λ` |

Todos tienen traza de convergencia, todos tienen barra de progreso honesta, y
todos permiten la pregunta pedagógica de oro: *¿por qué se detuvo aquí y no
allá?* El nodo `070-optimizacion/030-metodos-iterativos` de `notes/tree.md` ya
reserva ese lugar en el árbol.

Las redes neuronales (con Adam, épocas y decaimiento literales) **aparecen en el
catálogo pero deshabilitadas** — ver §6.

### 0.3 Contexto del repo

`learn/` no arranca de cero. Reutiliza lo que ya existe:

| Se reutiliza | De dónde | Para qué |
|---|---|---|
| `cargar_charcoal()`, `pivot_paises()`, `gen_sintetico()` | `libs/_comun/R/datos.R` | fuentes de la fase 1 |
| `listar_temas()`, `cambiar_tema()`, `retro.scss` | `libs/_comun/R/temas_bslib.R` | selector de tema del navbar |
| `verificar_html()` (chromote) | `libs/_comun/R/pruebas_web.R` | spec S2b: verificación en navegador |
| Galería de componentes `gal_*.R` | `libs/shiny/R/` | sección Referencia |
| `construir_bundle()` | `libs/shiny-live/build.R` | salida wasm |
| Patrón `modelo.R` puro + `run_headless.R` | `projects/_template/` | cada plugin de método |
| Routing de 33 temas | `libs/topics-map.md` | poblar el catálogo |
| Árbol de 15 macro-temas con slugs | `notes/tree.md` | anclas teóricas de cada ficha |

Invariantes heredadas de `libs/sdd.md`: lógica pura sin `input`/`reactive`
(S1), contrato headless con JSON+CSV+log (S2), verificación de consola y DOM
(S2b), `renv` único (S3), identificadores español ASCII y UI con tildes (S4).

---

## 1 · Mapa del sitio

```
SDA Lab
│
├─ ⌂  Inicio ....................... mapa del curso, progreso, atajos
│
├─ ①  Datos ........................ Knowledge
│     ├─ Fuente ................... cargar / elegir / generar
│     ├─ Diccionario .............. qué es cada columna, escala, rol
│     ├─ Calidad .................. faltantes, atípicos, duplicados, tipos
│     ├─ Transformación ........... centrar, escalar, log, Box–Cox, dummies
│     ├─ Partición ................ train/test, k-fold, estratificación
│     ├─ Balanceo ................. sub/sobre-muestreo, SMOTE, bootstrap
│     └─ ▣ Análisis ............... univariado · bivariado · multivariado
│
├─ ②  Modelado .................... Modeling
│     ├─ Catálogo ................. los 33+ métodos, filtrables
│     ├─ Especificación ........... fórmula / variables / estructura
│     ├─ Supuestos ................ qué exige el método, verificado en vivo
│     ├─ Hiperparámetros .......... los del modelo (no los del ajuste)
│     └─ ▣ Análisis ............... geometría del modelo ANTES de ajustar
│
├─ ③  Ajuste ....................... Training / Estimación
│     ├─ Optimizador .............. método, tolerancia, iteraciones, semilla
│     ├─ Control .................. paso, decaimiento, criterio de parada
│     ├─ Consola .................. barra de progreso + log live/realtime
│     └─ ▣ Análisis ............... convergencia · trayectoria · estabilidad
│
├─ ④  Evaluación ................... Evaluation
│     ├─ Composición .............. Dataset × Modelo × Receta → Corrida
│     ├─ Desempeño ................ métricas según el tipo de tarea
│     ├─ Diagnóstico .............. residuos, supuestos a posteriori
│     ├─ Explicabilidad ........... importancia, PDP/ICE, LIME, SHAP
│     ├─ Comparación .............. corrida A vs. B vs. C
│     └─ ▣ Análisis ............... el informe compuesto, exportable
│
├─ ⚙  Objetos ...................... CRUD transversal
│     └─ Datasets · Modelos · Recetas · Ejecuciones
│
└─ ⓘ  Referencia ................... glosario · árbol de temas · galería · tema
```

**▣ Análisis** es una subsección real, no un adorno: es el lugar donde la fase
deja de configurarse y empieza a *mirarse*.

---

## 2 · Las cuatro piezas que se componen

El corazón del diseño. Cuatro objetos con CRUD independiente que la fase 4
combina. Una **Corrida** es lo único que produce resultados.

```
   ┌──────────┐   ┌──────────┐   ┌──────────┐
   │ DATASET  │   │  MODELO  │   │  RECETA  │
   │  fase 1  │   │  fase 2  │   │  fase 3  │
   └────┬─────┘   └────┬─────┘   └────┬─────┘
        └──────────────┼──────────────┘
                       ▼
                 ┌───────────┐
                 │  CORRIDA  │   fase 4
                 │  (fit +    │
                 │  métricas)│
                 └───────────┘
```

### Contratos

| Objeto | Campos | Producido en |
|---|---|---|
| **Dataset** | `id`, `nombre`, `fuente`, `df`, `diccionario[]`, `transformaciones[]`, `particion`, `balanceo`, `semilla` | Fase 1 |
| **Modelo** | `id`, `metodo` (clave del catálogo), `spec` (fórmula/vars), `hiper{}` | Fase 2 |
| **Receta** | `id`, `optimizador`, `control{tol, maxit, paso, decaimiento}`, `cv{}`, `semilla` | Fase 3 |
| **Corrida** | `id`, `dataset_id`, `modelo_id`, `receta_id`, `fit`, `traza[]`, `metricas{}`, `duracion`, `estado` | Fase 4 |

`diccionario[]` es la pieza que casi nadie modela y que aquí es de primera
clase — una fila por columna:

```
{ columna, etiqueta, descripcion, escala, clase, rol, unidad, faltantes_pct }
   escala ∈ {nominal, ordinal, intervalo, razon}       ← notes/tree.md 020/020/010
   clase  ∈ {cualitativa, discreta, continua}
   rol    ∈ {respuesta, predictor, id, grupo, peso, ignorar}
```

**Por qué importa**: la escala decide qué gráfico y qué operación tienen
sentido. La app usa el diccionario para *filtrar la UI*: si marcás una columna
como nominal, el selector de "media" se deshabilita y aparece "moda", con la
razón escrita al lado.

Los objetos se serializan al contrato S2 de `libs/sdd.md`, así que una corrida
hecha en la UI y una hecha por `Rscript run_headless.R` producen el mismo JSON.

---

## 3 · Wireframes por vista

Ancho de referencia ≥ 1280 px. Debajo de 992 px las tres columnas se apilan
Entradas → Resultado → Proceso.

### ⌂ Inicio

```
┌──────────────────────────────────────────────────────────────────────────┐
│ SDA Lab            ⌂  ① Datos  ② Modelo  ③ Ajuste  ④ Evaluación   🎨 ⚙ ⓘ│
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─ Estado de la sesión ──────────┐  ┌─ Ruta sugerida ─────────────────┐ │
│  │ Dataset  charcoal · 35115×5  ✓ │  │ 1. Cargá twins                  │ │
│  │ Modelo   — sin definir       ○ │  │ 2. Marcá DLHRWAGE como respuesta│ │
│  │ Receta   por defecto         ✓ │  │ 3. Elegí LASSO en el catálogo   │ │
│  │ Corridas 3 guardadas           │  │ 4. Mové λ y mirá los ceros      │ │
│  └────────────────────────────────┘  └─────────────────────────────────┘ │
│                                                                          │
│  ┌─ Mapa del curso ─────────────────────────────────────────────────────┐│
│  │  Sesión 1–2 ▓▓▓▓▓▓▓░░  Herramientas básicas      → 5 métodos  3 list.││
│  │  Sesión 3   ▓▓▓░░░░░░  Normal multivariada       → 5 métodos  1 list.││
│  │  Sesión 4   ▓░░░░░░░░  ACP                       → 7 métodos  0 list.││
│  │  Sesión 5   ░░░░░░░░░  Clustering                → 5 métodos  0 list.││
│  │  Sesión 6–7 ▓▓▓▓░░░░░  Regresión múltiple        → 5 métodos  1 list.││
│  │  Sesión 8   ░░░░░░░░░  ANOVA a una vía           → 5 métodos  0 list.││
│  │  (cada barra enlaza al catálogo filtrado por ese macro-tema)          ││
│  └──────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  ┌─ Últimas corridas ───────────────────────────────────────────────────┐│
│  │ #12 twins · lasso · λ=0.04    R²=0.31  12:04  [abrir] [clonar] [🗑]  ││
│  │ #11 piv   · kmeans · k=4      sil=0.52 11:47  [abrir] [clonar] [🗑]  ││
│  └──────────────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────┘
```

**Acciones**: abrir ruta sugerida · saltar a cualquier fase · restaurar corrida ·
importar/exportar sesión (JSON) · cambiar tema.
**Diagramas**: barras de progreso por sesión del curso.

---

### ① Datos

Sidebar de subsecciones a la izquierda; el panel central cambia. La franja
inferior **"Estado del dataset"** es persistente en todas las subsecciones: es
el feedback-loop de la fase. Dar clic en la sección denotada [① DATOS] retorna a la vista principal anterior (aplica a todas las secciones o en subsecciones).

```
┌──────────────────────────────────────────────────────────────────────────┐
│ ① DATOS   ▸Fuente  Diccionario  Calidad  Transformación  Partición  ▣Anál│
├───────────────────┬──────────────────────────────────────────────────────┤
│ FUENTE            │  Vista previa                          [DT, 10 filas]│
│ ○ Del curso       │ ┌──────────────────────────────────────────────────┐ │
│   ◉ charcoal      │ │ Country_Area │ Commodity │ Year │ Unit │ Quantity│ │
│   ○ twins         │ │ Afghanistan  │ Charcoal  │ 1990 │  m3  │  12000  │ │
│   ○ topics-tf     │ │ …                                                │ │
│ ○ Sintético       │ └──────────────────────────────────────────────────┘ │
│   tipo: [anova ▾] │                                                      │
│   n:    ──●───    │  ┌─ ¿Por qué esta subsección? ────────────────────┐  │
│   efecto:──●──    │  │ Un método no se aplica a "datos": se aplica a  │  │
│   semilla: 42     │  │ una matriz X (n×p) con roles definidos. Antes  │  │
│ ○ Subir archivo   │  │ de eso no hay estadística, hay un archivo.     │  │
│   [Examinar…]     │  │ → notes/tree.md 020/030 · 070/020              │  │
│                   │  └────────────────────────────────────────────────┘  │
│ [Cargar]          │                                                      │
├───────────────────┴──────────────────────────────────────────────────────┤
│ ESTADO  n=35115  p=5  faltantes 0.4%  numéricas 2  categóricas 3         │
│         partición: ninguna · balanceo: ninguno · transformaciones: 0      │
└──────────────────────────────────────────────────────────────────────────┘
```

| Subsección | Acciones | Salida visible en vivo |
|---|---|---|
| **Fuente** | elegir del curso · generar sintético (tipo, n, efecto, semilla) · subir CSV (delimitador, decimal, encoding, símbolo de NA) | vista previa DT + franja de estado |
| **Diccionario** | editar por fila: etiqueta, descripción, escala, clase, rol, unidad · autodetección con revisión manual | tabla editable + badges de conflicto ("marcaste `Year` como razón; es discreta") |
| **Calidad** | patrón de faltantes (MCAR/MAR/MNAR) · imputar (media, mediana, k-NN, MICE) · duplicados · atípicos (IQR, z, Mahalanobis) · coerción de tipos | matriz de nulidad, mapa de calor de faltantes, tabla de atípicos con su distancia |
| **Transformación** | centrar `H` · escalar · log · √ · Box–Cox (λ con slider) · dummies + categoría de referencia · interacciones · pila ordenada con deshacer | histograma antes/después lado a lado, en vivo |
| **Partición** | holdout con proporción · k-fold · estratificada por columna · semilla | barra apilada de tamaños + tabla de balance por partición |
| **Balanceo** | sub-muestreo · sobre-muestreo · SMOTE · bootstrap · pesos de clase | barras de frecuencia por clase antes/después + nube 2D con los sintéticos marcados |

#### ① ▣ Análisis

Tres pestañas por dimensionalidad, cada gráfico con su ficha de "cómo se lee".

```
┌─ ▣ ANÁLISIS DE DATOS ────────────────────────────────────────────────────┐
│  [Univariado] [Bivariado] [Multivariado]                                 │
├───────────────────┬──────────────────────────────────────────────────────┤
│ Variable  [Qty ▾] │  ┌── Histograma + densidad kernel ─────────────────┐ │
│                   │  │      ▄▆█▇▅▃▂                                     │ │
│ Bins     ──●───   │  │    ▂▄███████▅▃                                   │ │
│          k = 24   │  │  ▁▃█████████████▅▂▁                              │ │
│                   │  └──────────────────────────────────────────────────┘ │
│ Ancho h  ──●───   │  ┌── Boxplot ──────────┐ ┌── Q–Q normal ───────────┐ │
│          0.42     │  │   ├──[▒▒▒|▒▒]──┤ ∘∘ │ │      ⋰⋰⋰                │ │
│                   │  └─────────────────────┘ └─────────────────────────┘ │
│ ☑ densidad        │                                                      │
│ ☑ atípicos        │  ┌─ PROCESO ──────────────────────────────────────┐  │
│ ☐ log en x        │  │ f̂ₕ(x) = (1/nh) Σ K((x−xᵢ)/h)                   │  │
│                   │  │ h=0.42 (Silverman ⇒ 0.51). h chico = ruido;    │  │
│ Agrupar [Unit ▾]  │  │ h grande = borra la bimodalidad. Movelo.       │  │
│                   │  └────────────────────────────────────────────────┘  │
│                   │  x̄ 312.4 │ Me 180.0 │ s 501.2 │ CV 1.60 │ g₁ 2.8    │
└───────────────────┴──────────────────────────────────────────────────────┘
```

| Pestaña | Diagramas | Hook interactivo |
|---|---|---|
| **Univariado** | barras · histograma · densidad kernel · boxplot · violín · beeswarm · Q–Q normal · ojiva | slider de `bins` y de ancho `h`: el mismo dato, dos historias |
| **Bivariado** | dispersión (+ jitter, alfa, hexbin) · densidad conjunta con curvas de nivel · boxplot agrupado · mosaico · tabla de contingencia con residuos estandarizados | selector de par + slider de transparencia; el sobreploteo se ve y se cura |
| **Multivariado** | matriz de dispersión · mapa de calor de `R` (con reordenamiento) · coordenadas paralelas · elipsoide de concentración · Q–Q de distancias de Mahalanobis · superficie de densidad bivariada 3D | multi-select de variables; el elipsoide se deforma con la correlación |

Cada gráfico trae un pie fijo con tres líneas: **qué muestra · qué buscar ·
cuándo engaña**.

---

### ② Modelo

```
┌──────────────────────────────────────────────────────────────────────────┐
│ ② MODELO   ▸Catálogo  Especificación  Supuestos  Hiperparámetros  ▣Anál  │
├──────────────────────────────────────────────────────────────────────────┤
│  Filtros:  Objetivo [todos ▾]  Sesión [todas ▾]  Supervisión [todas ▾]   │
│            ☑ solo ejecutables aquí   Buscar: [__________]                │
│                                                                          │
│  ┌─ Reducir ──────────────┐ ┌─ Agrupar ──────────┐ ┌─ Predecir ────────┐ │
│  │ ▣ ACP           s4 ⚡ │ │ ▣ k-medias   s5 ⚡│ │ ▣ Reg. simple s6 ⚡│ │
│  │ ▣ ACP robusto   s4 ✓  │ │ ▣ Jerárquico s5 ⚡│ │ ▣ Reg. múltip.s6 ⚡│ │
│  │ ▣ Análisis fact.s4 ✓  │ │ ▣ DBSCAN     s5 ✓  │ │ ▣ LASSO/Ridge s6 ⚡│ │
│  │ ▣ MDS           s4 ✓  │ │ ▣ GMM (EM)   s5 ✓  │ │ ▣ Cuantílica  s6 ✓ │ │
│  │ ▣ t-SNE         s4 ✓  │ │ ▣ Espectral  s5 ✓  │ │ ▣ Logística   s6 ⚡│ │
│  │ ▣ UMAP          s4 ✓  │ │ 🔒 DTW series      │ │ 🔒 Bayes (brms)   │ │
│  └────────────────────────┘ └────────────────────┘ └───────────────────┘ │
│  ┌─ Clasificar ───────────┐ ┌─ Contrastar ───────┐ ┌─ Avanzado 🔒 ─────┐ │
│  │ ▣ LDA / QDA     s3 ⚡ │ │ ▣ ANOVA 1 vía s8 ⚡│ │ 🔒 MLP / perceptrón│ │
│  │ ▣ Naive Bayes   s3 ✓  │ │ ▣ Welch/BF    s8 ✓ │ │ 🔒 CNN             │ │
│  │ ▣ k-NN          s3 ⚡ │ │ ▣ MANOVA      s8 ✓ │ │ 🔒 Transformer     │ │
│  │ ▣ Árbol / RF    s3 ✓  │ │ ▣ Tukey HSD   s8 ✓ │ │ 🔒 Modelo fundac.  │ │
│  └────────────────────────┘ └────────────────────┘ └───────────────────┘ │
│                                                                          │
│  ✓ implementado   ⚡ en navegador (wasm)   🔒 no disponible      │
└──────────────────────────────────────────────────────────────────────────┘
```
<!-- Si ejecuta en navegador se subentiende que está implementado, por ende sólo se muestra el rayo -->

Al dar clic en una tarjeta se abre la **ficha del método**, que es la
respuesta a "qué es y por qué es necesaria":

```
┌─ ACP · Análisis de componentes principales ──────────────── [Elegir] ────┐
│ QUÉ ES     Rotación ortogonal de X a ejes ordenados por varianza.        │
│ POR QUÉ    p variables correlacionadas cargan información redundante.    │
│            Sin reducir, no podés ver la nube ni ajustar sin colinealidad.│
│ ENTRADA    matriz numérica n×p, sin faltantes, escalada (decisión: S vs R)│
│ SALIDA     λᵢ (varianzas), vᵢ (cargas), scores, % explicado              │
│ SUPONE     estructura lineal; sensible a atípicos y a la escala          │
│ FALLA SI   la estructura es no lineal (→ kernel PCA, t-SNE, UMAP)        │
│ SE LEE EN  scree plot · círculo de correlaciones · biplot                │
│ TEORÍA     notes/tree.md → 090-reduccion/020-acp                         │
│ EN R       prcomp() · factoextra::fviz_pca_biplot()                      │
└──────────────────────────────────────────────────────────────────────────┘
```

Las tarjetas 🔒 **también abren su ficha** — con las secciones QUÉ ES / POR QUÉ
/ TEORÍA completas y un bloque extra:

```
│ ⛔ NO EJECUTABLE AQUÍ                                                     │
│    Motivo: torch no compila a WebAssembly y el curso no lo cubre.        │
│    Dónde encaja: es la generalización no lineal de la regresión logística│
│    multinomial (110/030/020). Un MLP sin capa oculta ES esa regresión.   │
│    Para explorarlo: Rscript learn/extra/mlp.R                            │
```

| Subsección | Acciones | Feedback en vivo |
|---|---|---|
| **Catálogo** | filtrar por objetivo / sesión / supervisión / ejecutable · buscar · abrir ficha · elegir método | contador "N métodos visibles" + resaltado de los compatibles con el dataset actual |
| **Especificación** | constructor de fórmula (`y ~ x₁ + x₂ + x₁:x₂`) con arrastre de columnas · o selección de bloques X / Y · vista del texto de la fórmula generada | matriz de diseño resultante: dimensiones, rango, nombres de dummies creadas |
| **Supuestos** | checklist específico del método, evaluado **sobre el dataset actual antes de ajustar** | semáforo por supuesto (normalidad, homocedasticidad, colinealidad VIF, tamaño mínimo, escalas) con el gráfico que lo prueba al lado |
| **Hiperparámetros** | solo los del *modelo*, no los del ajuste: `k`, nº de componentes, `α`, tipo de enlace, `ε`/`minPts`, kernel… | previsualización del efecto donde sea barato (ej.: `k` mueve el corte del dendrograma sin recalcular) |

#### ② ▣ Análisis — geometría **antes** de ajustar

Esta es la subsección que pediste que te propusiera. Su tesis: se puede entender
un modelo *sin haberlo ajustado todavía*, y hacerlo primero es lo que evita
tratar al ajuste como una caja negra.

| Vista | Qué muestra | Hook |
|---|---|---|
| **Espacio de hipótesis** | la familia de curvas/fronteras que el modelo *puede* producir, dibujada sobre tus datos | slider de grado / de `k`: mirás el repertorio, no el ajuste |
| **Modelo manual** | vos movés los parámetros a mano (β₀, β₁, centroides) y ves el error subir y bajar | sliders de parámetros → valor de la función objetivo en vivo |
| **Superficie de pérdida** | mapa de calor de la objetivo en 2 parámetros, con el mínimo marcado | selector de qué par de parámetros mirar |
| **Presupuesto de parámetros** | cuántos parámetros vas a estimar vs. cuántas observaciones tenés | se pone rojo cuando `p` se acerca a `n` |
| **Comparador de familias** | el mismo dato bajo 2–3 familias candidatas, sin ajustar | checkbox de familias |
| **Diagnóstico previo** | los mismos supuestos de arriba, en gráficos grandes | — |

El puente pedagógico: en "Modelo manual" el usuario *es* el optimizador. Después
la fase 3 le muestra cómo la máquina hace lo mismo, más rápido.

---

### ③ Ajuste

```
┌──────────────────────────────────────────────────────────────────────────┐
│ ③ AJUSTE   ▸Optimizador  Control  Consola  ▣Análisis                     │
├───────────────────┬──────────────────────────────────────┬───────────────┤
│ OPTIMIZADOR       │  ┌─ Traza de convergencia ─────────┐ │ EN VIVO       │
│ método            │  │ obj                              │ │               │
│  ◉ Lloyd          │  │  █                               │ │ iter    14/50 │
│  ○ MacQueen       │  │  █▄                              │ │ objetivo      │
│  ○ Hartigan-Wong  │  │  █ ▀▄▄                           │ │   1284.7      │
│                   │  │  █    ▀▀▄▄▄▄___                  │ │ Δ objetivo    │
│ inicialización    │  │  └────────────────────── iter    │ │   −0.0004     │
│  ◉ k-means++      │  └──────────────────────────────────┘ │ tol   1e-4    │
│  ○ aleatoria      │  ┌─ Camino en el espacio de params ─┐ │ tiempo  0.8 s │
│  ○ Forgy          │  │        ∘→∘→∘→⊙                   │ │               │
│ nstart  ──●── 25  │  │   contornos de la objetivo       │ │ ESTADO        │
│                   │  └──────────────────────────────────┘ │ ✓ convergió   │
│ CONTROL           │  ┌─ Consola ────────────────────────┐ │   por tol     │
│ máx iter ──●─ 50  │  │ [====================······] 68% │ │               │
│ tolerancia 1e-4   │  │ iter 12  W=1291.3  Δ=-2.1e-3     │ │ [Guardar como │
│ semilla    42     │  │ iter 13  W=1285.9  Δ=-4.2e-3     │ │  receta]      │
│ ☑ registrar traza │  │ iter 14  W=1284.7  Δ=-4.0e-4     │ │ [Guardar como │
│                   │  └──────────────────────────────────┘ │  corrida]     │
│ [▶ Ajustar] [■]   │                                       │               │
├───────────────────┴───────────────────────────────────────┴───────────────┤
│ ⓘ PROCESO  Lloyd alterna dos pasos: asignar cada punto a su centroide más │
│   cercano, y recolocar cada centroide en la media de los suyos. Cada paso │
│   no puede subir W, por eso la curva solo baja. Que baje no garantiza     │
│   óptimo global: por eso nstart>1. Probá inicialización aleatoria y mirá  │
│   cómo la curva se estanca más arriba.                                    │
└──────────────────────────────────────────────────────────────────────────┘
```
<!-- El footer de PROCESO debe poder ser togglable, o contraíble, no es información dinámica por ende se puede esconder -->

| Subsección | Acciones | Diagramas |
|---|---|---|
| **Optimizador** | elegir algoritmo · inicialización · nº de reinicios · (para los que aplican: paso, decaimiento, momento) | descripción del algoritmo paso a paso, resaltando el paso actual mientras corre |
| **Control** | máx. iteraciones · tolerancia · criterio de parada · semilla · registrar traza sí/no · validación cruzada durante el ajuste | — |
| **Consola** | ▶ ajustar · ■ detener · paso a paso (una iteración por clic) · velocidad de reproducción | barra de progreso real, log de iteraciones, cronómetro |

**Modo paso a paso**: el botón que más enseña. Una iteración por clic, con el
gráfico de resultado actualizándose. En k-medias se ven los centroides caminar;
en LASSO se ven los coeficientes tocar cero de a uno.

#### ③ ▣ Análisis — convergencia, trayectoria, estabilidad

| Vista | Qué muestra | Pregunta que responde |
|---|---|---|
| **Curva de convergencia** | objetivo vs. iteración, escala lineal/log | ¿se detuvo por converger o por agotar iteraciones? |
| **Trayectoria de parámetros** | cada coeficiente/centroide vs. iteración | ¿qué parámetro tardó más en estabilizarse? |
| **Camino sobre la superficie** | el recorrido dibujado sobre el mapa de calor de la fase 2 | ¿por dónde bajó y por qué no por el otro lado? |
| **Sensibilidad a la semilla** | N reinicios superpuestos, óptimos alcanzados | ¿es óptimo local o global? |
| **Ruta de regularización** | coeficientes vs. `λ` (LASSO/Ridge), con CV superpuesta | ¿cuándo muere cada variable? |
| **Curva de aprendizaje** | error de train y de validación vs. tamaño de muestra | ¿me faltan datos o me falta modelo? |
| **Costo** | tiempo e iteraciones por configuración | ¿qué me cuesta esa tolerancia extra? |

---

### ④ Evaluación

La composición es explícita: tres selectores arriba, resultado abajo.

```
┌──────────────────────────────────────────────────────────────────────────┐
│ ④ EVALUACIÓN  ▸Composición  Desempeño  Diagnóstico  Explicab.  Comparar  │
├──────────────────────────────────────────────────────────────────────────┤
│  ┌ DATASET ─────────┐ ┌ MODELO ──────────┐ ┌ AJUSTE ─────────┐          │
│  │ twins (post-part)│×│ LASSO α=1        │×│ cd tol1e-7 s=42 │  [▶ Correr]│
│  │ n=146/36  p=15   │ │ y ~ . −HRWAGEL   │ │ 100 λ, cv 10    │  [+ Cola] │
│  └──────────────────┘ └──────────────────┘ └─────────────────┘          │
│  Compatibilidad: ✓ tipos  ✓ supuestos (2 avisos)  ✓ ejecutable en wasm   │
├──────────────────────────────────────────────────────────────────────────┤
│  ┌─ Desempeño ──────────────┐  ┌─ Curva ROC ────────────────────────────┐│
│  │ R²      0.312            │  │      ┌────────────┐                    ││
│  │ RMSE    0.284            │  │      │   ╭────────│  AUC = 0.81        ││
│  │ MAE     0.219            │  │      │ ╭─╯        │                    ││
│  │ vars≠0  6 de 15          │  │      │╱           │                    ││
│  │ λ óptimo 0.041 (1-SE)    │  │      └────────────┘                    ││
│  └──────────────────────────┘  └────────────────────────────────────────┘│
│  ┌─ Matriz de confusión ────┐  ┌─ Residuos vs. ajustados ───────────────┐│
│  │         pred                │  │   ∘ ∘  ∘   ∘                       ││
│  │        0     1              │  │ ──∘──∘───∘────∘──── 0              ││
│  │ real 0 [84]   9             │  │  ∘   ∘  ∘    ∘                     ││
│  │      1  14  [39]            │  └────────────────────────────────────┘│
│  └──────────────────────────┘                                            │
└──────────────────────────────────────────────────────────────────────────┘
```

| Subsección | Acciones | Diagramas |
|---|---|---|
| **Composición** | elegir los 3 objetos · validar compatibilidad · correr · encolar barrido (grid de hiperparámetros) | panel de compatibilidad con avisos accionables |
| **Desempeño** | elegir conjunto (train / test / CV) · umbral de decisión · métrica principal | value boxes · ROC + AUC · precisión-exhaustividad · calibración · matriz de confusión interactiva (clic en celda → ver esos casos) |
| **Diagnóstico** | según el método | residuos vs. ajustados · Q–Q de residuos · escala-localización · leverage y distancia de Cook · VIF · Durbin–Watson · silueta · scree · dendrograma con corte móvil |
| **Explicabilidad** | elegir técnica y observación | importancia por permutación · PDP · ICE · LIME local · SHAP (si el método lo admite) · cargas y círculo de correlaciones · biplot · caracterización de grupos |
| **Comparación** | seleccionar 2+ corridas | tabla de métricas lado a lado · coordenadas paralelas de hiperparámetros vs. métrica · superposición de curvas ROC · diferencias significativas entre corridas |

#### ④ ▣ Análisis — el informe compuesto

Reúne lo mejor de las cuatro fases en un solo documento con narrativa:
**qué datos → qué modelo → cómo se ajustó → qué resultó → qué significa**.

Acciones: exportar a `.Rmd` · a HTML autocontenido · a PDF de diapositivas
(`revealjs`) · a JSON del contrato S2 · copiar el código R equivalente.

> **El exportador a `.Rmd` no es un extra.** La guía del curso (§15) pide
> cuaderno RMD + diapositivas PDF + video. Un informe exportable convierte
> cualquier exploración en la app en el 60 % de un entregable evaluable.

---

### ⚙ Objetos (CRUD transversal)

```
┌─ OBJETOS ────────────────────────────────────────────────────────────────┐
│  [Datasets 4] [Modelos 7] [Recetas 3] [Corridas 12]                      │
├──────────────────────────────────────────────────────────────────────────┤
│ id  nombre              resumen                    creado    acciones    │
│ d3  twins-particionado  146/36 · 15 vars · z-score 11:20  👁 ✎ ⧉ ⤓ 🗑    │
│ d2  charcoal-pivot      145×31 · numérico          10:58  👁 ✎ ⧉ ⤓ 🗑    │
│ m5  lasso-wage          LASSO α=1 · y~.            11:31  👁 ✎ ⧉ ⤓ 🗑    │
│ r1  cd-estricta         tol 1e-7 · cv 10 · s=42    11:33  👁 ✎ ⧉ ⤓ 🗑    │
│ c12 —                   d3 × m5 × r1 · R²=0.312    12:04  👁    ⧉ ⤓ 🗑    │
└──────────────────────────────────────────────────────────────────────────┘
   👁 ver · ✎ editar (te lleva a su fase) · ⧉ clonar · ⤓ exportar JSON · 🗑
```

Todo objeto es exportable e importable. Una sesión entera cabe en un JSON, lo
que permite: compartir un estado con un compañero por un enlace, reproducir una
corrida desde `rscript`, y que el agente verifique la app sin GUI.

---

### ⓘ Referencia

| Pestaña | Contenido |
|---|---|
| **Glosario** | cada símbolo del árbol (`Σ`, `λᵢ`, `H`, `T²`, `Λ`) con definición, dónde aparece y enlace a su nodo |
| **Árbol de temas** | `notes/tree.md` navegable; cada nodo con método implementado lleva un botón "abrir en el lab" |
| **Galería** | los `gal_*.R` de `libs/shiny/R/` — catálogo de componentes bajo el tema activo |
| **Tema** | selector de presets (`flatly`, `retro` 8-bit, …) + `bs_themer()` con `SDA_THEMER=1` |
| **Acerca de** | comandos `Rscript` copiables, versión de R, paquetes cargados, estado wasm/servidor |

---

## 4 · El registro de métodos

Una sola tabla declarativa gobierna el catálogo, los filtros, los candados y
qué entra en el bundle wasm. Añadir un método es añadir una fila y un archivo.

<!-- Quizás el candado se ve feo, simplemente haz que esté desactivado/ más opaco -->

```r
registrar_metodo(
  clave       = "kmeans",
  nombre      = "K-medias",
  objetivo    = "agrupar",              # describir|reducir|agrupar|clasificar|predecir|contrastar
  supervision = "no_supervisado",
  sesion      = 5,                       # sesión del curso (guide-eda-26A.md)
  nodo        = "100-agrupamiento/020-kmeans",   # ancla en notes/tree.md
  estado      = "activo",                # activo | pendiente | bloqueado
  wasm        = TRUE,                    # entra al bundle de GitHub Pages
  deps        = character(0),
  entrada     = list(tipo = "matriz_numerica", min_p = 2, faltantes = FALSE),
  hiper       = list(k = list(tipo="entero", min=2, max=10, def=3)),
  optimizador = list(metodos = c("Lloyd","MacQueen","Hartigan-Wong"),
                     traza = TRUE, paso_a_paso = TRUE),
  supuestos   = c("escalado_previo","grupos_esfericos","tamanos_similares"),
  analisis    = c("scree_inercia","silueta","plano_factorial","dendrograma"),
  ficha       = "learn/fichas/kmeans.md",
  ajustar     = ajustar_kmeans          # función PURA, sin input/reactive (S1)
)
```

Consecuencias directas:

- El **catálogo** se dibuja recorriendo el registro. Cero HTML a mano.
- Los **filtros** son consultas sobre columnas del registro.
- La UI de **hiperparámetros** se genera desde `hiper` (tipo → widget).
- Los **candados** son `estado != "activo"`, con su motivo en la ficha.
- El **bundle wasm** filtra `wasm == TRUE`; el servidor no filtra nada.
- El **checklist de supuestos** de la fase 2 se genera desde `supuestos`.
- Las **pestañas de análisis** de la fase 4 se generan desde `analisis`.
- `run_headless.R` recorre el mismo registro → app y batch nunca divergen (S2).

`libs/topics-map.md` ya trae 33 filas listas para transcribir (datos, deps,
firma de `modelo.R`, módulo UI base, hook reactivo).

---

## 5 · Dos salidas, un código

```
                    learn/R/  (mismo código fuente)
                          │
          ┌───────────────┴────────────────┐
          ▼                                ▼
   BUNDLE WASM                       SERVIDOR R
   shinylive::export()               shiny::runApp()
   filtra wasm == TRUE               registro completo
          │                                │
          ▼                                ▼
   GitHub Pages                      shinyapps.io / local
   cero instalación                  cualquier paquete CRAN
   arranque ~15 s                    arranque inmediato
   ~25 métodos                       los 33+
```

La app **sabe dónde está corriendo** (`Sys.getenv("SDA_MODO")`) y lo dice en el
navbar: `⚡ navegador` o `🖥 servidor`. En modo navegador, los métodos no-wasm
aparecen con candado ⚡ y el texto: *"Este método necesita R completo. Abrilo en
la versión de servidor o corré `Rscript learn/R/run_headless.R`."*

Reutiliza `construir_bundle()` de `libs/shiny-live/build.R`, que ya resolvió el
staging con `data/` y `libs/_comun/` adentro (sin eso el bundle no arranca en
webR — ver los 6 defectos documentados en `libs/shiny-live/AGENT.md`).

---

## 6 · Los métodos bloqueados

Visibles, con ficha completa, sin botón de ejecutar. No son huecos: son el borde
del mapa, y saber que existe un borde es parte de entender el territorio.

| Método | Motivo del candado | Dónde encaja conceptualmente |
|---|---|---|
| Perceptrón / MLP | `torch` no compila a wasm; fuera del temario | generaliza la logística multinomial (110/030/020) |
| CNN | ídem + requiere GPU y datos de imagen | convolución = filtro local con pesos compartidos |
| Transformers | ídem + escala de cómputo | atención = promedio ponderado aprendido |
| Modelos fundacionales | no entrenables en un curso | el borde: 150/090 datos no estructurados |
| Bayes MCMC (`brms`) | `rstan` no compila a wasm; ejecutable solo en servidor | 150/010 inferencia bayesiana |
| Espacial SAR/SEM | requiere shapefile externo | 100/060 correlación espacial |

Cada ficha bloqueada cierra con **"el puente"**: la frase que conecta el método
avanzado con algo que sí se puede correr en la app. Ej.: *"Un MLP sin capa
oculta y con activación sigmoide **es** una regresión logística. Corré la
logística en el lab, después imaginá una capa más."*

---

## 7 · Estructura de archivos propuesta

```
learn/
├─ SCHEMA.md                este documento
├─ README.md                cómo correr (español)
├─ AGENT.md                 comandos exactos + schema de salidas (inglés)
├─ app.R                    wrapper de 9 líneas para shinylive
├─ R/
│  ├─ app.R                 solo cablea: navbar de 4 fases + shell
│  ├─ registro.R            registrar_metodo() + la tabla completa
│  ├─ estado.R              los 4 objetos (Dataset/Modelo/Receta/Corrida) + CRUD
│  ├─ contratos.R           validación de compatibilidad entre objetos
│  ├─ fase1_datos.R         módulo de la fase 1 (subsecciones)
│  ├─ fase1_analisis.R      ▣ Análisis de datos
│  ├─ fase2_modelo.R
│  ├─ fase2_analisis.R
│  ├─ fase3_ajuste.R
│  ├─ fase3_analisis.R
│  ├─ fase4_evaluacion.R
│  ├─ fase4_analisis.R
│  ├─ ui_ficha.R            renderiza una ficha de método desde markdown
│  ├─ ui_generador.R        hiper{} → widgets; el generador de formularios
│  ├─ graficos.R            todos los ggplot, funciones PURAS
│  ├─ run_headless.R        contrato S2: png+json+csv+run_log
│  ├─ test_headless.R       lógica + invariantes por método
│  └─ test_app.R            shinytest2 + consola del navegador (S2b)
├─ metodos/                 un archivo por método, función pura ajustar_*()
│  ├─ kmeans.R
│  ├─ acp.R
│  ├─ lasso.R
│  └─ …
├─ fichas/                  un .md por método (QUÉ ES / POR QUÉ / FALLA SI …)
│  ├─ kmeans.md
│  └─ …
├─ build.R                  export wasm filtrando registro por wasm==TRUE
├─ docs/                    bundle exportado → GitHub Pages
└─ outputs/                 corridas headless (png/json/csv + run_log.csv)
```

Se respeta S1 (`metodos/*.R` y `graficos.R` sin `input`/`reactive`) y el techo
de 300 LOC por archivo — por eso cada fase se parte en módulo + análisis.

---

## 8 · Preguntas abiertas

1. **Persistencia entre sesiones.** ¿Las corridas viven solo en memoria (se
   pierden al recargar) o se guardan? En wasm no hay disco: la opción realista
   es exportar/importar JSON a mano, o `localStorage` vía un pequeño binding JS.
2. **Tamaño del bundle.** Cada dep suma megas al arranque de webR. Puede
   convenir un bundle "núcleo" (base + stats + ggplot2) y bundles por sesión del
   curso, en vez de uno solo con todo.
3. **`charcoal` con 35 115 filas** es lento para gráficos interactivos en wasm.
   ¿Muestreo automático con aviso visible, o precómputo de agregados?
4. **Idioma de la UI.** El repo usa español con tildes en UI e identificadores
   ASCII. Asumo lo mismo aquí. ¿O UI bilingüe, dado que `topics-tf.csv` trae los
   temas en ESP y ENG?
5. **Orden de construcción.** Sugerencia: shell + registro + fase 1 completa
   primero (es la que más se usa y la única que no depende de las otras), luego
   ACP de punta a punta como método de prueba del marco, luego k-medias (valida
   el paso a paso), luego el resto.
