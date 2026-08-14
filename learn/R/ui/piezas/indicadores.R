# learn/R/ui/piezas/indicadores.R
#
# Responsabilidad: los elementos chicos que informan estado.
#
# Todos comparten una regla: solo muestran cosas que CAMBIAN (C5). Un badge
# que siempre dice lo mismo es ruido con estilo.

#' Franja de estado de una fase: una línea, valores vivos, nada más.
#'
#' @param items lista con nombre: list("n" = 35115, "faltantes" = "0.4 %")
franja_estado <- function(items) {
  if (!length(items)) return(NULL)
  piezas <- lapply(names(items), function(etiqueta) {
    shiny::tags$span(
      class = "me-3",
      shiny::tags$span(class = "text-muted small", etiqueta), " ",
      shiny::tags$strong(as.character(items[[etiqueta]]))
    )
  })
  shiny::tags$div(
    class = "border-top pt-2 mt-2 d-flex flex-wrap align-items-center",
    piezas
  )
}

#' Aviso de muestreo (C8). Aparece SOLO cuando de verdad se muestreó.
#'
#' Truncar sin decirlo convierte un gráfico en una mentira, así que este badge
#' no es cortesía: es parte del contrato con quien mira.
badge_muestreo <- function(n_total, n_muestra, semilla, id_boton = NULL) {
  if (n_muestra >= n_total) return(NULL)
  shiny::tags$span(
    class = "badge bg-warning text-dark d-inline-flex align-items-center gap-1",
    bsicons::bs_icon("funnel"),
    sprintf("graficando %s de %s · semilla %s",
            format(n_muestra, big.mark = "."),
            format(n_total, big.mark = "."), semilla),
    if (!is.null(id_boton))
      shiny::actionLink(id_boton, "usar todo", class = "link-dark ms-1")
  )
}

#' Badge de estado de un método: activo, pendiente o bloqueado.
#'
#' Sin iconos de candado: un método no ejecutable ya se distingue porque su
#' tarjeta está atenuada y su botón deshabilitado. Añadir un candado encima
#' repite el mensaje y ensucia una rejilla de 54 tarjetas.
badge_estado <- function(estado, wasm = TRUE) {
  config <- switch(estado,
    activo    = list(clase = "text-bg-success",   texto = "listo"),
    pendiente = list(clase = "text-bg-light",     texto = "pendiente"),
    bloqueado = list(clase = "text-bg-light",     texto = "no ejecutable"),
    list(clase = "text-bg-light", texto = estado))

  shiny::tagList(
    shiny::tags$span(class = paste("badge fw-normal", config$clase),
                     config$texto),
    if (wasm) bslib::tooltip(
      shiny::tags$span(class = "badge text-bg-info fw-normal",
                       bsicons::bs_icon("lightning-charge")),
      "Corre dentro del navegador")
  )
}

#' Badge del modo de ejecución, para el navbar.
badge_modo <- function() {
  navegador <- es_wasm()
  bslib::tooltip(
    shiny::tags$span(
      class = paste("badge", if (navegador) "bg-info text-dark" else "bg-secondary"),
      bsicons::bs_icon(if (navegador) "lightning-charge" else "hdd-rack"),
      " ", etiqueta_modo()),
    if (navegador)
      paste("R corre dentro de tu navegador vía WebAssembly.",
            "Los métodos que necesitan R completo aparecen con candado.")
    else
      "R completo: todos los métodos del catálogo pueden ejecutarse."
  )
}

#' Barra de progreso con etiqueta. Para el mapa del curso del Inicio.
barra_progreso <- function(hechos, total, etiqueta = NULL) {
  porcentaje <- if (total > 0) round(100 * hechos / total) else 0
  shiny::tags$div(
    class = "d-flex align-items-center gap-2",
    if (!is.null(etiqueta))
      shiny::tags$span(class = "small", style = "min-width: 11rem;", etiqueta),
    shiny::tags$div(
      class = "progress flex-grow-1", style = "height: 0.6rem;",
      shiny::tags$div(class = "progress-bar", role = "progressbar",
                      style = sprintf("width: %d%%;", porcentaje))),
    shiny::tags$span(class = "text-muted small", style = "min-width: 4.5rem;",
                     sprintf("%d de %d", hechos, total))
  )
}

#' Lista de avisos de compatibilidad, con su severidad y su sugerencia.
lista_avisos <- function(avisos) {
  if (!length(avisos)) return(NULL)
  estilo <- c(ok = "alert-success", aviso = "alert-warning", error = "alert-danger")
  icono <- c(ok = "check-circle", aviso = "exclamation-triangle", error = "x-circle")
  shiny::tagList(lapply(avisos, function(a) {
    shiny::tags$div(
      class = paste("alert py-2 px-3 mb-2", estilo[[a$severidad]]),
      shiny::tags$div(bsicons::bs_icon(icono[[a$severidad]]), " ", a$mensaje),
      if (!is.na(a$sugerencia))
        shiny::tags$div(class = "small mt-1 opacity-75", a$sugerencia)
    )
  }))
}
