# libs/shiny/R/app.R
#
# Punto de entrada de la app Shiny. SOLO cablea UI + modulos + extras
# (theme switcher, bookmarking, notificaciones globales).
# Toda la logica de negocio esta en modelo.R (funciones puras).
#
# La app tiene dos mitades:
#   - ANALISIS  (mod_*.R)  : regresion sobre charcoal. El contenido real.
#   - GALERIA   (gal_*.R)  : catalogo de componentes Shiny + bslib bajo el
#                            tema activo. Es la referencia visual del curso.
#
# Como correr (desde la raiz del proyecto):
#   Rscript -e 'shiny::runApp("libs/shiny/R/app.R", launch.browser = TRUE)'
#
# Variables de entorno:
#   SDA_TEMA=retro     preset inicial (ver listar_temas() en temas_bslib.R)
#   SDA_THEMER=1       activa el widget "Theme customizer" (bs_themer)

# --- Bootstrap del proyecto ----------------------------------------------
.raiz <- (function() {
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "data", "charcoal.csv")) ||
        file.exists(file.path(d, "renv", "activate.R"))) return(d)
    p <- dirname(d); if (p == d) stop("Raiz SDA no encontrada desde: ", getwd())
    d <- p
  }
})()

for (f in c("datos.R", "metricas.R", "temas.R", "temas_bslib.R"))
  source(file.path(.raiz, "libs", "_comun", "R", f))
for (f in c("datos.R", "modelo.R",
            "mod_ajuste.R", "mod_diagnostico.R", "mod_datos.R", "mod_resumen.R",
            "gal_inputs.R", "gal_layout.R", "gal_plots.R",
            "gal_tablas.R", "gal_feedback.R", "gal_tipografia.R"))
  source(file.path(.raiz, "libs", "shiny", "R", f))

suppressPackageStartupMessages({
  library(shiny); library(bslib); library(DT)
  library(ggplot2); library(patchwork)
})

TEMA_INICIAL <- Sys.getenv("SDA_TEMA", "flatly")

# --- UI ------------------------------------------------------------------
ui <- page_navbar(
  id = "tab",
  title = "SDA · Regresion sobre charcoal",
  navbar_options = navbar_options(bg = "#0B1623", type = "dark"),
  theme = tema(TEMA_INICIAL),
  header = tags$head(tags$style(".value-box {min-height: 110px;}")),

  # --- Analisis ---------------------------------------------------------
  nav_panel("Ajuste",       mod_ajuste_ui("ajuste")),
  nav_panel("Diagnosticos", mod_diagnostico_ui("diag")),
  nav_panel("Datos",        mod_datos_ui("datos")),
  nav_panel("Resumen",      mod_resumen_ui("resumen")),

  # --- Galeria de componentes -------------------------------------------
  nav_menu(
    "Galeria", icon = bsicons::bs_icon("grid-3x3-gap"),
    nav_panel("Inputs",         gal_inputs_ui("g_inputs")),
    nav_panel("Cards",          gal_layout_ui("g_layout")),
    nav_panel("Plots",          gal_plots_ui("g_plots")),
    nav_panel("Tablas",         gal_tablas_ui("g_tablas")),
    nav_panel("Notificaciones", gal_feedback_ui("g_feedback")),
    nav_panel("Tipografia",     gal_tipografia_ui("g_tipo"))
  ),

  nav_spacer(),

  # Un actionLink por preset declarado en temas_bslib.R. Agregar un tema alli
  # lo hace aparecer aca sin tocar este archivo.
  nav_menu(
    "Tema", align = "right", icon = bsicons::bs_icon("palette"),
    !!!lapply(listar_temas(), function(nm) {
      nav_item(actionLink(paste0("tema_", gsub("-", "_", nm)), nm))
    })
  ),

  fillable = FALSE
)

# --- Server --------------------------------------------------------------
server <- function(input, output, session) {

  # Widget "Theme customizer" de la vinieta de theming de bslib. Al moverlo,
  # imprime en la consola de R el bs_theme() equivalente.
  # Off por defecto: interfiere con el switcher de presets de abajo.
  if (Sys.getenv("SDA_THEMER", "0") != "0") bslib::bs_themer()

  # --- Analisis ---------------------------------------------------------
  # mod_ajuste devuelve un reactiveValues con datos/ajuste/brush que los
  # otros tres modulos consumen.
  estado <- mod_ajuste_server("ajuste")
  mod_diagnostico_server("diag", estado)
  mod_datos_server("datos", estado)
  mod_resumen_server("resumen", estado)

  # --- Galeria ----------------------------------------------------------
  gal_inputs_server("g_inputs")
  gal_layout_server("g_layout")
  gal_plots_server("g_plots")
  gal_tablas_server("g_tablas")
  gal_feedback_server("g_feedback")
  gal_tipografia_server("g_tipo")

  # --- Theme switcher ---------------------------------------------------
  # cambiar_tema() vive en _comun/R/temas_bslib.R y reconstruye el preset
  # COMPLETO (no bs_theme_update), para que las reglas Sass y las fuentes del
  # preset anterior no queden pegadas al cambiar.
  lapply(listar_temas(), function(nm) {
    id <- paste0("tema_", gsub("-", "_", nm))
    observeEvent(input[[id]], cambiar_tema(session, nm), ignoreInit = TRUE)
  })

  # --- Bookmarking automatico en cada cambio de tab --------------------
  observeEvent(input$tab, {
    session$doBookmark()
  })
  onBookmarked(function(url) {
    updateQueryString(url)
  })
}

# --- Arranque ------------------------------------------------------------
shinyApp(ui, server, enableBookmarking = "server")
