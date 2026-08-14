# libs/shiny-live/R/app.R
#
# Punto de entrada de la app Shiny. SO cablea UI + módulos + extras (theme
# switcher, modal de carga webR, bookmarking). Toda la lógica de negocio está
# en modelo.R (funciones puras).
#
# Cómo correr (desde la raíz del proyecto):
#   shiny::runApp("libs/shiny-live/R/app.R", launch.browser = TRUE)
#
# Nota webR: el bundle exportado por shinylive::export() lee este archivo vía
# el wrapper app.R de la raíz de libs/shiny-live/.

# --- Bootstrap del proyecto ----------------------------------------------
.raiz <- (function() {
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "data", "charcoal.csv")) ||
        file.exists(file.path(d, "renv", "activate.R"))) return(d)
    p <- dirname(d); if (p == d) stop("Raíz SDA no encontrada desde: ", getwd())
    d <- p
  }
})()

for (f in c("datos.R", "metricas.R", "temas.R"))
  source(file.path(.raiz, "libs", "_comun", "R", f))

# Directorio de los módulos de esta app. En el árbol de desarrollo es
# <raiz>/libs/shiny-live/R; en el bundle shinylive es <raiz>/R (build.R arma
# un mini-root donde la app ES la raíz). Se resuelve por sondeo para servir a
# los dos layouts sin duplicar código.
.dir_app <- local({
  cand <- c(file.path(.raiz, "libs", "shiny-live", "R"),
            file.path(.raiz, "R"), getwd())
  hit <- Filter(function(d) file.exists(file.path(d, "modelo.R")), cand)
  if (!length(hit)) stop("No se encontro R/modelo.R desde: ", getwd())
  hit[1]
})
for (f in c("datos.R", "modelo.R", "mod_anova.R", "mod_distribucion.R",
            "mod_potencia.R", "mod_resumen.R"))
  source(file.path(.dir_app, f))

suppressPackageStartupMessages({
  library(shiny); library(bslib); library(DT)
  library(ggplot2); library(bsicons)
})

# TRUE cuando la app corre dentro de webR (bundle shinylive). Se usa para
# desactivar lo que necesita servidor (bookmarking).
.es_webr <- identical(R.version$os, "emscripten")

# --- Tema bslib (sin font_google: en webR las fuentes externas fallan) ----
tema_inicial <- bslib::bs_theme(bootswatch = "flatly",
                                 `enable-gradients` = TRUE, `enable-shadows` = TRUE)

# --- UI ------------------------------------------------------------------
ui <- page_navbar(
  id = "tab",
  title = "SDA · ANOVA + distribuciones",
  navbar_options = navbar_options(bg = "#0B1623", type = "dark"),
  theme = tema_inicial,
  header = tags$head(tags$style(".value-box {min-height: 110px;}")),

  nav_panel("ANOVA",        mod_anova_ui("anova")),
  nav_panel("Distribución", mod_distribucion_ui("dist")),
  nav_panel("Potencia",     mod_potencia_ui("pot")),
  nav_panel("Resumen",      mod_resumen_ui("resumen")),

  nav_spacer(),
  nav_menu("Tema", align = "right", icon = bsicons::bs_icon("palette"),
           nav_item(actionLink("tema_flatly", "Flatly (claro)")),
           nav_item(actionLink("tema_darkly", "Darkly (oscuro)")),
           nav_item(actionLink("tema_cosmo",  "Cosmo"))),
  fillable = FALSE
)

# --- Server --------------------------------------------------------------
server <- function(input, output, session) {

  estado <- mod_anova_server("anova")
  mod_distribucion_server("dist", estado)
  mod_potencia_server("pot", estado)
  mod_resumen_server("resumen", estado)

  # --- Modal de carga webR ---------------------------------------------
  showModal(modalDialog(
    title = "Inicializando webR",
    tags$div(class = "text-center",
             # size debe ser una unidad CSS válida: "xl" revienta en
             # validateCssUnit() y tumba el render del modal.
             bsicons::bs_icon("hourglass-split", size = "3rem", class = "my-3"),
             tags$p("R se está cargando en el navegador vía WebAssembly.",
                    "Esto tarda ~10-30s la primera vez."),
             tags$small(class = "text-muted", "La app se habilitará al terminar.")),
    footer = NULL, fade = FALSE
  ))
  observeEvent(estado$resultado(), {
    removeModal()
  }, once = TRUE)

  # --- Theme switcher ---------------------------------------------------
  cambiar <- function(bootswatch) {
    nuevo <- bslib::bs_theme_update(session$getCurrentTheme(), bootswatch = bootswatch)
    session$setCurrentTheme(nuevo)
    showNotification(sprintf("Tema: %s", bootswatch), type = "message", duration = 2)
  }
  observeEvent(input$tema_flatly, cambiar("flatly"))
  observeEvent(input$tema_darkly, cambiar("darkly"))
  observeEvent(input$tema_cosmo,  cambiar("cosmo"))

  # --- Bookmarking (solo funciona en runApp nativo, no en bundle webR) -
  # En webR no hay servidor que persista el estado: cablearlo solo produce
  # errores en cada cambio de tab, así que se omite.
  if (!.es_webr) {
    observeEvent(input$tab, session$doBookmark())
    onBookmarked(function(url) updateQueryString(url))
  }
}

# --- Arranque ------------------------------------------------------------
shinyApp(ui, server,
         enableBookmarking = if (.es_webr) "disable" else "server")
