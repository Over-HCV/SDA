# learn/R/ui/transversal/sesion.R
#
# Guardar y abrir una sesión, desde donde se la busque.
#
# Vivía entero en la barra de ⚙ Objetos y nadie lo encontraba: se recargaba la
# página y se perdía el filtro, el diccionario y los paneles marcados. Ahora es
# un componente y lo ponen Inicio y Objetos; el cómo se serializa sigue en
# nucleo/sesion.R y nucleo/exportar.R, sin Shiny.
#
# El navegador no guarda nada solo. Lo que sí hace este archivo es llevar la
# cuenta de si hay cambios sin guardar, para que Inicio lo diga y para que el
# navegador pregunte antes de cerrar o recargar (www/salida.js).

#' El script que pregunta antes de salir con cambios sin guardar.
dependencia_salida <- function() {
  htmltools::htmlDependency(
    name = "sda-salida", version = "1.0.0",
    src = c(file = ruta_app("www")), script = "salida.js",
    # Solo este archivo: con all_files la carpeta arrastraría KaTeX otra vez.
    all_files = FALSE)
}

#' Las sesiones que trae la app, listas para un selector: nombre -> ruta.
sesiones_de_ejemplo <- function(carpeta = ruta_app("sesiones")) {
  archivos <- sort(list.files(carpeta, pattern = "[.](json|rds)$",
                              full.names = TRUE, ignore.case = TRUE))
  stats::setNames(archivos, tools::file_path_sans_ext(basename(archivos)))
}

controles_sesion <- function(ns) {
  ejemplos <- sesiones_de_ejemplo()
  shiny::tagList(
    shiny::div(
      class = "d-flex gap-2 mb-2",
      shiny::downloadButton(ns("bajar_json"), "Guardar JSON",
                            class = "btn-sm btn-primary flex-fill"),
      shiny::downloadButton(ns("bajar_rds"), "Guardar RDS",
                            class = "btn-sm btn-outline-primary flex-fill")),
    shiny::fileInput(ns("subir"), "Abrir sesión guardada", width = "100%",
                     accept = c(".json", ".rds"), buttonLabel = "Elegir"),
    if (length(ejemplos)) shiny::tagList(
      shiny::tags$label(class = "form-label", `for` = ns("ejemplo"),
                        "O una de ejemplo"),
      shiny::div(
        class = "d-flex gap-2 align-items-start mb-3",
        shiny::div(class = "flex-grow-1",
                   shiny::selectInput(ns("ejemplo"), NULL, width = "100%",
                                      choices = names(ejemplos))),
        shiny::actionButton(ns("abrir_ejemplo"), "Abrir",
                            class = "btn-outline-secondary"))),
    shiny::uiOutput(ns("estado_guardado")),
    plegable("¿JSON o RDS?", shiny::tags$div(
      class = "small",
      shiny::tags$p(shiny::tags$strong("JSON"), " viaja entre máquinas y lo",
                    " puede leer un agente. Guarda la receta de ① Datos",
                    " (fuente, pila, diccionario, balanceo, partición, paneles",
                    " y lecturas) y la rehace al abrir; las corridas vuelven",
                    " sin el objeto ajustado."),
      shiny::tags$p(class = "mb-0", shiny::tags$strong("RDS"), " conserva",
                    " todo exactamente, corridas incluidas, pero solo lo abre R."))))
}

#' Si hay cambios sin guardar. Se compara una HUELLA del estado —lo mismo que
#' iría al archivo, sin la hora de exportación— contra la del último guardado o
#' abierto: escribir algo y borrarlo vuelve a "guardada", y abrir una sesión no
#' cuenta como cambio aunque mueva el dataset y la selección.
#'
#' Es un environment para que app.R, Inicio y Objetos compartan el mismo.
nuevo_estado_guardado <- function() {
  estado <- new.env(parent = emptyenv())
  estado$huella <- shiny::reactiveVal(NULL)     # la del último guardado/abierto
  estado$guardada <- shiny::reactiveVal(NULL)   # hora, para mostrar
  estado$actual <- function() NULL              # lo reemplaza vigilar_cambios()
  estado$pendiente <- function() FALSE          # idem
  estado
}

.huella_sesion <- function(almacen, dataset, seleccion, cuaderno) {
  sesion <- sesion_actual(almacen, dataset, seleccion, cuaderno)
  sesion$exportado <- NULL
  sesion
}

#' Engancha la huella a los reactiveVal de app.R y le avisa al navegador si
#' tiene que preguntar antes de salir. Se llama una vez, en app.R.
vigilar_cambios <- function(session, almacen, dataset, seleccion, cuaderno,
                            guardado) {
  guardado$actual <- function()
    .huella_sesion(almacen(), dataset(), seleccion(), cuaderno())
  pendiente <- shiny::reactive({
    objetos <- sum(vapply(TIPOS_OBJETO, function(tipo)
      almacen_contar(almacen(), tipo), integer(1)))
    hay_algo <- !is.null(dataset()) || length(seleccion()) > 0L || objetos > 0L
    hay_algo && !identical(guardado$actual(), guardado$huella())
  })
  guardado$pendiente <- pendiente
  shiny::observe({
    session$sendCustomMessage("sda-salida", list(avisar = isTRUE(pendiente())))
  })
  invisible(guardado)
}

.marcar_guardada <- function(guardado) {
  if (is.null(guardado)) return(invisible(NULL))
  guardado$huella(shiny::isolate(guardado$actual()))
  guardado$guardada(format(Sys.time(), "%H:%M"))
  invisible(NULL)
}

#' Abre un archivo de sesión y lo aplica. Lo usan el fileInput, las sesiones de
#' ejemplo y `?sesion=` de la URL.
#'
#' @return el mensaje para quien abrió, o NULL si falló (ya se notificó)
abrir_sesion_en <- function(ruta, nombre, almacen, dataset, seleccion,
                            cuaderno = NULL, guardado = NULL) {
  recuperado <- tryCatch({
    if (grepl("[.]rds$", nombre, ignore.case = TRUE))
      importar_sesion_rds(ruta) else importar_sesion_json(ruta)
  }, error = function(e) {
    shiny::showNotification(paste("No se pudo abrir la sesión:",
                                  conditionMessage(e)),
                            type = "error", duration = 8)
    NULL
  })
  if (is.null(recuperado)) return(invisible(NULL))
  # Una sesión sin objetos guardados trae el almacén vacío ({} en el JSON):
  # ponerlo tal cual dejaba un almacén sin contadores ni colecciones.
  if (length(recuperado$almacen$contadores)) almacen(recuperado$almacen)
  mensaje <- restaurar_fase1_en(recuperado$fase1, dataset, seleccion,
                                cuaderno)
  .marcar_guardada(guardado)
  shiny::showNotification(mensaje, type = "message", duration = 6)
  invisible(mensaje)
}

#' @param almacen,dataset,seleccion,cuaderno los reactiveVal de app.R
#' @param guardado nuevo_estado_guardado(), o NULL
servidor_sesion <- function(input, output, session, almacen, dataset,
                            seleccion, cuaderno = NULL, guardado = NULL) {
  .sesion <- function() sesion_actual(
    almacen(),
    if (is.null(dataset)) NULL else dataset(),
    if (is.null(seleccion)) list() else seleccion(),
    cuaderno = if (is.null(cuaderno)) NULL else cuaderno())

  output$bajar_json <- shiny::downloadHandler(
    filename = function() nombre_descarga("sesion", "json"),
    content = function(archivo) {
      exportar_sesion_json(.sesion(), archivo)
      .marcar_guardada(guardado)
    })

  output$bajar_rds <- shiny::downloadHandler(
    filename = function() nombre_descarga("sesion", "rds"),
    content = function(archivo) {
      exportar_sesion_rds(.sesion(), archivo)
      .marcar_guardada(guardado)
    })

  shiny::observeEvent(input$subir, {
    abrir_sesion_en(input$subir$datapath, input$subir$name, almacen, dataset,
                    seleccion, cuaderno, guardado)
  })

  shiny::observeEvent(input$abrir_ejemplo, {
    ejemplos <- sesiones_de_ejemplo()
    ruta <- ejemplos[[input$ejemplo]]
    shiny::req(ruta)
    abrir_sesion_en(ruta, basename(ruta), almacen, dataset, seleccion,
                    cuaderno,
                    guardado)
  })

  output$estado_guardado <- shiny::renderUI({
    if (is.null(guardado)) return(NULL)
    if (isTRUE(guardado$pendiente()))
      return(shiny::tags$p(class = "small text-warning-emphasis mb-2",
                           bsicons::bs_icon("exclamation-circle"),
                           " Cambios sin guardar: recargar la página los pierde."))
    hora <- guardado$guardada()
    if (!is.null(hora))
      shiny::tags$p(class = "small text-muted mb-2",
                    bsicons::bs_icon("check2"), sprintf(" Guardada o abierta a las %s.", hora))
  })
  invisible(NULL)
}
