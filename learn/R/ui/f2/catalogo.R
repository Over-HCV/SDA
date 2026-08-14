# learn/R/ui/f2/catalogo.R
#
# Responsabilidad: la subsección Catálogo de la fase 2.
#
# Es la única vista con contenido real del Hito 1, y a propósito: se dibuja
# entera recorriendo el registro, así que si funciona, el mecanismo declarativo
# funciona. Nada de HTML escrito a mano por método.

#' Controles del catálogo. Van al sidebar de la fase (C4).
controles_catalogo <- function(ns) {
  sesiones <- sort(unique(stats::na.omit(metodos_df()$sesion)))
  shiny::tagList(
    shiny::textInput(ns("busqueda"), "Buscar", placeholder = "nombre o clave"),
    shiny::checkboxGroupInput(
      ns("objetivo"), "Objetivo",
      choices = stats::setNames(OBJETIVOS, ETIQUETA_OBJETIVO[OBJETIVOS])),
    shiny::checkboxGroupInput(
      ns("sesion"), "Sesión del curso",
      choices = stats::setNames(sesiones, paste("Sesión", sesiones)),
      inline = TRUE),
    shiny::checkboxGroupInput(
      ns("estado"), "Estado",
      choices = c("Listo" = "activo", "Pendiente" = "pendiente",
                  "Bloqueado" = "bloqueado")),
    shiny::checkboxInput(ns("solo_ejecutables"),
                         "Solo los que corren en este modo", FALSE),
    shiny::hr(),
    shiny::actionLink(ns("limpiar"), "Limpiar filtros",
                      class = "btn btn-sm btn-outline-secondary w-100")
  )
}

#' Hueco del catálogo en el cuerpo de la pestaña.
salida_catalogo <- function(ns) {
  shiny::tagList(
    shiny::uiOutput(ns("resumen_filtros")),
    shiny::uiOutput(ns("rejilla"))
  )
}

#' Claves que pasan los filtros vigentes.
#'
#' Pura respecto a Shiny salvo por leer `input`: la decisión de qué mostrar es
#' una consulta al registro, no lógica de UI.
claves_filtradas <- function(input) {
  claves <- filtrar_metodos(
    objetivo = if (length(input$objetivo)) input$objetivo else NULL,
    sesion   = if (length(input$sesion)) as.integer(input$sesion) else NULL,
    estado   = if (length(input$estado)) input$estado else NULL,
    busqueda = input$busqueda)
  if (isTRUE(input$solo_ejecutables)) claves <- Filter(ejecutable, claves)
  claves
}

#' Línea de resumen: cuántos se ven, cuántos hay, y por qué faltan los demás.
resumen_filtros <- function(visibles, totales) {
  bloqueados <- length(filtrar_metodos(estado = "bloqueado"))
  shiny::tags$div(
    class = "d-flex justify-content-between align-items-center mb-2",
    shiny::tags$span(class = "text-muted small",
                     sprintf("%d de %d métodos", visibles, totales)),
    shiny::tags$span(
      class = "text-muted small",
      sprintf("%d bloqueados se muestran igual, con su ficha y su puente",
              bloqueados))
  )
}

#' Cablea el catálogo dentro del server de la fase 2.
#'
#' @param al_elegir función(clave) que se llama al pulsar "Elegir"
servidor_catalogo <- function(input, output, session, al_elegir = NULL) {
  ns <- session$ns

  output$resumen_filtros <- shiny::renderUI(
    resumen_filtros(length(claves_filtradas(input)), length(claves_metodos())))

  output$rejilla <- shiny::renderUI(rejilla_metodos(claves_filtradas(input), ns))

  shiny::observeEvent(input$limpiar, {
    shiny::updateTextInput(session, "busqueda", value = "")
    for (id in c("objetivo", "sesion", "estado"))
      shiny::updateCheckboxGroupInput(session, id, selected = character(0))
    shiny::updateCheckboxInput(session, "solo_ejecutables", value = FALSE)
  })

  # Un observador por método, creados UNA vez al arrancar. Recrearlos en cada
  # filtrado dejaría observadores duplicados escuchando el mismo id.
  for (clave in claves_metodos()) {
    local({
      esta_clave <- clave
      shiny::observeEvent(input[[paste0("ficha_", esta_clave)]], {
        shiny::showModal(modal_ficha(esta_clave))
      }, ignoreInit = TRUE)
      shiny::observeEvent(input[[paste0("elegir_", esta_clave)]], {
        if (!is.null(al_elegir)) al_elegir(esta_clave)
        shiny::showNotification(
          sprintf("Método elegido: %s", metodo(esta_clave)$nombre),
          type = "message", duration = 3)
      }, ignoreInit = TRUE)
    })
  }
  invisible(TRUE)
}
