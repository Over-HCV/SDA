# learn/R/ui/f1/datos.R
#
# Responsabilidad: cablear la fase 1. No calcula ni dibuja nada por su cuenta.
#
# Cada subsección vive en su propio archivo (C2) y expone cuatro funciones que
# comparten el namespace de este módulo, igual que f2/catalogo.R:
#
#   controles_<x>(ns)                 lo que va al sidebar, ESTÁTICO
#   actualizar_<x>(session, ds)       rellena sus opciones cuando hay dataset
#   salida_<x>(ns)                    lo que va al cuerpo de la pestaña
#   servidor_<x>(input, output, session, ...)
#
# Los controles se construyen UNA vez y se muestran por pestaña con
# `conditionalPanel`; sus opciones se rellenan con `update*Input`. La versión
# anterior rendía el sidebar entero con renderUI al cambiar de pestaña, y ahí
# apareció un bug real: el HTML se insertaba pero Shiny no volvía a enlazar los
# controles — `input$clases` no existía nunca y ningún error salía por consola.
# Un control sin binding es exactamente el fallo silencioso de cliente que
# describe S2b, y por eso test_app.R ahora mueve un slider de cada subsección.
#
# El estado vive en dos reactiveVal:
#   datos_base  el data.frame como se cargó, sin transformar
#   dataset     el objeto Dataset actual (nucleo/estado.R)
# La pila de transformaciones se aplica siempre desde datos_base, que es lo
# que hace que "deshacer" sea exacto y no aproximado.

SUBSECCIONES_DATOS <- c("Fuente", "Diccionario", "Calidad", "Transformación",
                        "Partición", "Balanceo", ETIQUETA_ANALISIS)

mod_datos_ui <- function(id) {
  ns <- shiny::NS(id)
  subsecciones <- list(
    "Fuente"         = salida_fuente(ns),
    "Diccionario"    = salida_diccionario(ns),
    "Calidad"        = salida_calidad(ns),
    "Transformación" = salida_transformacion(ns),
    "Partición"      = salida_particion(ns),
    "Balanceo"       = salida_balanceo(ns))
  subsecciones[[ETIQUETA_ANALISIS]] <- salida_analisis(ns)

  armazon_fase(controles = .sidebar_datos(ns),
               subsecciones = subsecciones,
               estado = shiny::uiOutput(ns("estado")),
               id_pestanas = ns("pestana"))
}

# Un bloque de controles por subsección, todos presentes desde el arranque y
# visibles de a uno. La condición se escribe contra el id sin namespace: el
# argumento `ns` de conditionalPanel se encarga de traducirla.
.sidebar_datos <- function(ns) {
  visible_en <- function(pestana, contenido)
    shiny::conditionalPanel(
      sprintf("input.pestana == '%s'", pestana), ns = ns, contenido)

  shiny::tagList(
    visible_en("Fuente", controles_fuente(ns)),
    visible_en("Diccionario", controles_diccionario(ns)),
    visible_en("Calidad", controles_calidad(ns)),
    visible_en("Transformación", controles_transformacion(ns)),
    visible_en("Partición", controles_particion(ns)),
    visible_en("Balanceo", controles_balanceo(ns)),
    visible_en(ETIQUETA_ANALISIS, controles_analisis(ns)),
    .controles_comunes(ns))
}

mod_datos_server <- function(id, almacen = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    datos_base <- shiny::reactiveVal(NULL)
    dataset <- shiny::reactiveVal(NULL)
    usar_todo <- shiny::reactiveVal(FALSE)

    # Muestra de dibujo compartida por todas las subsecciones (C8). Las
    # métricas nunca la usan: se calculan sobre dataset()$df completo.
    muestreo <- shiny::reactive({
      ds <- dataset()
      shiny::req(ds)
      muestrear_para_grafico(ds$df, semilla = ds$semilla,
                             usar_todo = usar_todo())
    })
    shiny::observeEvent(input$usar_todo, usar_todo(TRUE))
    shiny::observeEvent(dataset(), usar_todo(FALSE))

    # Las opciones de todo selector de columnas se rellenan acá, en un solo
    # lugar: el dataset cambia de forma con cada transformación.
    shiny::observeEvent(dataset(), {
      ds <- dataset()
      shiny::req(ds)
      previos <- shiny::isolate(shiny::reactiveValuesToList(input))
      actualizar_diccionario_ui(session, ds, previos)
      actualizar_calidad(session, ds, previos)
      actualizar_transformacion(session, ds, previos)
      actualizar_particion(session, ds, previos)
      actualizar_balanceo(session, ds, previos)
      actualizar_analisis(session, ds, previos)
    })

    output$estado <- shiny::renderUI(.franja_dataset(dataset()))

    servidor_fuente(input, output, session, datos_base, dataset)
    servidor_diccionario(input, output, session, dataset)
    servidor_calidad(input, output, session, dataset, muestreo)
    servidor_transformacion(input, output, session, datos_base, dataset)
    servidor_particion(input, output, session, dataset)
    servidor_balanceo(input, output, session, dataset, muestreo)
    servidor_analisis(input, output, session, dataset, muestreo)

    shiny::observeEvent(input$guardar, {
      ds <- dataset()
      shiny::req(ds, !is.null(almacen))
      guardado <- almacen_agregar(almacen(), ds)
      almacen(guardado)
      dataset(almacen_obtener(guardado, "dataset", attr(guardado, "id_nuevo")))
      shiny::showNotification(
        sprintf("Dataset guardado como %s", attr(guardado, "id_nuevo")),
        type = "message", duration = 3)
    })
  })
}

# Controles presentes en todas las pestañas: el dataset activo se guarda desde
# cualquier punto de la fase, no solo desde Fuente.
.controles_comunes <- function(ns) {
  shiny::tagList(
    shiny::tags$hr(),
    shiny::actionButton(ns("guardar"), "Guardar en Objetos",
                        class = "btn-outline-primary btn-sm w-100",
                        icon = shiny::icon("save")),
    shiny::tags$p(class = "text-muted small mt-2 mb-0",
                  "Queda disponible para la fase 4 y para exportar."))
}

#' Utilidad compartida: rellena un selector sin perder lo ya elegido.
.rellenar_selector <- function(session, id, opciones, previo = NULL) {
  seleccionado <- if (!is.null(previo) && previo %in% opciones) previo
                  else if (length(opciones)) opciones[1] else NULL
  shiny::updateSelectInput(session, id, choices = opciones,
                           selected = seleccionado)
}

# Franja inferior: solo valores que cambian (C5).
.franja_dataset <- function(ds) {
  if (is.null(ds))
    return(franja_estado(list("dataset" = "sin cargar")))
  diccionario <- ds$diccionario
  faltantes <- round(mean(vapply(ds$df, function(columna)
    mean(is.na(columna)), numeric(1))) * 100, 2)
  franja_estado(list(
    "n" = format(ds$n, big.mark = ".", decimal.mark = ","), "p" = ds$p,
    "faltantes" = paste0(faltantes, " %"),
    "numericas" = sum(diccionario$clase %in% c("discreta", "continua")),
    "cualitativas" = sum(diccionario$clase == "cualitativa"),
    "transformaciones" = length(ds$transformaciones),
    "particion" = if (is.null(ds$particion)) "ninguna" else ds$particion$tipo,
    "balanceo" = if (is.null(ds$balanceo)) "ninguno" else ds$balanceo$metodo))
}

# Badge de muestreo listo para el encabezado de un panel (C8).
.badge_de_muestreo <- function(ns, muestra) {
  if (is.null(muestra)) return(NULL)
  badge_muestreo(muestra$n_total, muestra$n_muestra, muestra$semilla,
                 id_boton = ns("usar_todo"))
}
