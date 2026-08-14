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

---

## Hitos siguientes

> Completado el 2026-08-13. Pendiente heredado: los métodos de la fase 1 que
> exigirían dependencias nuevas (MICE, k-NN, SMOTE) siguen sin implementar, a
> propósito. Entran cuando se decida pagar el peso en el bundle.

- [ ] **Hito 3 · ACP de punta a punta** — primer método por las 4 fases; valida
      el marco. Teoría en `notes/SDA/NB3/main.md`
- [ ] **Hito 4 · k-medias** — valida el modo paso a paso y la traza de
      convergencia, que el ACP no ejercita
- [ ] **Hito 5 · LASSO** — valida barrido de hiperparámetros y ruta de
      regularización; migra `projects/01-lasso/`
- [ ] **Hito 6 · Evaluación completa** — explicabilidad, comparación de corridas,
      exportador a `.Rmd` + `revealjs`
- [ ] **Hito 7 · Poblar el catálogo** — el resto de `libs/topics-map.md`, un
      método por vez, con su ficha y sus textos
