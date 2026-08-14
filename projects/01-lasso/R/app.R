# projects/01-lasso/R/app.R
#
# Proyecto 01 — Seleccion de variables con penalizacion LASSO sobre twins.csv.
# (Fila 23 de libs/topics-map.md.)
#
# Este archivo SOLO cablea. Toda la logica esta en modelo.R (pura) y toda la
# reactividad en mod_main.R.
#
# Como correr (desde la raiz del proyecto):
#   Rscript -e 'shiny::runApp("projects/01-lasso/R/app.R", launch.browser=TRUE)'
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
  source(file.path(.raiz, "projects", "01-lasso", "R", f))

suppressPackageStartupMessages({
  library(shiny); library(bslib); library(DT)
  library(ggplot2); library(patchwork)
})

TEMA_INICIAL <- Sys.getenv("SDA_TEMA", "flatly")

ui <- page_navbar(
  id = "tab",
  title = "01 · LASSO sobre twins",
  navbar_options = navbar_options(bg = "#0B1623", type = "dark"),
  theme = tema(TEMA_INICIAL),
  header = tags$head(tags$style(".value-box {min-height: 110px;}")),

  nav_panel("Modelo", mod_main_ui("main")),

  nav_panel(
    "Acerca de",
    card(
      card_header("Que hace este proyecto"),
      card_body(
        p(strong("Tema:"), " Seleccion de variables con penalizacion LASSO ",
          "(", code("glmnet::glmnet"), ", alpha = 1)."),
        p(strong("Datos:"), " ", code("data/twins.csv"), " — 183 pares de ",
          "gemelos, 16 variables. La respuesta habitual es ",
          code("DLHRWAGE"), " (diferencia en log-salario horario), que tiene ",
          "34 faltantes; quedan 147 casos completos con los predictores por ",
          "defecto."),
        p(strong("Hook interactivo:"), " el slider de ", code("lambda"),
          " en escala log. Al subirlo, la penalizacion L1 lleva coeficientes ",
          "exactamente a cero y el contador de activos baja en vivo. Con ",
          code("alpha = 0"), " (ridge) los coeficientes se encogen pero ",
          "nunca se anulan: es la diferencia que el tema quiere mostrar."),
        p(strong("Ojo con el R2:"), " con regularizacion no es una medida de ",
          "ajuste honesta. La metrica que manda para elegir lambda es el ",
          "MSE de validacion cruzada."),
        hr(),
        p("Contrato headless (S2):"),
        tags$pre(
          'Rscript -e \'source("projects/01-lasso/R/run_headless.R");\n',
          '            correr("lasso-base", alpha=1)\''
        ),
        tags$pre("Rscript projects/01-lasso/R/test_headless.R   # regresion")
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
