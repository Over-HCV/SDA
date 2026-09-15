<!-- Plan de ejecución de SDA Lab. Los agentes marcan [x] al terminar y añaden
     "> Completado el <YYYY-MM-DD>" al final de su sección (patrón S7 de
     libs/sdd.md). El diseño está en SCHEMA.md; las reglas en CONVENCIONES.md. -->

# Plan de ejecución — SDA Lab

- **Diseño**: `SCHEMA.md` — qué hay en cada pantalla
- **Reglas**: `CONVENCIONES.md` — C1…C14, verificables
- **Índice**: `MAPA.md` — clave → archivos (generado)
- **Máquina**: `AGENT.md` — comandos exactos

---

## Hito 1 — Núcleo + shell desplegado

Al terminar: la app se recorre entera, las 4 fases navegan, el catálogo se
dibuja solo desde el registro, el tema cambia, y está viva en GitHub Pages.
**Cero estadística.**

### E0 · Andamiaje y convenciones

- [x] `CONVENCIONES.md` — C1…C14
- [x] `PLAN.md` — este archivo
- [x] Esqueleto de carpetas
- [x] `README.md` (español) + `AGENT.md` (inglés, comandos exactos)
- [x] `R/cargar.R` — sourcea en orden `nucleo/ → logica/ → graficos/ → ui/`
- [x] `R/nucleo/modo.R` — `modo_ejecucion()` lee `SDA_MODO` → `"wasm"` / `"servidor"`
- [x] `R/pruebas/verificar_loc.R` — exit 1 si algún `.R` pasa de 300 LOC (C2)
- [x] `R/pruebas/verificar_idioma.R` — identificadores nuestros en español ASCII (C1)

### E1 · Núcleo headless (sin UI)

- [x] `R/nucleo/registro.R` — `registrar_metodo()`, `metodos()`, `metodo()`, `filtrar_metodos()`
- [x] `R/nucleo/catalogo/` — 54 métodos en 7 archivos por macro-tema; Hito 1 solo
      metadatos. Fuente: `libs/topics-map.md` + `SCHEMA.md` §6 (6 bloqueados)
- [x] `R/nucleo/estado.R` — constructores + diccionario de columnas
- [x] `R/nucleo/almacen.R` — CRUD puro (devuelve copias, no muta)
- [x] `R/nucleo/contratos.R` — `validar_compatibilidad()` → avisos con severidad
- [x] `R/nucleo/claves.R` — `registrar_artefacto()`, `rutas_de()`, `contexto_de()` (C9)
- [x] `R/nucleo/artefactos/` — 71 artefactos en 2 archivos por fase
- [x] `R/nucleo/textos.R` — `texto(clave)`; si falta el `.md`, aviso discreto (C6)
- [x] `R/nucleo/exportar.R` — JSON · CSV · PNG · RDS · Rmd · MD
- [x] `R/nucleo/informe/corridas.R` — armado del cuaderno `.Rmd`
- [x] `R/mapa.R` + `MAPA.md` generado
- [x] `R/pruebas/verificar_mapa.R` — huérfanos + `MAPA.md` al día + deuda
- [x] `R/pruebas/test_headless.R` — 46 pruebas, sin Shiny

> Completado el 2026-08-13. El núcleo carga con `cargar_sda(con_ui = FALSE)` sin
> bslib ni DT: es la base sobre la que puede montarse una CLI.

### E2 · Piezas de UI reutilizables

Codifica C4, C5 y C7 una sola vez, para que ninguna vista las reinvente.

- [x] `R/ui/piezas/panel.R` — `panel_resultado()`, `plegable()`, `sello_clave()`,
      `salida_contexto()` / `dibujar_contexto()`, `panel_pendiente()`
- [x] `R/ui/piezas/tablas.R` — `tabla_paginada()`, `recortar_para_tabla()`,
      `pie_tabla()`, `salida_tabla()` / `dibujar_tabla()`
- [x] `R/ui/piezas/indicadores.R` — `franja_estado()`, `badge_muestreo()`,
      `badge_estado()`, `badge_modo()`, `barra_progreso()`, `lista_avisos()`
- [x] `R/ui/piezas/tarjetas.R` — `tarjeta_metodo()`, `rejilla_metodos()`
- [x] `R/ui/piezas/fase.R` — `armazon_fase()`, `navegacion_fase()`, `fase_pendiente()`
- [x] `R/ui/ficha.R` — ficha desde `fichas/<clave>.md`, con "el puente" si está bloqueada
- [x] `R/ui/formulario.R` — `hiper{}` → widgets, `valores_hiper()`, `hiper_por_defecto()`
- [x] `fichas/acp.md`, `fichas/kmeans.md`, `fichas/mlp.md` (bloqueada)
- [x] `textos/f1/analisis/histograma.md`, `textos/f3/analisis/convergencia.md`
      (rutas del Hito 2; en el Hito 1 eran planas)

> Completado el 2026-08-13. En su momento se decidió no usar LaTeX en los
> textos, porque `commonmark` no renderiza matemáticas. Eso cambió: hoy se
> escribe LaTeX y se ve como LaTeX, con `nucleo/formulas.R` protegiendo las
> fórmulas del parser y KaTeX vendorizado pintándolas (ver C6 y C10 en
> CONVENCIONES.md).

### E3 · Shell navegable

- [x] `R/app.R` — `page_navbar`: ⌂ ① ② ③ ④ ⚙ ⓘ + tema + badge de modo. Solo cablea
- [x] `R/ui/f0/inicio.R` — estado, mapa del curso, cobertura de textos, corridas
- [x] `R/ui/f2/catalogo.R` + `f2/modelado.R` — **la vista real del hito**
- [x] `R/ui/transversal/objetos.R` — CRUD + exportar/importar sesión
- [x] `R/ui/transversal/referencia.R` — glosario · catálogo · artefactos · entorno
- [x] `R/ui/f1/datos.R`, `f3/ajuste.R`, `f4/evaluacion.R` — pestañas reales, vacías
- [x] `R/nucleo/tema_app.R` — `tema_seguro()`: sin `font_google()` en wasm
- [x] `R/pruebas/test_app.R` — 31 aserciones, cero errores de consola (C14)

> Completado el 2026-08-13.

### E4 · Despliegue día 0

- [x] `app.R` — wrapper con `$value` **y** las librerías declaradas
- [x] `build.R` — staging fuera del repo, `verificar_staging()`,
      `verificar_dependencias()`, `inventario_bundle()`
- [x] Export a `docs/` — 53 archivos, 24 paquetes wasm, app.json 3.0 MB
- [x] `R/pruebas/verificar_bundle.R` — webR real en Chrome headless, aserciones
      positivas dentro del iframe
- [x] GitHub Pages sirviendo `learn/docs/` — `.github/workflows/pages.yml`
      construye el bundle y lo sube como artefacto. Falta un clic humano:
      Settings → Pages → Source = *GitHub Actions*

> Completado el 2026-08-13. La Action de Pages se añadió en el Hito 2; queda
> solo el ajuste del repositorio, que no es código.

### Definición de "hecho" — Hito 1

- [x] `verificar_loc.R` verde — 47 archivos, máximo 188 LOC
- [x] `verificar_idioma.R` verde
- [x] `verificar_mapa.R` verde
- [x] `test_headless.R` verde — 46 pruebas
- [x] `test_app.R` verde — 31 pruebas, consola sin errores
- [x] `verificar_bundle.R` verde — el bundle wasm arranca y pinta
- [x] Cero dependencias nuevas: los 14 paquetes que `learn/` necesita ya estaban
      en `renv.lock`. `renv::status()` reporta 15 paquetes fuera de sincronía
      (tidyverse, plotly, GGally, psych…), pero todos vienen de los cuadernos de
      `notes/SDA/`, no de `learn/`. Comprobar con:
      `Rscript -e 'print(sort(unique(renv::dependencies("learn", quiet=TRUE)$Package)))'`

---

## Hito 2 — Fase 1 completa

Al terminar: se carga un dataset real, se le declara el diccionario, se lo
limpia, transforma, parte y balancea, y se lo mira en univariado, bivariado y
multivariado. Entran las dos invariantes que hasta ahora solo estaban escritas:
el muestreo visible (C8) y la escala de medición gobernando la UI.

### E5 · Lógica pura de la fase 1

- [x] `R/logica/muestreo.R` — `UMBRAL_MUESTREO`, `muestrear_para_grafico()`:
      los gráficos reciben la muestra, las métricas el total (C8)
- [x] `R/logica/resumen_univariado.R` — estadísticos filtrados por escala
- [x] `R/logica/densidad.R` · `normalidad.R` · `asociacion.R` ·
      `contingencia.R` · `distancias.R`
- [x] `R/logica/datos/` — `fuente`, `diccionario`, `calidad`,
      `transformacion`, `particion`, `balanceo` (una carpeta, sin prefijos)
- [x] Cero dependencias nuevas: imputación por media/mediana/moda, atípicos por
      IQR/z/Mahalanobis, balanceo por sub/sobre-muestreo y bootstrap. MICE y
      SMOTE quedan como pendientes del catálogo

### E6 · Gráficos de la fase 1

- [x] `R/graficos/univariado.R` · `bivariado.R` · `multivariado.R` ·
      `calidad.R` · `preparacion.R` — 25 funciones, ggplot puro
- [x] Contra el sobreploteo: transparencia, jitter y conteo por celda
      (`geom_bin2d`, sin traer hexbin)
- [x] Densidad 2D y elipsoide a mano, sin `MASS`

### E7 · Artefactos y textos

- [x] `R/nucleo/artefactos/preparacion.R` — 8 claves nuevas
      (`f1.fuente.*`, `f1.diccionario.*`, `f1.transformacion.*`,
      `f1.particion.*`) y las 3 de preparación que estaban en `exploracion.R`
- [x] Las rutas del registro apuntan a archivos que existen: `R/logica/...`,
      `R/graficos/...`. Antes decían `logica/...` y `MAPA.md` mentía
- [x] `textos/<fase>/<subseccion>/<artefacto>.md` — 24 textos de `f1`, con los
      tres bloques fijos

### E8 · UI de las 7 subsecciones

- [x] `R/ui/f1/` — `datos.R` (cableado) + una subsección por archivo
- [x] `R/ui/f1/analisis/` — `analisis.R` + `univariado.R` · `bivariado.R` ·
      `multivariado.R`
- [x] Controles estáticos con `conditionalPanel` + `update*Input`, no un
      sidebar rendido con `renderUI` (ver la trampa en `AGENT.md`)
- [x] Badge de muestreo, franja de estado persistente y "Guardar en Objetos"

### E9 · Datos y despliegue

- [x] `twins_path()` resuelve `data/` **y** `workshops/twins/`
- [x] `libs/shiny-live/build.R` copia los datos por nombre: ya no falla
- [x] charcoal crudo y pivot, ambos con carga diferida y aviso de peso en wasm
- [x] `.github/workflows/pages.yml`

### E10 · Pruebas

- [x] `R/pruebas/test_fase1.R` — 50 pruebas de lógica y gráficos, sin Shiny
- [x] `test_app.R` — recorrido real de la fase: cargar, transformar, partir,
      balancear, y el badge de muestreo con charcoal crudo

### Definición de "hecho" — Hito 2

- [x] `verificar_loc.R` verde
- [x] `verificar_idioma.R` verde
- [x] `verificar_mapa.R` verde — 79 artefactos, deuda de código 20/44
- [x] `test_headless.R` verde
- [x] `test_fase1.R` verde
- [x] `test_app.R` verde, consola del navegador limpia
- [x] `verificar_bundle.R` verde — el bundle wasm arranca con la fase 1 dentro
- [x] Cero dependencias nuevas

> Completado el 2026-08-13. Pendiente heredado: los métodos de la fase 1 que
> exigirían dependencias nuevas (MICE, k-NN, SMOTE) siguen sin implementar, a
> propósito. Entran cuando se decida pagar el peso en el bundle.

---

## Hito 3 — ACP de punta a punta

Al terminar: se elige ACP en el catálogo, se declara la matriz X, se ve el
semáforo de supuestos, se fija `k` y S-vs-R, se ajusta con **iteración de
potencia real** viendo la traza bajar, se compone Dataset × Modelo × Receta en
una Corrida, y se lee el resultado en scree, cargas, círculo y biplot — con el
mismo JSON que produce `Rscript learn/R/run_headless.R`.

El primer método existente. Lo que valida no es el ACP: es el marco.

### E11 · Lógica pura del método

- [x] `metodos/acp.R` — `ajustar_acp()` con dos optimizadores: `svd`
      (`prcomp`) y `potencia` (iteración de potencia con deflación). Convención
      de signo fija para que coincidan; `test_acp.R` lo comprueba a 1e-6
- [x] `R/logica/traza.R` — `nueva_traza()`, `registrar_iteracion()`,
      `traza_a_tabla()`, `parametros_a_tabla()`, `traza_monotona()`,
      `comparar_reinicios()`. Genérico: k-medias lo reusa sin tocarlo
- [x] `R/logica/metricas_reduccion.R` — `metricas_de_corrida()`,
      `varianza_explicada()`, `cargas()`, `correlaciones_componentes()`,
      `coordenadas_2d()`, `coordenadas_biplot()`, `componentes_sugeridas()`
- [x] `R/logica/modelo_geometria.R` — `familia_candidatas()`,
      `proyectar_en_direccion()`, `evaluar_objetivo()`, `contar_parametros()`,
      `presupuesto_por_k()`, `resumen_matriz_diseno()`
- [x] `R/logica/supuestos.R` — `evaluar_supuestos()` recorre
      `metodo(clave)$supuestos` y devuelve avisos con la forma de `contratos.R`

### E12 · Gráficos

- [x] `R/graficos/modelo.R` · `convergencia.R` · `diagnostico.R` ·
      `explicabilidad.R` — 10 funciones, ggplot puro
- [x] Biplot y círculo de correlaciones a mano: nada de `factoextra`

### E13 · Registro, artefactos y textos

- [x] `acp` pasa a `estado = "activo"` con `ajustar = ajustar_acp` y 12
      artefactos declarados. El optimizador declara `potencia` y `svd`
- [x] Dos claves nuevas: `f2.especificacion.matriz_diseno` y
      `f2.supuestos.semaforo`
- [x] 10 textos nuevos en `textos/f2/`, `f3/` y `f4/`, con los cuatro bloques

### E14 · Fase 2 — Modelado

- [x] `R/ui/f2/` — `modelado.R` (cableado) + `especificacion.R` ·
      `supuestos.R` · `hiperparametros.R` · `analisis.R`
- [x] El catálogo usa por fin su `al_elegir`: elegir un método lleva a
      Especificación con el método ya seleccionado
- [x] «Guardar modelo en Objetos» → `nuevo_modelo()`

### E15 · Fase 3 — Ajuste

- [x] `R/ui/f3/` — `ajuste.R` (cableado) + `optimizador.R` · `control.R` ·
      `consola.R` · `analisis.R`
- [x] Modo paso a paso: **reproduce** la traza registrada, no recalcula. Con
      `invalidateLater` para la reproducción automática, sin JavaScript (C10)
- [x] «Guardar receta» y «Guardar corrida»

### E16 · Fase 4 — Evaluación

- [x] `R/ui/f4/` — `evaluacion.R` (cableado) + `composicion.R` · `desempeno.R` ·
      `diagnostico.R` · `explicabilidad.R` · `analisis.R`
- [x] Composición real: `validar_compatibilidad()` + `lista_avisos()` + Correr
- [x] El informe compuesto con descargas `.Rmd` · JSON · CSV · RDS

### E17 · `R/run_headless.R`

- [x] `correr()` recorre el registro y escribe el contrato S2 con
      `escribir_salida()`. No sabe nada del ACP: k-medias no lo va a tocar
- [x] `hiper_por_defecto()` se mudó de `ui/formulario.R` a `nucleo/registro.R`:
      el batch corre con `con_ui = FALSE` y no sourcea `ui/`

### E18 · Pruebas y documentación

- [x] `R/pruebas/test_acp.R` — 55 pruebas del método, sin Shiny
- [x] `R/pruebas/test_contrato.R` — 16 pruebas del contrato S2 y de C11
- [x] `R/pruebas/test_app_metodo.R` — 44 aserciones en navegador, fases 2→4
- [x] `test_headless.R` — la aserción de ACP pasó de negativa a positiva

### Definición de "hecho" — Hito 3

- [x] `verificar_loc.R` verde — máximo 261 LOC
- [x] `verificar_idioma.R` verde
- [x] `verificar_mapa.R` verde — 81 artefactos, deuda de código 30/47
- [x] `test_headless.R` · `test_fase1.R` · `test_acp.R` · `test_contrato.R`
- [x] `test_app.R` y `test_app_metodo.R` verdes, consola del navegador limpia
- [x] Cero dependencias nuevas

### Tres bugs que este hito destapó

Ninguno era del ACP; los tres estaban esperando a que alguien compusiera las
fases de verdad.

1. **`layout_sidebar(height=)` aplastaba los gráficos.** Con un alto fijo el
   cuerpo se vuelve contenedor *fill* y las cards se reparten los píxeles: en
   la pestaña Calidad cada `plotOutput` quedaba con decenas de píxeles y el
   device de R abortaba con `figure margins too large`. El alto ahora lo acota
   el sidebar y nadie más.
2. **`modelado-estado` estaba duplicado.** El filtro del catálogo y la franja
   de estado compartían id; Shiny lo avisa por consola y sigue a medias, con
   `input$estado` devolviendo cualquier cosa. Ahora el filtro es
   `estado_metodo`.
3. **`almacen_ids()` devolvía NULL con el almacén vacío**, porque
   `names(list())` es NULL. Un selector rellenado con eso tiraba "attempt to
   set an attribute on NULL" en un observer, al arrancar.

Y una decisión de producto que salió de componer: `validar_compatibilidad()`
valida contra las columnas que el **modelo** usa, no contra todas las numéricas
del dataset. Bloquear una corrida por faltantes en una columna que el modelo ni
mira mandaba a limpiar datos que no participan.

---

> Completado el 2026-08-14. El marco quedó validado: añadir un método es un
> archivo en `metodos/`, una fila en `catalogo/` y sus textos. La UI de las
> fases 2, 3 y 4 no se toca. Pendiente heredado: la subsección Comparación de
> la fase 4 espera al Hito 6, porque comparar corridas exige tener más de un
> método que comparar.

## Hito 4 — k-medias, y el marco puesto a prueba

Al terminar: se elige K-medias en el catálogo, se ve el semáforo con las dos
comprobaciones que hasta ahora decían «sin comprobación automática», se fijan
`k`, algoritmo, inicialización y reinicios, se ajusta viendo la inercia bajar,
se reproduce paso a paso con los centroides caminando, y se lee el resultado en
codo, silueta, tamaños y perfil de grupos — con el mismo JSON que produce
`correr("kmeans-twins", metodo = "kmeans")`.

Lo que este hito valida no es k-medias: es que el marco aguante **dos**
familias. El Hito 3 declaró que «la UI de las fases 2, 3 y 4 no se toca», y era
falso: con un solo método, «las métricas de la corrida» y «las métricas del
ACP» eran la misma cosa, y la fase 4 llamaba a `graficar_scree()` por su
nombre. El segundo método es lo que separa las dos ideas.

### E19 · Lógica pura del método

- [x] `metodos/kmeans.R` — `ajustar_kmeans()` con dos optimizadores escritos a
      mano: **Lloyd** (asignar todo, después recentrar) y **MacQueen** (cada
      punto mueve los centroides en el acto). Sin `stats::kmeans()`, que
      devuelve el resultado y se traga las iteraciones
- [x] Tres inicializaciones: `k-means++` (muestreo proporcional a D²),
      `aleatoria` y `Forgy`. Las tres bajo `set.seed(semilla)` (C13)
- [x] `reinicios` corridas con semillas `semilla + 0:(reinicios-1)`; gana la de
      menor inercia y las trazas de todas quedan para `comparar_reinicios()`
- [x] Traza rica: la inercia por iteración, los centroides como parámetros, y
      `asignaciones_por_iter` aparte — no son escalares y no caben en la traza
      genérica
- [x] Convención de orden de los grupos, equivalente a `.fijar_signo()` del
      ACP: sin ella la misma partición se pinta con otros colores y parece que
      cambió algo
- [x] `Hartigan-Wong` **se retiró** del catálogo. Prometerlo y despacharlo a
      `stats::kmeans()` daría un resultado sin traza, que es justo lo que la
      fase 3 muestra

### E20 · Despacho por familia

- [x] `R/logica/metricas.R` — seis genéricas S3 que la app le hace a cualquier
      ajuste: `metricas_de_corrida()`, `coordenadas_2d()`, `tabla_resultado()`,
      `grafico_resultado()`, `resumen_ajuste()`, `lectura_resultado()` y
      `etiquetas_ejes()`. El default falla y explica: un ajuste sin clase es un
      método a medio escribir, y una vista vacía lo escondería
- [x] `ajustar_acp()` y `ajustar_kmeans()` devuelven su lista con
      `class = c("ajuste_<clave>", "ajuste_sda")`. `registro.R` no cambia
- [x] `R/nucleo/registro.R` — `argumentos_ajuste()` filtra los mandos por la
      firma del método. Sin él, elegir k-medias revienta con
      "unused argument (inicializacion)"
- [x] `R/logica/modelo_geometria.R` — `k_del_modelo()`: la fase 2 tenía escrito
      `hiper$n_componentes`, que era la última suposición del ACP que quedaba

### E21 · Métricas y gráficos de grupos

- [x] `R/logica/metricas_grupos.R` — `silueta()`, `inercia_por_k()`,
      `resumen_grupos()`, `centroides_tabla()` y los métodos S3 de la familia.
      Cero dependencias nuevas: la silueta se escribe a mano
- [x] `R/graficos/diagnostico.R` — `graficar_codo()` y `graficar_silueta()`, en
      el archivo que el registro ya nombraba como deuda
- [x] `R/graficos/grupos.R` — `graficar_centroides()` y `graficar_tamanos()`
- [x] `coordenadas_2d.ajuste_kmeans()` proyecta sobre las dos primeras
      direcciones principales y colorea por grupo, así que `graficar_mapa_2d()`
      se reusa sin tocarla

### E22 · Supuestos

- [x] `grupos_esfericos` y `tamanos_similares` dejan de caer en
      `.supuesto_sin_prueba()`: el catálogo las prometía desde el Hito 1
- [x] El mensaje de `estructura_lineal` deja de nombrar al ACP

### E23 · UI de las fases 3 y 4

Ninguna vista nueva: lo que cambia es que las existentes despachan.

- [x] `R/ui/piezas/panel.R` — `panel_si_declara()` y `declarar_artefactos()`.
      Cumplen lo que `SCHEMA.md` §4 prometía: las vistas de la fase 4 se
      generan desde `artefactos`. Sin `renderUI`: la card se construye una vez
      y se muestra según el registro
- [x] `f3/optimizador.R` gana la inicialización y los pasos de Lloyd y
      MacQueen; `f3/control.R` gana los reinicios; `f3/ajuste.R` los pasa y los
      guarda en la receta
- [x] `f3/consola.R` — el mapa del estado por iteración: **los centroides
      caminando**, que es la promesa de `SCHEMA.md`. Reproduce la traza rica,
      no recalcula
- [x] `f4/desempeno.R` recorre `metricas_de_corrida()` en vez de leer campos
      fijos; `f4/diagnostico.R` y `f4/explicabilidad.R` encienden cada card
      según el registro; `f4/analisis.R` exporta `tabla_resultado()`

### E24 · `run_headless.R`

- [x] `plot_obj = grafico_resultado(ajuste)`, `datos_df = tabla_resultado(ajuste)`
      y el resumen final por `resumen_ajuste()`. El archivo vuelve a merecer su
      comentario de cabecera
- [x] `correr()` gana `inicializacion` y `reinicios`, en la firma y en el
      bloque `params` (C11)

### E25 · Artefactos y textos

- [x] Tres claves nuevas: `f3.consola.estado`, `f4.desempeno.grupos` y
      `f4.explicabilidad.centroides`
- [x] Cinco textos nuevos con los cuatro bloques y LaTeX donde hace falta
- [x] `fichas/kmeans.md` ya estaba escrita desde el Hito 1. No se tocó

### E26 · Pruebas

- [x] `R/pruebas/test_kmeans.R` — 59 pruebas. Las dos que el ACP no podía dar:
      la traza baja de verdad (`traza_monotona()` sobre la inercia) y la
      semilla cambia el resultado con datos solapados
- [x] `test_contrato.R` — las mismas aserciones, ahora sobre dos familias.
      Comprueba además que el corredor no le pasa a un método los mandos del otro
- [x] `test_headless.R` — el despacho por familia, y que un ajuste sin clase falle
- [x] `R/pruebas/test_app_kmeans.R` — el recorrido en navegador. Un archivo por
      método, como en las pruebas sin GUI: unificarlo con `test_app_metodo.R`
      pasaba de 300 LOC (C2) para no compartir casi nada

### Definición de "hecho" — Hito 4

- [x] `verificar_loc.R` verde
- [x] `verificar_idioma.R` verde
- [x] `verificar_mapa.R` verde — 84 artefactos
- [x] `test_headless.R` · `test_fase1.R` · `test_acp.R` · `test_kmeans.R` ·
      `test_contrato.R` verdes
- [x] `test_app.R`, `test_app_metodo.R` y `test_app_kmeans.R` verdes, consola
      del navegador limpia
- [x] Cero dependencias nuevas: Lloyd, MacQueen, k-means++ y la silueta,
      escritos a mano

### Dos bugs que este hito destapó

Ninguno era de k-medias.

1. **`paleta_cat()` devolvía menos colores de los pedidos.** Con `n > 8`
   retornaba los 8 de Okabe-Ito y ya. `scale_color_manual()` con menos valores
   que niveles no avisa al construir el gráfico: revienta al pintarlo. La
   trayectoria de k-medias (k × p parámetros) lo destapó, pero el ACP sobre
   twins —16 columnas— tenía el mismo fallo esperando. Ahora interpola sobre la
   misma base, y los ocho primeros siguen siendo los mismos.
2. **`graficar_trayectoria()` dibujaba decenas de líneas ilegibles.** Con 16
   cargas o 12 centroides no se lee ninguna. Muestra las ocho que más se
   movieron —que son las que contestan la pregunta de esa vista— y el subtítulo
   dice cuántas quedaron fuera.

Y una corrección de rumbo: el plan decía que este hito validaba el paso a paso
**recalculando**. No lo hace, y no debería: `consola.R` documenta desde el Hito
3 por qué recalcular por clic cruzaría la frontera R-navegador en cada paso y
rompería la garantía de que lo que se ve es lo que pasó. Lo que entró es una
traza más rica —centroides y asignaciones por iteración— que da el mismo efecto
didáctico reproduciendo.

> Completado el 2026-08-29. Añadir el tercer método ya no debería tocar la UI:
> lo que faltaba no era un archivo en `metodos/`, era el despacho por familia.

---

## Hito 4b — el Taller 01 se puede hacer entero dentro del lab

Al terminar: se carga `ori`, se filtra `Hora = 12:00`, se responden las doce
preguntas del Taller 01 en la app, y lo que se marcó con la casilla «Añadir» se
baja como un cuaderno `.Rmd` que corre solo.

Lo que valida este hito no es el taller: es que la fase 1 sirva para responder
una pregunta REAL de principio a fin. Con un taller concreto encima aparecieron
tres huecos que ningún dataset de juguete había destapado.

### E27 · La pregunta manda: filtrar filas

- [x] `R/ui/f1/filtro.R` — subsección **Filtro**, entre Fuente y Diccionario.
      Once de las doce preguntas dicen «para los registros recolectados a medio
      día»; sin filtro de filas, ninguna se podía responder de verdad
- [x] `aplicar_filtro()` en `logica/datos/transformacion.R` — el filtro entra en
      la MISMA pila que las transformaciones de columna (`TIPOS_PILA`), y por
      eso hereda gratis el deshacer, el aviso de qué se aplicó y el cuaderno
- [x] Un filtro que dejaría el dataset vacío NO se aplica: devuelve los datos
      intactos con un aviso de error. Un `data.frame` de cero filas rompe todo
      lo que viene después, y en silencio

### E28 · Los tres huecos de análisis que faltaban

- [x] `medir_asociacion()` devuelve **covarianza** junto a Pearson y Spearman:
      la pregunta 8 es justamente por qué una tiene unidades y la otra no
- [x] `graficar_histograma(normal =)` y `graficar_densidad(normal =)` superponen
      la N(media, desvío) estimada de los datos (pregunta 12)
- [x] `graficar_dispersion_marginal()` compone la nube con el histograma de cada
      variable en su borde (pregunta 7), con `gtable` — que ggplot2 ya arrastra.
      `patchwork` o `ggExtra` lo harían en una línea y serían una dependencia
      más en el bundle wasm

### E29 · ⤓ Informe: llevarse el laboratorio

- [x] Casilla «Añadir» en el encabezado de 17 paneles (`casilla_informe()`), con
      la selección viviendo en un `reactiveVal` de `app.R`: ① Datos la llena y
      la pestaña Informe la exporta, en la misma sesión Shiny
- [x] `nucleo/informe/exploracion.R` — la selección a cuaderno: los datos, la
      pila de preparación traducida a R, y una sección por panel con su texto
      y sus parámetros congelados AL MARCAR, no al exportar
- [x] `nucleo/informe/codigos.R` — un artefacto a R autónomo (base + ggplot2):
      el cuaderno se abre en cualquier R, sin nada del lab instalado
- [x] `nucleo/informe/opciones.R` + `encabezado.R` — qué piezas lleva el
      cuaderno (texto del panel, procedencia, tablas, YAML) casilla por
      casilla, con el entregable del taller como valor de fábrica
- [x] `R/ui/transversal/informe.R` — la pestaña: cuaderno (`.qmd` o `.Rmd`),
      CSV de los datos actuales y JSON de la selección

### E30 · Que los datos del taller lleguen al despliegue

- [x] `data/ORI.csv` en `build.R` y en el espejo de `manifiesto.R`: sin eso el
      archivo estaba en el repo pero no viajaba ni a GH-Pages ni a Posit
- [x] `ORI.csv` convertido a UTF-8. `shinylive::export()` mete los `.csv` en
      `app.json` **como texto UTF-8**: con el archivo en ISO-8859-1 el bundle
      salía con JSON inválido. `cargar_ori()` acepta las dos codificaciones, así
      que un estudiante puede subir su copia del curso sin convertir nada
- [x] `learn/workshops/Taller-01-Sln.md` — el solucionario: por pregunta, la
      ruta en la app, la respuesta con sus números y el R equivalente

### E31 · El laboratorio también por consola

- [x] `R/lab.R` — la fase 1 sin navegador: `datos`, `diccionario`, `resumen`,
      `frecuencias`, `atipicos`, `asociacion`, `normalidad`, `contingencia`,
      `panel`, `casillas`, `cuaderno`. `--fuente` y `--filtro` (repetible)
      arman el mismo objeto dataset que la app, así que lo que se mide por
      consola es lo que muestra la pantalla
- [x] `panel <clave>` devuelve **el gráfico como tabla**: lee del registro (C9)
      qué función dibuja ese artefacto, la llama y imprime las capas de
      `ggplot_build()` en vez del dibujo. Los bordes y alturas del histograma,
      los cinco números de la caja. Un gráfico se puede leer sin verlo
- [x] `R/pruebas/test_informe.R` — el cuaderno y el CLI, sin Shiny. Salió de
      partir `test_headless.R`, que había pasado el techo de 300 LOC

> Completado el 2026-09-02. El hueco que más costó no fue estadístico: fue que
> un CSV en latin1 rompe el bundle wasm sin decir por qué. Los datos de verdad
> vienen sucios, y el despliegue es donde se nota.

---

## Hitos siguientes

- [ ] **Hito 5 · LASSO** — valida barrido de hiperparámetros y ruta de
      regularización; migra `projects/01-lasso/`
- [ ] **Hito 6 · Evaluación completa** — explicabilidad, comparación de corridas,
      exportador a `.Rmd` + `revealjs`. El exportador a `.Rmd` ya está hecho para
      la fase 1 (Hito 4b): falta extenderlo a las corridas y añadir `revealjs`
- [ ] **Hito 7 · Poblar el catálogo** — el resto de `libs/topics-map.md`, un
      método por vez, con su ficha y sus textos
