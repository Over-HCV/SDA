# learn/R/app.R
#
# Responsabilidad: SOLO cablear. Cero estadística, cero HTML de contenido.
#
# Como correr, desde la raíz del repo:
#   Rscript -e 'shiny::runApp("learn/R/app.R", launch.browser = TRUE)'
#
# Variables de entorno (ver README.md):
#   SDA_TEMA=retro   preset inicial
#   SDA_MODO=wasm    fuerza el camino del navegador sin exportar el bundle
#   SDA_THEMER=1     monta el widget bs_themer() de bslib

# El directorio de trabajo depende de quién arranca la app: shiny::runApp lo
# pone en learn/R/, el wrapper de shinylive en la raíz del bundle. Se prueban
# las tres ubicaciones posibles en vez de suponer una.
local({
  candidatas <- c("cargar.R", "R/cargar.R", "learn/R/cargar.R")
  encontrada <- Find(file.exists, candidatas)
  if (is.null(encontrada))
    stop("No se encontró cargar.R desde: ", getwd())
  source(encontrada, local = FALSE)
})

cargar_sda(con_ui = TRUE)
cargar_librerias_ui()

TEMA_INICIAL <- Sys.getenv("SDA_TEMA", "flatly")

# --- UI --------------------------------------------------------------------
ui <- bslib::page_navbar(
  id = "seccion",
  title = "SDA Lab",
  theme = tema_seguro(TEMA_INICIAL),
  navbar_options = bslib::navbar_options(bg = "#0B1623", type = "dark"),
  fillable = FALSE,

  # KaTeX, una vez para toda la app. No pinta nada por sí sola: engancha el JS
  # y el CSS que convierten en matemáticas los nodos que deja
  # R/nucleo/formulas.R. Ver R/ui/piezas/formulas.R.
  header = dependencia_formulas(),

  bslib::nav_panel("Inicio", icon = bsicons::bs_icon("house"),
                   mod_inicio_ui("inicio")),
  bslib::nav_panel("① Datos",      mod_datos_ui("datos")),
  bslib::nav_panel("② Modelado",   mod_modelado_ui("modelado")),
  bslib::nav_panel("③ Ajuste",     mod_ajuste_ui("ajuste")),
  bslib::nav_panel("④ Evaluación", mod_evaluacion_ui("evaluacion")),

  bslib::nav_spacer(),

  bslib::nav_panel("Objetos", icon = bsicons::bs_icon("box-seam"),
                   mod_objetos_ui("objetos")),
  bslib::nav_panel("Referencia", icon = bsicons::bs_icon("info-circle"),
                   mod_referencia_ui("referencia")),

  # Un actionLink por preset de libs/_comun/R/temas_bslib.R. Añadir un tema
  # allí lo hace aparecer acá sin tocar este archivo.
  bslib::nav_menu(
    "Tema", align = "right", icon = bsicons::bs_icon("palette"),
    !!!lapply(temas_disponibles(), function(nombre) {
      bslib::nav_item(shiny::actionLink(
        paste0("tema_", gsub("-", "_", nombre)), nombre))
    })),

  bslib::nav_item(badge_modo())
)

# --- Server ----------------------------------------------------------------
server <- function(input, output, session) {

  if (Sys.getenv("SDA_THEMER", "0") != "0") bslib::bs_themer()

  # Estado de la sesión: un almacén PURO dentro de un reactiveVal. Cada
  # operación del CRUD lo reemplaza entero, y eso es lo que dispara la
  # invalidación. Ver R/nucleo/almacen.R.
  almacen <- shiny::reactiveVal(nuevo_almacen())

  mod_inicio_server("inicio", almacen)
  mod_datos_server("datos", almacen)
  mod_modelado_server("modelado", almacen)
  mod_ajuste_server("ajuste", almacen)
  mod_evaluacion_server("evaluacion", almacen)
  mod_objetos_server("objetos", almacen)
  mod_referencia_server("referencia")

  # cambiar_tema() reconstruye el preset COMPLETO en vez de usar
  # bs_theme_update(), para que las reglas Sass y las fuentes del tema anterior
  # no queden pegadas (ver libs/_comun/R/temas_bslib.R). La versión _seguro
  # además evita font_google() en el navegador (ver nucleo/tema_app.R).
  lapply(temas_disponibles(), function(nombre) {
    id <- paste0("tema_", gsub("-", "_", nombre))
    shiny::observeEvent(input[[id]], cambiar_tema_seguro(session, nombre),
                        ignoreInit = TRUE)
  })
}

shiny::shinyApp(ui, server)
