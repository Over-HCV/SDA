# SDA Lab

Laboratorio interactivo para el curso **Análisis Estadístico de Datos**
(Universidad del Rosario). Un solo aplicativo Shiny donde se recorren las
cuatro fases de un análisis y se ve, en vivo, qué hace cada método y por qué
es necesario.

```
① Datos  →  ② Modelado  →  ③ Ajuste  →  ④ Evaluación
```

- **Diseño completo**: [`SCHEMA.md`](SCHEMA.md) — qué hay en cada pantalla
- **Reglas de código**: [`CONVENCIONES.md`](CONVENCIONES.md) — C1…C14
- **Plan y avance**: [`PLAN.md`](PLAN.md) — casillas por hito
- **Índice de artefactos**: [`MAPA.md`](MAPA.md) — clave → archivos

## Estado

**Hito 2 hecho**: la fase 1 calcula de verdad. Se carga un dataset (de los del
curso, sintético o un CSV propio), se declara qué es cada columna, se limpia, se
transforma, se parte y se balancea, y se mira en univariado, bivariado y
multivariado. Las fases 2, 3 y 4 siguen siendo andamio, salvo el catálogo.
El avance vive en [`PLAN.md`](PLAN.md) — este README no lo repite para no quedar
desactualizado.

## Correr

Desde la **raíz del repo** (`SDA/`), no desde `learn/`:

```bash
# App completa, R de verdad
Rscript -e 'shiny::runApp("learn/R/app.R", launch.browser = TRUE)'

# Con el tema 8-bit
SDA_TEMA=retro Rscript -e 'shiny::runApp("learn/R/app.R", launch.browser = TRUE)'

# Forzar el camino de wasm sin exportar el bundle
SDA_MODO=wasm Rscript -e 'shiny::runApp("learn/R/app.R", launch.browser = TRUE)'
```

## Verificar

```bash
Rscript learn/R/pruebas/verificar_loc.R      # techo de 300 LOC (C2)
Rscript learn/R/pruebas/verificar_idioma.R   # español ASCII (C1)
Rscript learn/R/pruebas/verificar_mapa.R     # MAPA.md al día (C9)
Rscript learn/R/pruebas/test_headless.R      # núcleo, sin Shiny
Rscript learn/R/pruebas/test_fase1.R         # lógica y gráficos de la fase 1
Rscript learn/R/pruebas/test_app.R           # UI + consola del navegador
Rscript learn/R/pruebas/verificar_bundle.R   # el bundle wasm arranca de verdad
```

Los dos últimos abren un navegador de verdad. No son opcionales: un render
limpio y un HTTP 200 no prueban nada (ver `libs/sdd.md` S2b).

## Desplegar

El mismo código produce dos salidas: un bundle que corre **dentro del
navegador** (webR/WebAssembly, cero instalación, se sirve como archivos
estáticos) y la app normal sobre R completo.

```bash
Rscript -e 'source("learn/build.R"); construir_bundle()'
python3 -m http.server 8000 --directory learn/docs
```

### En navegador (wasm) — GitHub Pages

`.github/workflows/pages.yml` reconstruye el bundle en cada push a `main` que
toque `learn/`, `libs/_comun/` o `data/`, y lo publica. Requiere un ajuste
manual una sola vez: **Settings → Pages → Build and deployment → Source =
GitHub Actions** (en el repo, no en los ajustes de la cuenta).

### En servidor (R completo) — Posit Connect Cloud

El punto de entrada es el `app.R` de la **raíz** del repo, que solo hace
`source("learn/R/app.R")$value`. Vive ahí porque la app usa `data/` y
`libs/_comun/`, que se comparten con `notes/`, `workshops/` y `projects/`:
moverlas dentro de `learn/` las duplicaría. Al desplegar desde git, el servidor
clona el repositorio entero y las encuentra donde siempre.

Connect Cloud exige un `manifest.json` con las dependencias de R. Se regenera
—y hay que volver a generarlo cuando cambien las librerías que usa la app— con:

```bash
Rscript -e 'source("learn/manifiesto.R"); escribir_manifiesto()'
```

No se corre `rsconnect::writeManifest(".")` directo: rsconnect leería
`renv.lock`, que es único para todo el repo y trae 111 paquetes (tidyverse,
plotly, chromote…). El script lo genera contra un espejo con solo lo que la app
toca, y quedan 60 con sus dependencias transitivas.

En el formulario de Connect Cloud: **Primary file = `app.R`**.

Los métodos que no compilan a WebAssembly (`brms`, `torch`, …) siguen visibles
en el catálogo, con su ficha y su explicación, pero sin botón de ejecutar.

`learn/docs/` no se versiona: se reconstruye con el comando de arriba.

## Variables de entorno

| Variable | Valores | Efecto |
|---|---|---|
| `SDA_TEMA` | `flatly` (def.), `darkly`, `cosmo`, `minty`, `vapor`, `retro`, `retro-dark` | preset inicial |
| `SDA_MODO` | `wasm`, `servidor` | fuerza el modo; por defecto se detecta solo |
| `SDA_THEMER` | `1` | monta el widget `bs_themer()` de bslib |

## Cómo está organizado

El árbol completo y comentado está en [`SCHEMA.md`](SCHEMA.md) §7. En corto:

- `R/nucleo/` — registro, estado, contratos, trazabilidad, exportación.
  **Sin Shiny en ninguna línea**: `cargar_sda(con_ui = FALSE)` lo carga entero
  sin bslib ni DT, que es lo que haría viable una CLI encima.
- `R/logica/` y `R/graficos/` — cálculo y ggplot puros. Sin prefijos en los
  nombres: lo que agrupa es la carpeta (`logica/datos/calidad.R`), no el
  archivo (`logica/datos_calidad.R`).
- `R/ui/` — módulos Shiny; solo cablean. `piezas/` tiene los componentes
  compartidos y ninguna vista los reinventa.
- `fichas/` y `textos/` — la parte pedagógica, en markdown, fuera del código.
  Los textos siguen la clave del artefacto:
  `f1.analisis.histograma` → `textos/f1/analisis/histograma.md`.

Reutiliza `libs/_comun/R/` (datos, temas, métricas, verificación en navegador)
del resto del repo. No duplicar esas funciones aquí.

## Archivos generados

No se versionan y se reconstruyen con un comando:

| Ruta | Cómo se regenera |
|---|---|
| `learn/docs/` | `Rscript -e 'source("learn/build.R"); construir_bundle()'` — en GitHub lo hace `.github/workflows/pages.yml` |
| `learn/outputs/` | corridas de `run_headless.R` |

`MAPA.md` también se genera (`Rscript learn/R/mapa.R`) pero **sí** se versiona:
es el índice que un agente lee antes de tocar nada y tiene que estar disponible
sin correr R. `verificar_mapa.R` falla si queda desactualizado.
