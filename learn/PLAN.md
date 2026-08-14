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

- [ ] `R/ui/ui_piezas.R`
  - [ ] `panel_resultado(clave, contenido, ...)` — card + los tres toggles
  - [ ] `toggle(titulo, contenido, abierto = FALSE)`
  - [ ] `tabla_paginada(df, ...)` — paginación, filtro, pie "X de N"
  - [ ] `badge_muestreo(n_total, n_muestra, semilla)`
  - [ ] `franja_estado(items)`
  - [ ] `tarjeta_metodo(clave)` — con candado si `estado != "activo"`
- [ ] `R/ui/ui_ficha.R` — ficha desde `fichas/<clave>.md`, con "el puente" si está bloqueada
- [ ] `R/ui/ui_formulario.R` — `hiper{}` → widgets
- [ ] `fichas/acp.md`, `fichas/kmeans.md`, `fichas/mlp.md` (bloqueada)
- [ ] 2 textos de ejemplo en `textos/`

### E3 · Shell navegable

- [ ] `R/app.R` — `page_navbar`: ⌂ ① ② ③ ④ ⚙ ⓘ + tema + badge de modo. Solo cablea
- [ ] `R/ui/f0_inicio.R` — estado, mapa del curso, últimas corridas, ruta sugerida
- [ ] `R/ui/f2_catalogo.R` — **la vista real del hito**: tarjetas + filtros + ficha
- [ ] `R/ui/x_objetos.R` — CRUD con `tabla_paginada()`
- [ ] `R/ui/x_referencia.R` — glosario · árbol · galería (`libs/shiny/R/gal_*.R`) · tema
- [ ] Placeholders navegables de ① ② ③ ④ con sus tabs y aviso "en construcción"
- [ ] `R/pruebas/test_app.R` — recorre 7 secciones, cambia tema, filtra, abre ficha;
      cero errores de consola + aserciones positivas (C14)

### E4 · Despliegue día 0

- [ ] `app.R` — wrapper shinylive (patrón de `libs/shiny-live/app.R`, ojo con `$value`)
- [ ] `build.R` — `construir_bundle()` filtrando `wasm == TRUE`, staging con
      `data/` y `libs/_comun/` adentro
- [ ] Export a `docs/`
- [ ] `verificar_html()` sobre el bundle: consola limpia + aserciones positivas
- [ ] GitHub Pages sirviendo `learn/docs/`

### Definición de "hecho" — Hito 1

- [ ] `verificar_loc.R` verde
- [ ] `verificar_idioma.R` verde
- [ ] `verificar_mapa.R` verde
- [ ] `test_headless.R` verde
- [ ] `test_app.R` verde, consola sin errores
- [ ] Bundle wasm abre y navega sin errores
- [ ] `renv::status()` limpio (Hito 1 no debería añadir dependencias)

---

## Hitos siguientes

- [ ] **Hito 2 · Fase 1 completa** — 6 subsecciones + ▣ Análisis (uni/bi/multi).
      Entra el muestreo con aviso (C8) y el diccionario que filtra la UI según
      la escala de medición
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
