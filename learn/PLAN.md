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
- [x] `R/nucleo/informe.R` — armado del cuaderno `.Rmd`
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

> Completado el 2026-08-13. Sin LaTeX en los textos: `commonmark` no renderiza
> matemáticas y MathJax exigiría red y JavaScript propio. Notación en Unicode,
> como en `notes/tree.md` (ver C6 en CONVENCIONES.md).

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

## Hitos siguientes

- [ ] **Hito 4 · k-medias** — valida el modo paso a paso recalculando (el ACP
      lo resuelve reproduciendo la traza) y la sensibilidad a la semilla, que
      el ACP no ejercita porque siempre converge al mismo sitio
- [ ] **Hito 5 · LASSO** — valida barrido de hiperparámetros y ruta de
      regularización; migra `projects/01-lasso/`
- [ ] **Hito 6 · Evaluación completa** — explicabilidad, comparación de corridas,
      exportador a `.Rmd` + `revealjs`
- [ ] **Hito 7 · Poblar el catálogo** — el resto de `libs/topics-map.md`, un
      método por vez, con su ficha y sus textos
