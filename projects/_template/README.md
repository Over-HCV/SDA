# Proyecto __NN__ — __TITULO__

> **TODO**: reemplazar esta plantilla. Buscá `TODO` en `R/*.md` y `R/*.R`.

App Shiny para el tema **__TITULO__**, fila **__FILA__** de
`libs/topics-map.md` (macro-tema *TODO*).

**Hook pedagógico**: TODO — qué control hace que el método se entienda al
moverlo, y qué se ve cambiar.

---

## Estructura

```
projects/__SLUG__/
├── R/
│   ├── datos.R           # adaptador → libs/_comun/R/datos.R
│   ├── modelo.R          # lógica PURA (sin input/reactive/session)
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

**TODO**: fuente, respuesta, predictores, faltantes.

Fuentes disponibles en `libs/_comun/R/datos.R`:

| Función | Qué da |
|---|---|
| `cargar_charcoal()` | panel FAO país × flujo × año |
| `cargar_twins()` | 183 pares × 16 vars (NA codificados como `.`) |
| `gen_sintetico()` | sintético controlado (`tipo = "anova"` / `"regresion"`) |
| `pivot_paises()` | matriz país × año, lista para PCA/clustering |

---

## Cómo correrlo

> ⚠️ Todo desde la raíz del proyecto (`SDA/`), donde está `.Rprofile`.

```bash
# Interactivo
Rscript -e 'shiny::runApp("projects/__SLUG__/R/app.R", launch.browser = TRUE)'

# Con tema retro 8-bit
SDA_TEMA=retro Rscript -e 'shiny::runApp("projects/__SLUG__/R/app.R", launch.browser = TRUE)'

# Headless
Rscript -e 'source("projects/__SLUG__/R/run_headless.R"); correr("demo")'

# Tests
Rscript projects/__SLUG__/R/test_headless.R
Rscript projects/__SLUG__/R/test_app.R
```

---

## Checklist (definition of done)

Ver `libs/sdd.md` para la versión completa.

- [ ] `modelo.R` no menciona `input`, `reactive` ni `session`
- [ ] Ningún `.R` supera 300 LOC
- [ ] Regla de las 3 partes: cada hiperparámetro está en `modelo.R`,
      `run_headless.R` (incluido su `params`) y `mod_main.R`
- [ ] `test_headless.R` verde, con al menos una **invariante del tema**
- [ ] `test_app.R` verde, ejercitando el hook
- [ ] README (español) y AGENT.md (inglés) sin `TODO` sueltos
- [ ] `renv::snapshot()` corrido si se añadió algún paquete
