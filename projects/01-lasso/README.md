# Proyecto 01 — LASSO sobre twins

App Shiny para explorar **selección de variables con penalización LASSO**
(`glmnet`) sobre `data/twins.csv`. Corresponde a la fila **23** de
`libs/topics-map.md` (macro-tema *Regresión lineal en múltiples variables*).

**Hook pedagógico**: el slider de `lambda` en escala log. Al subirlo, la
penalización L1 lleva coeficientes **exactamente a cero** y el contador de
predictores activos baja en vivo. Con `alpha = 0` (ridge) los coeficientes se
encogen pero nunca se anulan — esa es justamente la diferencia que el tema
quiere mostrar.

---

## Estructura

```
projects/01-lasso/
├── R/
│   ├── datos.R           # adaptador: datos_lasso(), etiquetas_vars(), n_completos()
│   ├── modelo.R          # lógica PURA: correr_lasso(), graficar_*(), tabla_coefs()
│   ├── mod_main.R        # UI + server del módulo principal
│   ├── app.R             # cableado: page_navbar + módulo + theme switcher
│   ├── run_headless.R    # entrada para el agente (sin GUI)
│   ├── test_headless.R   # regresión de la lógica + contrato S2
│   └── test_app.R        # regresión de la UI (shinytest2)
├── outputs/              # artefactos de corridas (no versionar)
├── README.md             # este archivo
└── AGENT.md              # instrucciones para agente LLM (inglés)
```

---

## Datos

`data/twins.csv` — estudio de gemelos, 183 pares × 16 variables.

- **Respuesta**: `DLHRWAGE`, diferencia en log-salario horario entre gemelos.
- **Predictores por defecto** (13): `DEDUC1`, `DEDUC2`, `AGE`, `AGESQ`, `DTEN`,
  `DMARRIED`, `DUNCOV`, `EDUCH`, `EDUCL`, `WHITEH`, `WHITEL`, `MALEH`, `MALEL`.
- **Excluidos a propósito**: `HRWAGEH` y `HRWAGEL`. Son los salarios crudos con
  los que se construye `DLHRWAGE`; incluirlos sería fuga de información.
- **Faltantes**: `DLHRWAGE` 34, `HRWAGEH` 22, `HRWAGEL` 21, `DTEN` 4. Con los
  predictores por defecto quedan **147 casos completos**.

El loader `cargar_twins()` vive en `libs/_comun/R/datos.R` y resuelve dos
trampas del archivo: los faltantes vienen como `"."` (no como celda vacía) y
el CSV trae BOM UTF-8.

---

## Cómo correrlo

> ⚠️ Todo desde la raíz del proyecto (`SDA/`), donde está `.Rprofile`.

### Interactivo

```bash
Rscript -e 'shiny::runApp("projects/01-lasso/R/app.R", launch.browser = TRUE)'
```

Con tema retro 8-bit:

```bash
SDA_TEMA=retro Rscript -e 'shiny::runApp("projects/01-lasso/R/app.R", launch.browser = TRUE)'
```

### Headless

```bash
Rscript -e 'source("projects/01-lasso/R/run_headless.R");
            correr("lasso-base", alpha = 1)'
```

Otros escenarios:

```r
correr("ridge",        alpha = 0, lambda = 0.05)
correr("enet",         alpha = 0.5)
correr("lasso-fuerte", alpha = 1, lambda = 0.3)
correr("subset",       x_vars = c("DEDUC1", "DEDUC2", "AGE", "DTEN"))
```

Escribe en `projects/01-lasso/outputs/`:

- `<esc>.png` — observado vs predicho
- `<esc>.json` — params + métricas + rutas (schema S2)
- `<esc>.csv` — tabla de coeficientes al lambda usado
- `<esc>-regularizacion.png` — camino de coeficientes + curva de CV
- `run_log.csv` — append

### Tests

```bash
Rscript projects/01-lasso/R/test_headless.R   # lógica + contrato S2
Rscript projects/01-lasso/R/test_app.R        # UI + comportamiento del slider
```

---

## Qué hace la app

### Controles

| Input | Qué cambia |
|---|---|
| `log10(lambda)` (slider) | la penalización. **El control principal.** |
| botones `lambda.min` / `lambda.1se` | saltan al óptimo de validación cruzada |
| `alpha` (slider 0–1) | 1 = LASSO, 0 = ridge, intermedio = elastic net |
| Predictores (checkboxGroup) | qué columnas entran al modelo |
| Folds, semilla, estandarizar | configuración del CV |

### Salidas

- **Value boxes**: activos / λ actual / MSE de CV / n usados.
- **Camino de coeficientes**: cada línea es un predictor; roja = sigue activo,
  gris = ya anulado. Tres verticales: λ actual (rojo), `lambda.min` (azul
  punteado), `lambda.1se` (verde punteado). Con brush horizontal se inspecciona
  un rango de λ.
- **Curva de CV**: MSE con barras de error por λ.
- **Observado vs predicho**, **tabla de coeficientes**, y un tab de
  **diagnóstico de datos** que muestra cuántos casos completos quedan según las
  columnas elegidas.

---

## Notas de interpretación

- **El R² no es una medida de ajuste honesta bajo regularización.** No hay
  grados de libertad bien definidos. Se muestra como referencia descriptiva; la
  métrica que manda para elegir λ es el **MSE de validación cruzada**.
- `lambda.1se` ≥ `lambda.min` siempre: es la regla "un error estándar", más
  parsimoniosa que el mínimo del CV.
- El CV parte los folds al azar → **sin fijar semilla los resultados no son
  reproducibles**. Por eso `semilla` es un input y viaja al JSON.
- Con λ muy alto, `no_cero = 0`: solo queda el intercepto.

---

## Dependencias

- `glmnet` (5.0) — único paquete nuevo respecto al Proyecto 1
- El resto (`shiny`, `bslib`, `DT`, `ggplot2`, `patchwork`) ya estaba

---

## Siguiente

Este proyecto es la **instancia de referencia** de `projects/_template/`.
Para arrancar otro tema de `libs/topics-map.md`:

```bash
./projects/nuevo-tema.sh 02 dbscan
```
