# Theming cheat-sheet (bslib)

Cómo personalizar la app más allá del switcher de 5 bootswatch que ya está
cableado en `app.R:35-100`. Todo esto está documentado en
<https://rstudio.github.io/bslib/articles/theming/index.html>.

---

## 1. Las 4 palancas principales de `bs_theme()`

```r
bs_theme(
  bg = "#FFFFFF",          # fondo (impacta en TODO: texto, cards, sidebars)
  fg = "#1A1A1A",          # texto principal
  primary = "#0B6E4F",     # links, nav activa, focus de inputs
  secondary = "#6C757D",   # actionButton por defecto
  base_font   = font_google("Inter"),     # texto cuerpo
  heading_font = font_google("Inter"),    # h1-h6
  code_font   = font_google("JetBrains Mono")
)
```

`bg`, `fg`, `primary` son **las más influyentes**: afectan cientos de defaults.
`font_google()` descarga y cachea en el primer uso (luego offline).

## 2. Sass variables vía `...` (cientos de knobs)

Cualquier variable Bootstrap 5 se pasa como string:

```r
bs_theme(
  "font-size-base"   = "0.95rem",   # tamaño de texto global
  "enable-rounded"   = FALSE,        # desactiva bordes redondeados
  "enable-shadows"   = TRUE,
  "spacer"           = "1.25rem",
  "progress-bar-bg"  = "orange"
)
```

Lista completa: <https://rstudio.github.io/bslib/articles/bs5-variables/>.

## 3. `bs_add_rules()` — añadir Sass/CSS propio

Acepta strings, archivos `.scss`/`.css`, o listas mixtas:

```r
tema_inicial <- bslib::bs_theme(bootswatch = "flatly") |>
  bslib::bs_add_rules(
    list(
      sass::sass_file("libs/shiny/styles/custom.scss"),
      "body { background-color: $body-bg; }"
    )
  )
```

Las reglas pueden **referenciar variables Bootstrap** (`$body-bg`, `$primary`,
`$body-color`) y funciones Sass (`mix()`, `rgba()`, `color-contrast()`).
Ver `libs/shiny/styles/custom.scss` para un ejemplo completo.

## 4. Modo oscuro dinámico (toggle en runtime)

Tu `app.R` ya cambia bootswatch; para oscuro **custom** (no Darkly):

```r
light <- bs_theme(bg = "#FFFFFF", fg = "#1A1A1A", primary = "#0B6E4F")
dark  <- bs_theme(bg = "#0F1115", fg = "#E8E8E8", primary = "#4DD0A8")

observe(session$setCurrentTheme(
  if (isTRUE(input$dark_mode)) dark else light
))
```

## 5. `bs_themer()` — diseño de tema en vivo (solo DEV)

Superpone un widget en la app para iterar colores/fuentes/bootswatch e
**imprime en consola el código R** para reproducir lo que vas eligiendo:

```r
server <- function(input, output, session) {
  bslib::bs_themer()   # ⚠️ solo en desarrollo, NUNCA en producción
}
```

Ideal para las primeras fases de diseño de cada `projects/NN-<slug>/`.

---

## Temas listos para pegar

### A. Académico (papel, default académico)

```r
bs_theme(
  bootswatch = "flatly",
  bg = "#FCFBF7", fg = "#2B2B2B", primary = "#205070",
  base_font = font_google("Source Serif 4"),
  heading_font = font_google("Source Sans 3"),
  code_font = font_google("JetBrains Mono"),
  "font-size-base" = "0.95rem"
) |> bs_add_rules(sass::sass_file("libs/shiny/styles/custom.scss"))
```

### B. Dark mode técnico (IDE-like)

```r
bs_theme(
  bootswatch = "darkly",
  bg = "#0F1115", fg = "#E8E8E8", primary = "#4DD0A8",
  base_font = font_google("Inter"),
  code_font = font_google("JetBrains Mono"),
  "enable-gradients" = FALSE
) |> bs_add_rules(
  ".card { background-color: mix($body-bg, white, 6%); }"
)
```

### C. Retro (inspirado en NES.css del artículo)

```r
bs_theme(
  bg = "#E5E5E5", fg = "#0D0C0C", primary = "#DD2020",
  base_font = font_google("Press Start 2P"),
  code_font = font_google("Press Start 2P"),
  "font-size-base" = "0.75rem",
  "enable-rounded" = FALSE
) |> bs_add_rules(
  sass::sass_file("libs/shiny/styles/nes.min.css")  # descargar primero de nostalgic-css/NES.css
)
```

### D. Positivo/corporativo (Minty con dorado)

```r
bs_theme(
  bootswatch = "minty",
  primary = "#A37C2C",
  base_font = font_google("Lato"),
  heading_font = font_google("Playfair Display")
)
```

---

## Dónde tocar

| Qué | Dónde | Cómo |
|---|---|---|
| Tema inicial | `libs/shiny/R/app.R:35-41` | reemplaza `tema_inicial <- bs_theme(...)` |
| Cargar `custom.scss` | `app.R:35-41` | añade `|> bs_add_rules(sass::sass_file(...))` |
| Switcher de temas | `app.R:95-100` (`cambiar_tema`) | extiende con nuevos `observeEvent` |
| Modo oscuro toggle | nuevo `checkboxInput` + `observe` | ver ejemplo sección 4 |

## Gotchas

- `bs_icon()` no está en bslib 0.9+ → usar `bsicons::bs_icon(...)`. Ya hecho.
- `font_google()` requiere conexión a internet **solo la primera vez**
  (cachea en `~/.cache/sass/`).
- `thematic` no es compatible con `httpgd` (device `unigd`); NO va en
  `.Rprofile`. Cada app lo activaría dentro de su `renderPlot()` si lo necesita.
- `bs_add_rules()` con variables Sass posteriores a Bootstrap (ej.
  `$secondary`) requiere `.where = "declarations"` vía `bs_add_variables()`.
