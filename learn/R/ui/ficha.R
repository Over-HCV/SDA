# learn/R/ui/ficha.R
#
# Responsabilidad: mostrar la ficha de un método.
#
# La ficha responde "qué es" y sobre todo "por qué es necesaria", que es la
# pregunta que el aplicativo existe para contestar. El cuerpo largo vive en
# fichas/<clave>.md (C6); acá solo se arma el marco: metadatos que salen del
# registro, y el bloque del puente cuando el método está bloqueado.

.fila_meta <- function(etiqueta, valor) {
  if (is.null(valor) || (length(valor) == 1 && is.na(valor)) ||
      !length(valor) || identical(valor, "")) return(NULL)
  shiny::tags$tr(
    shiny::tags$th(class = "text-muted fw-normal pe-3 align-top", etiqueta),
    shiny::tags$td(valor))
}

#' Tabla de metadatos, generada desde el registro. Nunca se escribe a mano:
#' si el catálogo cambia, la ficha cambia sola.
metadatos_metodo <- function(clave) {
  m <- metodo(clave)
  shiny::tags$table(
    class = "table table-sm mb-3",
    shiny::tags$tbody(
      .fila_meta("Objetivo", ETIQUETA_OBJETIVO[[m$objetivo]] %||% m$objetivo),
      .fila_meta("Supervisión", gsub("_", " ", m$supervision)),
      .fila_meta("Sesión del curso", if (is.na(m$sesion)) NA else as.character(m$sesion)),
      .fila_meta("Teoría", if (is.na(m$nodo)) NA else
        shiny::tags$code(paste0("notes/tree.md → ", m$nodo))),
      .fila_meta("Paquetes", if (!length(m$deps)) NA else
        shiny::tags$code(paste(m$deps, collapse = ", "))),
      .fila_meta("Supuestos", if (!length(m$supuestos)) NA else
        paste(gsub("_", " ", m$supuestos), collapse = " · ")),
      .fila_meta("Se lee en", if (!length(m$artefactos)) NA else
        paste(vapply(m$artefactos, titulo_de, ""), collapse = " · ")),
      .fila_meta("Optimizador", if (is.null(m$optimizador)) NA else
        paste(m$optimizador$metodos, collapse = " · "))
    )
  )
}

#' Bloque que solo aparece en métodos bloqueados.
#'
#' El puente es lo que convierte un candado en una lección: conecta el método
#' inalcanzable con algo que sí se puede correr acá.
bloque_puente <- function(clave) {
  m <- metodo(clave)
  if (m$estado != "bloqueado") return(NULL)
  shiny::tags$div(
    class = "alert alert-dark",
    shiny::tags$div(class = "fw-bold mb-1",
                    bsicons::bs_icon("lock"), " No ejecutable aquí"),
    shiny::tags$div(class = "mb-2", m$motivo),
    if (!is.na(m$puente)) shiny::tagList(
      shiny::tags$div(class = "fw-bold mb-1 mt-3",
                      bsicons::bs_icon("bezier2"), " El puente"),
      shiny::tags$div(m$puente))
  )
}

#' Ficha completa de un método.
ui_ficha <- function(clave) {
  m <- metodo(clave)
  shiny::tagList(
    bloque_puente(clave),
    metadatos_metodo(clave),
    shiny::tags$hr(),
    shiny::HTML(ficha(clave)),
    shiny::tags$hr(),
    shiny::tags$p(
      class = "text-muted small mb-0",
      "Ficha: ", shiny::tags$code(file.path("learn", m$ficha)),
      " · clave: ", shiny::tags$code(m$clave))
  )
}

#' Ficha en modal. Es la forma correcta de mostrarla: es contenido estático y
#' extenso, así que no puede ocupar el cuerpo de una vista (C5).
modal_ficha <- function(clave) {
  m <- metodo(clave)
  shiny::modalDialog(
    title = shiny::tags$span(
      bsicons::bs_icon(ICONO_OBJETIVO[[m$objetivo]] %||% "circle"), " ", m$nombre),
    ui_ficha(clave),
    size = "l", easyClose = TRUE,
    footer = shiny::tagList(
      if (m$estado == "activo")
        shiny::actionButton("elegir_desde_ficha", "Elegir este método",
                            class = "btn-primary"),
      shiny::modalButton("Cerrar"))
  )
}
