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

**Hito 1 en curso**: núcleo + shell navegable + despliegue. Las cuatro fases
existen y se recorren, pero todavía no calculan nada. Ver `PLAN.md`.

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
Rscript learn/R/pruebas/test_headless.R      # lógica y contratos
Rscript learn/R/pruebas/test_app.R           # UI + consola del navegador
```

## Desplegar

El mismo código produce dos salidas: un bundle que corre **dentro del
navegador** (webR/WebAssembly, cero instalación, se sirve como archivos
estáticos) y la app normal sobre R completo.

```bash
Rscript -e 'source("learn/build.R"); construir_bundle()'
python3 -m http.server 8000 --directory learn/docs
```

Los métodos que no compilan a WebAssembly (`brms`, `torch`, …) aparecen en el
catálogo con candado y su explicación, en vez de desaparecer.

## Variables de entorno

| Variable | Valores | Efecto |
|---|---|---|
| `SDA_TEMA` | `flatly` (def.), `darkly`, `cosmo`, `minty`, `vapor`, `retro`, `retro-dark` | preset inicial |
| `SDA_MODO` | `wasm`, `servidor` | fuerza el modo; por defecto se detecta solo |
| `SDA_THEMER` | `1` | monta el widget `bs_themer()` de bslib |

## Cómo está organizado

```
learn/
├─ R/nucleo/    registro de métodos, estado, contratos, claves, exportación
├─ R/logica/    cálculo puro — sin Shiny
├─ R/graficos/  ggplot puro — sin Shiny
├─ R/ui/        módulos Shiny; solo cablean
├─ R/pruebas/   verificadores y los dos harness de test
├─ metodos/     una función ajustar_*() pura por método
├─ fichas/      un .md por método (qué es, por qué, cuándo falla)
├─ textos/      un .md por gráfico (qué muestra, qué buscar, cuándo engaña)
└─ docs/        bundle wasm exportado
```

Reutiliza `libs/_comun/R/` (datos, temas, métricas, verificación en navegador)
del resto del repo. No duplicar esas funciones aquí.
