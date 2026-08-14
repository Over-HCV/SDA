# learn/R/ui/piezas/fase.R
#
# Responsabilidad: el armazón de navegación de una fase (C4).
#
# Todas las fases se ven igual por dentro: pestañas horizontales para las
# subsecciones, y la última siempre es ▣ Análisis — el lugar donde la fase deja
# de configurarse y empieza a mirarse.
#
# Que esto viva en un solo sitio evita que cada fase invente su navegación y
# garantiza que la última pestaña sea siempre la misma en las cuatro.

ETIQUETA_ANALISIS <- "▣ Análisis"

#' Pestañas de subsección de una fase.
#'
#' @param subsecciones lista con nombre: list("Fuente" = ui, "Calidad" = ui)
#' @param id_pestanas  id para saber en qué pestaña está el usuario, o NULL
navegacion_fase <- function(subsecciones, id_pestanas = NULL) {
  paneles <- lapply(names(subsecciones), function(titulo) {
    bslib::nav_panel(titulo, subsecciones[[titulo]])
  })
  do.call(bslib::navset_card_tab,
          c(list(id = id_pestanas, full_screen = TRUE), paneles))
}

#' Fase completa: controles a la izquierda, subsecciones a la derecha.
#'
#' El sidebar es plegable a propósito: cuando el usuario está mirando un
#' resultado y no tocando controles, el gráfico se queda con toda la pantalla.
#'
#' @param controles     UI del sidebar, o NULL si la fase no tiene controles
#' @param subsecciones  lista con nombre
#' @param estado        franja_estado(), o NULL
armazon_fase <- function(controles, subsecciones, estado = NULL,
                         id_pestanas = NULL, ancho_controles = 320) {
  cuerpo <- shiny::tagList(navegacion_fase(subsecciones, id_pestanas), estado)
  if (is.null(controles)) return(cuerpo)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(width = ancho_controles, title = "Controles",
                             open = "desktop", controles),
    cuerpo
  )
}

#' Fase todavía sin construir, pero navegable.
#'
#' Las pestañas reales ya están: se ve la estructura completa de la fase antes
#' de que exista su contenido. Cada una dice a qué hito pertenece.
#'
#' @param subsecciones character() de títulos
#' @param detalles     lista con nombre: una frase por subsección, opcional
fase_pendiente <- function(subsecciones, hito, detalles = list()) {
  contenidos <- lapply(subsecciones, function(titulo) {
    panel_pendiente(titulo, hito, detalles[[titulo]])
  })
  navegacion_fase(stats::setNames(contenidos, subsecciones))
}

#' Servidor vacío. Existe para que app.R llame siempre al mismo par ui/server
#' aunque la fase todavía no haga nada, y para que añadir lógica después no
#' obligue a tocar app.R.
servidor_pendiente <- function(id) {
  shiny::moduleServer(id, function(input, output, session) invisible(NULL))
}
