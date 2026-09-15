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
#   SDA_SESION=ruta  abre la app con una sesión ya restaurada
#
# En el navegador la sesión se pide por URL: `?sesion=sesiones/taller-00.json`
# (una ruta dentro del bundle). Es el camino que sobrevive en wasm, donde no
# hay variables de entorno ni disco del usuario.

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
  header = shiny::tagList(dependencia_formulas(), dependencia_salida()),

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
  bslib::nav_panel("Informe", icon = bsicons::bs_icon("download"),
                   mod_informe_ui("informe")),

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

  # Paneles marcados con la casilla "Añadir": la pestaña Informe los convierte
  # en un cuaderno .Rmd. Vive acá para que Datos (que los marca) e Informe
  # (que los exporta) compartan el mismo estado toda la sesión.
  seleccion <- shiny::reactiveVal(list())

  # Piezas del cuaderno y cambios sin guardar: los dos viajan con la sesión y
  # los leen varias pestañas (Inicio, Objetos, Informe).
  cuaderno <- shiny::reactiveVal(opciones_cuaderno())
  guardado <- nuevo_estado_guardado()

  estado_datos <- mod_datos_server("datos", almacen, seleccion)
  mod_inicio_server("inicio", almacen, estado_datos$dataset, seleccion,
                    cuaderno, guardado)
  mod_modelado_server("modelado", almacen)
  mod_ajuste_server("ajuste", almacen)
  mod_evaluacion_server("evaluacion", almacen)
  mod_objetos_server("objetos", almacen, estado_datos$dataset, seleccion,
                     cuaderno, guardado)
  mod_referencia_server("referencia")
  mod_informe_server("informe", seleccion, estado_datos$dataset, cuaderno)
  vigilar_cambios(session, almacen, estado_datos$dataset, seleccion, cuaderno,
                  guardado)

  # Arrancar con una sesión puesta: el caso de uso es entrar al lab y que el
  # dataset, el filtro, el diccionario y los paneles del taller ya estén,
  # en vez de rehacer catorce clics cada vez.
  shiny::observeEvent(session$clientData$url_search, {
    ruta <- .sesion_inicial(session$clientData$url_search)
    if (is.null(ruta)) return(invisible(NULL))
    bruto <- tryCatch(
      if (grepl("[.]rds$", ruta, ignore.case = TRUE)) importar_sesion_rds(ruta)
      else importar_sesion_json(ruta),
      error = function(e) {
        shiny::showNotification(paste("No se pudo abrir la sesión:",
                                      conditionMessage(e)),
                                type = "error", duration = 8)
        NULL
      })
    if (is.null(bruto)) return(invisible(NULL))
    if (length(bruto$almacen$contadores)) almacen(bruto$almacen)
    shiny::showNotification(
      restaurar_fase1_en(bruto$fase1, estado_datos$dataset, seleccion,
                         cuaderno),
      type = "message", duration = 6)
    .marcar_guardada(guardado)
  }, once = TRUE, ignoreNULL = FALSE)

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

#' La sesión con que arrancar, si la hay: primero `?sesion=` de la URL (el
#' camino que funciona en wasm), después SDA_SESION. La ruta se busca tal cual
#' y, si no está, dentro de learn/: así el mismo `?sesion=sesiones/x.json`
#' sirve en el bundle y en modo servidor.
.sesion_inicial <- function(busqueda = "") {
  pedida <- if (nzchar(busqueda %||% "")) {
    partes <- shiny::parseQueryString(busqueda)
    partes$sesion
  } else NULL
  pedida <- pedida %||% (if (nzchar(Sys.getenv("SDA_SESION")))
    Sys.getenv("SDA_SESION") else NULL)
  if (is.null(pedida) || !nzchar(pedida)) return(NULL)
  candidatas <- c(pedida, ruta_app(pedida))
  encontrada <- Find(file.exists, candidatas)
  if (is.null(encontrada))
    message("[sesion] no existe el archivo pedido: ", pedida)
  encontrada
}

shiny::shinyApp(ui, server)
