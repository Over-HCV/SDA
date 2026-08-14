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

# Los controles siguen a la vista sin aplastar el resultado.
#
# Primero se intentó fijarle un alto a `layout_sidebar()`. Salió mal, y vale la
# pena dejar escrito por qué: con `height=`, layout_sidebar pasa a ser un
# contenedor *fill*, y entonces el `navset_card_tab` y sus cards se REPARTEN ese
# alto en vez de crecer. En una pestaña con tres `panel_resultado()` a cada
# `plotOutput` le quedaban unas decenas de píxeles de área útil y el device de R
# abortaba con `figure margins too large`: la pestaña Calidad se veía peor que
# Univariado justamente porque tiene más cards.
#
# Lo que se quería —leer un análisis largo sin perder de vista los controles—
# no necesita acotar la fase entera, solo el sidebar. Se acota él, con su propio
# scroll, y se queda pegado mientras la página baja. La derecha crece lo que
# necesite, que es lo que un resultado tiene que poder hacer.
#
# Es CSS en línea, no JavaScript propio: C10 se respeta.
#
# El descuento es la navbar de page_navbar más el padding de la página. Si se
# cambia el alto de la navbar, este número se ajusta con él.
ESTILO_CONTROLES <- paste(
  "position: sticky; top: 0;",
  "max-height: calc(100vh - 8rem); overflow-y: auto;")

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
#' @param estilo_controles  CSS del sidebar; ver ESTILO_CONTROLES arriba
armazon_fase <- function(controles, subsecciones, estado = NULL,
                         id_pestanas = NULL, ancho_controles = 320,
                         estilo_controles = ESTILO_CONTROLES) {
  cuerpo <- shiny::tagList(navegacion_fase(subsecciones, id_pestanas), estado)
  if (is.null(controles)) return(cuerpo)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = ancho_controles, title = "Controles", open = "desktop",
      shiny::div(style = estilo_controles, controles)),
    # `fillable = FALSE` es lo que deja crecer al resultado. Con el valor por
    # defecto el cuerpo se vuelve contenedor fill, las cards se reparten el alto
    # disponible y un plotOutput aplastado reporta altura cero: Shiny ni
    # siquiera evalúa su renderPlot, así que el gráfico —y el mensaje de
    # validate que iría en su lugar— no llegan nunca al DOM. Se descubrió
    # porque test_app.R dejó de ver el bloqueo por escala nominal.
    fillable = FALSE,
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
