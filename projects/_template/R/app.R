# projects/__SLUG__/R/app.R
#
# __TITULO__
#
# Este archivo SOLO cablea. La logica esta en modelo.R (pura) y la
# reactividad en mod_main.R.
#
# Como correr (desde la raiz del proyecto):
#   Rscript -e 'shiny::runApp("projects/__SLUG__/R/app.R", launch.browser=TRUE)'
#
# Variables de entorno:
#   SDA_TEMA=retro     preset inicial (ver listar_temas() en _comun/temas_bslib.R)
#   SDA_THEMER=1       widget bs_themer de theming en vivo

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
for (f in c("datos.R", "modelo.R", "run_headless.R", "mod_main.R"))
  source(file.path(.raiz, "projects", "__SLUG__", "R", f))

suppressPackageStartupMessages({
  library(shiny); library(bslib); library(DT)
  library(ggplot2); library(patchwork)
})

TEMA_INICIAL <- Sys.getenv("SDA_TEMA", "flatly")

ui <- page_navbar(
  id = "tab",
  title = "__TITULO__",
  navbar_options = navbar_options(bg = "#0B1623", type = "dark"),
  theme = tema(TEMA_INICIAL),
  header = tags$head(tags$style(".value-box {min-height: 110px;}")),

  nav_panel("Modelo", mod_main_ui("main")),

  nav_panel(
    "Acerca de",
    card(
      card_header("Que hace este proyecto"),
      card_body(
        # TODO: completar. Como minimo: tema, datos, hook interactivo y
        # una advertencia de interpretacion si el metodo tiene alguna.
        p(strong("Tema:"), " TODO"),
        p(strong("Datos:"), " TODO"),
        p(strong("Hook interactivo:"), " TODO"),
        hr(),
        tags$pre(
          'Rscript -e \'source("projects/__SLUG__/R/run_headless.R");\n',
          '            correr("demo")\''
        ),
        tags$pre("Rscript projects/__SLUG__/R/test_headless.R")
      )
    )
  ),

  nav_spacer(),

  nav_menu(
    "Tema", align = "right", icon = bsicons::bs_icon("palette"),
    !!!lapply(listar_temas(), function(nm) {
      nav_item(actionLink(paste0("tema_", gsub("-", "_", nm)), nm))
    })
  ),

  fillable = FALSE
)

server <- function(input, output, session) {

  if (Sys.getenv("SDA_THEMER", "0") != "0") bslib::bs_themer()

  mod_main_server("main")

  lapply(listar_temas(), function(nm) {
    id <- paste0("tema_", gsub("-", "_", nm))
    observeEvent(input[[id]], cambiar_tema(session, nm), ignoreInit = TRUE)
  })
}

shinyApp(ui, server)
