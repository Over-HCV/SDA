# learn/R/ui/piezas/tarjetas.R
#
# Responsabilidad: la tarjeta de un método en el catálogo de la fase 2.
#
# Es la pieza más repetida de la app (54 instancias) y la que más carga
# pedagógica lleva: en cuatro líneas tiene que decir qué es el método, si se
# puede correr aquí, y a qué parte del temario pertenece.
#
# Los métodos bloqueados NO se ocultan. Una tarjeta con candado que al abrirse
# explica por qué y con qué se conecta enseña más que un hueco.

ICONO_OBJETIVO <- c(
  describir  = "bar-chart-line",
  reducir    = "arrows-angle-contract",
  agrupar    = "diagram-3",
  clasificar = "tags",
  predecir   = "graph-up-arrow",
  contrastar = "shuffle"
)

ETIQUETA_OBJETIVO <- c(
  describir = "Describir", reducir = "Reducir", agrupar = "Agrupar",
  clasificar = "Clasificar", predecir = "Predecir", contrastar = "Contrastar"
)

#' Tarjeta de un método.
#'
#' @param clave clave del método
#' @param ns    namespace del módulo que la dibuja (para el botón de la ficha)
tarjeta_metodo <- function(clave, ns = shiny::NS(NULL)) {
  m <- metodo(clave)
  bloqueado <- m$estado == "bloqueado"

  bslib::card(
    class = if (bloqueado) "opacity-75" else NULL,
    bslib::card_header(
      class = "d-flex justify-content-between align-items-start gap-2",
      shiny::tags$span(
        bsicons::bs_icon(ICONO_OBJETIVO[[m$objetivo]] %||% "circle"), " ",
        shiny::tags$strong(m$nombre)),
      badge_estado(m$estado, m$wasm)
    ),
    bslib::card_body(
      class = "py-2",
      shiny::tags$div(
        class = "text-muted small mb-2",
        sprintf("%s%s", ETIQUETA_OBJETIVO[[m$objetivo]] %||% m$objetivo,
                if (!is.na(m$sesion)) sprintf(" · sesión %d", m$sesion) else "")),
      if (bloqueado) shiny::tags$div(class = "small", m$motivo) else NULL,
      if (length(m$deps))
        shiny::tags$div(class = "small text-muted",
                        "requiere ", shiny::tags$code(paste(m$deps, collapse = ", ")))
      else NULL
    ),
    bslib::card_footer(
      class = "d-flex gap-2 py-2",
      shiny::actionLink(ns(paste0("ficha_", clave)), "Ver ficha",
                        class = "btn btn-sm btn-outline-secondary"),
      .boton_elegir(clave, m, ns)
    )
  )
}

#' Botón de acción de la tarjeta, uno por estado.
#'
#' Los tres estados tienen destinos distintos y ofrecer "Elegir" en los tres
#' sería mentir: un método `pendiente` está en el temario pero todavía no se
#' puede correr, y un `bloqueado` no se va a poder nunca. Un botón que no hace
#' nada al pulsarlo enseña desconfianza en el resto de la interfaz.
.boton_elegir <- function(clave, m, ns) {
  if (m$estado == "activo")
    return(shiny::actionLink(ns(paste0("elegir_", clave)), "Elegir",
                             class = "btn btn-sm btn-primary"))

  if (m$estado == "pendiente")
    return(bslib::tooltip(
      shiny::tags$span(class = "btn btn-sm btn-outline-secondary disabled",
                       bsicons::bs_icon("hourglass"), " Sin implementar"),
      paste("Está en el temario y su ficha ya explica qué hace, pero todavía",
            "no tiene función de ajuste. Ver learn/PLAN.md.")))

  bslib::tooltip(
    shiny::tags$span(class = "btn btn-sm btn-outline-dark disabled",
                     bsicons::bs_icon("lock"), " No ejecutable"),
    m$motivo)
}

#' Rejilla de tarjetas agrupadas por objetivo.
#'
#' Agrupar por objetivo y no por sesión es deliberado: cuando alguien busca un
#' método, sabe qué quiere HACER (agrupar, predecir), no en qué clase se vio.
rejilla_metodos <- function(claves, ns = shiny::NS(NULL), columnas = 3L) {
  if (!length(claves))
    return(shiny::tags$div(class = "text-muted text-center py-5",
                           "Ningún método coincide con los filtros."))

  objetivos <- vapply(claves, function(k) metodo(k)$objetivo, "")
  bloques <- lapply(OBJETIVOS, function(objetivo) {
    del_grupo <- claves[objetivos == objetivo]
    if (!length(del_grupo)) return(NULL)
    shiny::tagList(
      shiny::tags$h5(
        class = "mt-4 mb-2",
        bsicons::bs_icon(ICONO_OBJETIVO[[objetivo]]), " ",
        ETIQUETA_OBJETIVO[[objetivo]],
        shiny::tags$span(class = "text-muted small ms-2",
                         sprintf("%d", length(del_grupo)))),
      bslib::layout_column_wrap(
        width = 1 / columnas, gap = "0.75rem",
        !!!lapply(del_grupo, tarjeta_metodo, ns = ns))
    )
  })
  shiny::tagList(Filter(Negate(is.null), bloques))
}
