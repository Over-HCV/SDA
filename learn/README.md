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

**Hito 4 hecho**: las cuatro fases se recorren enteras con dos métodos de
familias distintas. Se carga un dataset (de los del curso, sintético o un CSV
propio), se limpia y se transforma; se elige **ACP** o **K-medias** en el
catálogo, se mira el semáforo de supuestos y se fijan los hiperparámetros; se
ajusta viendo bajar el objetivo y se reproduce iteración por iteración; y se lee
el resultado en las vistas que ese método produce y no en las del otro.

El segundo método es lo que hace honesta la frase «el marco es genérico»: hasta
el Hito 3, «las métricas de la corrida» y «las métricas del ACP» eran la misma
cosa. El avance vive en [`PLAN.md`](PLAN.md) — este README no lo repite para no
quedar desactualizado.

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
Rscript learn/R/pruebas/test_informe.R       # el cuaderno exportable y lab.R
Rscript learn/R/pruebas/test_acp.R           # el método ACP, sin Shiny
Rscript learn/R/pruebas/test_kmeans.R        # el método K-medias, sin Shiny
Rscript learn/R/pruebas/test_contrato.R      # contrato S2 y regla de tres partes
Rscript learn/R/pruebas/test_app.R           # UI de la fase 1 + consola
Rscript learn/R/pruebas/test_app_piezas.R    # la envoltura que comparten las cards
Rscript learn/R/pruebas/test_app_metodo.R    # el ACP por las fases 2, 3 y 4
Rscript learn/R/pruebas/test_app_kmeans.R    # K-medias, el mismo recorrido
Rscript learn/R/pruebas/verificar_bundle.R   # el bundle wasm arranca de verdad
```

Los cinco últimos abren un navegador de verdad. No son opcionales: un render
limpio y un HTTP 200 no prueban nada (ver `libs/sdd.md` S2b).

## Hacer el laboratorio por consola

`learn/R/lab.R` recorre la fase 1 sin navegador: es la app preguntada por
escrito. Sirve para responder un taller desde la terminal, para comprobar en
dos segundos lo que un panel dice, y para que un script o un agente puedan
hacer lo mismo que una persona hace con las pestañas.

```bash
Rscript learn/R/lab.R                          # los comandos disponibles
Rscript learn/R/lab.R fuentes                  # el catálogo de datos
ORI="--fuente ori --filtro Hora=12:00"         # se repite en cada comando

Rscript learn/R/lab.R datos $ORI               # dimensiones + pila + cabecera
Rscript learn/R/lab.R diccionario $ORI         # escala y clase por columna
Rscript learn/R/lab.R resumen Temperatura $ORI # los 14 estadísticos
Rscript learn/R/lab.R atipicos Presion $ORI    # Tukey: corte y filas marcadas
Rscript learn/R/lab.R asociacion Temperatura Velocidad_del_Viento $ORI
Rscript learn/R/lab.R normalidad Presion $ORI  # asimetría, h, Shapiro-Wilk
```

**Un gráfico se devuelve como su tabla.** `panel` construye el mismo ggplot que
pinta la app y, en vez de dibujarlo, imprime las capas ya calculadas: los
bordes y las alturas del histograma, los cinco números de la caja, los puntos
de la nube. Es la información que uno lee del dibujo, en un formato que se lee
sin ojos.

```bash
Rscript learn/R/lab.R panel f1.analisis.histograma Temperatura $ORI
Rscript learn/R/lab.R casillas                 # las 18 claves exportables
Rscript learn/R/lab.R cuaderno f1.analisis.boxplot:Temperatura $ORI --salida taller.Rmd

# Una sesión = fuente + pila + diccionario declarado + paneles marcados.
Rscript learn/R/lab.R sesion f1.analisis.boxplot:Temperatura $ORI \
  --escala Temperatura=intervalo --salida sesion.json
Rscript learn/R/lab.R cuaderno --sesion sesion.json --salida taller.Rmd
SDA_SESION=sesion.json Rscript -e 'shiny::runApp("learn/R/app.R")'   # o ?sesion=
```

`--filtro` se puede repetir y se aplica en orden, igual que la pila de la
subsección Filtro. No hay estado entre invocaciones a propósito: cada comando
declara el dataset sobre el que corre, y por eso es reproducible.

Ver `learn/workshops/Taller-01-Sln.md` para el Taller 01 resuelto por los tres
caminos: la app, la consola y R puro.

## Correr un método sin la app

La misma corrida que hace la interfaz, desde la línea de comandos, con el
mismo JSON de salida:

```bash
Rscript -e 'source("learn/R/run_headless.R"); correr("acp-twins")'
Rscript -e 'source("learn/R/run_headless.R");
            correr("acp-cov", hiper = list(matriz = "covarianza"))'
Rscript -e 'source("learn/R/run_headless.R");
            correr("kmeans-twins", metodo = "kmeans", hiper = list(k = 4L),
                   reinicios = 10L)'
```

Escribe `learn/outputs/<escenario>.{json,csv,png}` y va acumulando
`run_log.csv`. Que app y batch produzcan lo mismo no es casualidad: los dos
llaman a la misma función pura de `learn/metodos/`, y `test_contrato.R` lo
comprueba.

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
