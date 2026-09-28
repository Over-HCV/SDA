# learn/R/ui/f2/especificacion.R
#
# Responsabilidad: subsección Especificación — qué columnas entran al modelo.
#
# Para un método no supervisado como el ACP la especificación es la lista de
# columnas X. Cuando entren los supervisados, acá se añade el bloque Y y el
# constructor de fórmula; la tabla de la matriz de diseño no cambia.
#
# Los controles se construyen una vez y se rellenan con update*Input (ver la
# cabecera de f1/datos.R: un sidebar rendido con renderUI deja los inputs sin
# binding y no lo avisa nadie).

controles_especificacion <- function(ns) {
  shiny::tagList(
    shiny::checkboxGroupInput(ns("columnas"), "Columnas del modelo (X)",
                              choices = character(0)),
    shiny::div(
      class = "d-flex gap-2",
      shiny::actionLink(ns("todas_columnas"), "Todas",
                        class = "btn btn-sm btn-outline-secondary w-100"),
      shiny::actionLink(ns("ninguna_columna"), "Ninguna",
                        class = "btn btn-sm btn-outline-secondary w-100")),
    shiny::uiOutput(ns("nota_columnas")))
}

#' Solo las columnas que el método admite: la escala del diccionario manda
#' también acá. Una nominal codificada con números no es una variable numérica,
#' y el ACP sobre códigos de país no significa nada — pero un ACM sobre esas
#' mismas columnas sí, y por eso quién se ofrece lo decide `entrada$tipo` del
#' método y no esta vista.
#'
#' @param tipo el `entrada$tipo` del método elegido
actualizar_especificacion <- function(session, ds, previos = list(),
                                      tipo = "matriz_numerica") {
  admisibles <- columnas_admisibles(ds, tipo)
  elegidas <- intersect(previos$columnas %||% admisibles, admisibles)
  shiny::updateCheckboxGroupInput(session, "columnas", choices = admisibles,
                                  selected = elegidas)
}

salida_especificacion <- function(ns) {
  panel_resultado(
    "f2.especificacion.matriz_diseno",
    shiny::tagList(
      shiny::uiOutput(ns("avisos_especificacion")),
      shiny::tableOutput(ns("matriz_diseno"))),
    contexto = salida_contexto(ns, "contexto_especificacion"))
}

#' @param tipo reactivo con el `entrada$tipo` del método elegido
servidor_especificacion <- function(input, output, session, dataset, columnas,
                                    tipo = NULL) {
  tipo_actual <- function() {
    if (is.null(tipo)) "matriz_numerica" else tipo() %||% "matriz_numerica"
  }

  output$nota_columnas <- shiny::renderUI({
    ds <- dataset()
    if (is.null(ds)) return(NULL)
    fuera <- setdiff(names(ds$df), columnas_admisibles(ds, tipo_actual()))
    if (!length(fuera)) return(NULL)
    shiny::tags$p(
      class = "text-muted small mt-2 mb-0",
      sprintf("Quedan fuera por su clase en el diccionario: %s.",
              paste(fuera, collapse = ", ")))
  })

  shiny::observeEvent(input$todas_columnas, {
    ds <- dataset(); shiny::req(ds)
    shiny::updateCheckboxGroupInput(
      session, "columnas", selected = columnas_admisibles(ds, tipo_actual()))
  })
  shiny::observeEvent(input$ninguna_columna, {
    shiny::updateCheckboxGroupInput(session, "columnas",
                                    selected = character(0))
  })

  output$matriz_diseno <- shiny::renderTable({
    ds <- dataset()
    shiny::validate(shiny::need(!is.null(ds),
                                "Elegí un dataset guardado en Objetos."))
    shiny::validate(shiny::need(length(columnas()) >= 1L,
                                "Marcá al menos una columna en el sidebar."))
    resumen_matriz_diseno(ds$df, columnas())
  }, colnames = FALSE, striped = TRUE, width = "100%")

  output$avisos_especificacion <- shiny::renderUI({
    ds <- dataset()
    if (is.null(ds) || length(columnas()) < 2L) return(NULL)
    tabla <- resumen_matriz_diseno(ds$df, columnas())
    rango <- tabla[tabla$campo == "rango", ]
    if (!grepl("colineales", rango$nota)) return(NULL)
    lista_avisos(list(list(
      severidad = "aviso", clave = "rango", mensaje = rango$nota,
      sugerencia = "Quitá una de las columnas repetidas y mirá si el rango sube.")))
  })

  dibujar_contexto(output, "f2.especificacion.matriz_diseno",
                   params = shiny::reactive({
                     ds <- dataset()
                     if (is.null(ds)) return(NULL)
                     list(dataset = ds$id, columnas = paste(columnas(),
                                                            collapse = ","),
                          n = ds$n, p = length(columnas()))
                   }),
                   sufijo = "contexto_especificacion")
  invisible(TRUE)
}
