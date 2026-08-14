# learn/R/ui/piezas/panel.R
#
# Responsabilidad: la envoltura estándar de todo resultado visible.
#
# Codifica C4 y C5 de una vez para que ninguna vista los reinvente:
#   - el RESULTADO manda y ocupa el cuerpo de la card,
#   - lo que no cambia con los inputs vive plegado abajo,
#   - la clave del artefacto está siempre a un clic (C9).
#
# Uso típico dentro de un módulo:
#
#   panel_resultado("f1.analisis.histograma",
#     plotOutput(ns("histograma"), height = "380px"),
#     contexto = salida_contexto(ns))
#
# y en el server:
#
#   dibujar_contexto(output, "f1.analisis.histograma",
#                   params = reactive(list(bins = input$bins)))

#' Plegable cerrado por defecto. Es el destino de todo lo estático (C5).
plegable <- function(titulo, contenido, abierto = FALSE,
                     icono = "chevron-right") {
  bslib::accordion(
    open = abierto, class = "mt-2",
    bslib::accordion_panel(titulo, icon = bsicons::bs_icon(icono), contenido)
  )
}

#' Etiqueta ⓘ con la clave y las rutas del artefacto, dentro de un popover.
#'
#' Está en el encabezado y no en el cuerpo a propósito: es metadato, no
#' resultado, así que no puede robarle espacio al gráfico.
sello_clave <- function(clave) {
  rutas <- if (existe_artefacto(clave)) rutas_de(clave)
           else list(clave = clave, grafico = NA, logica = NA, texto = NA)
  linea <- function(etiqueta, valor) {
    if (is.null(valor) || is.na(valor)) return(NULL)
    shiny::tags$div(shiny::tags$strong(etiqueta), " ", shiny::tags$code(valor))
  }
  bslib::popover(
    bslib::tooltip(bsicons::bs_icon("info-circle", class = "text-muted"),
                   "De dónde sale este gráfico"),
    title = rutas$clave,
    linea("gráfico:", rutas$grafico),
    linea("lógica:", rutas$logica),
    linea("texto:", rutas$texto),
    placement = "left"
  )
}

#' Card estándar de un artefacto.
#'
#' @param clave     clave registrada en artefactos/
#' @param contenido el resultado: plotOutput, tableOutput, lo que sea
#' @param contexto  salida_contexto(ns), o NULL para no ofrecer el bloque
#' @param porque    UI opcional para "¿Por qué importa?" (contenido estático)
#' @param altura    alto del cuerpo, ej. "420px"
#' @param encabezado_extra UI a la derecha del título (badges, botones chicos)
panel_resultado <- function(clave, contenido, contexto = NULL, porque = NULL,
                            altura = NULL, encabezado_extra = NULL) {
  bslib::card(
    full_screen = TRUE,
    height = altura,
    bslib::card_header(
      shiny::tags$div(
        class = "d-flex justify-content-between align-items-center",
        shiny::tags$span(titulo_de(clave)),
        shiny::tags$span(class = "d-flex gap-2 align-items-center",
                         encabezado_extra, sello_clave(clave))
      )
    ),
    bslib::card_body(contenido),
    bslib::card_footer(
      class = "pt-1 pb-1",
      bslib::accordion(
        open = FALSE, class = "accordion-flush",
        bslib::accordion_panel(
          "¿Cómo se lee?", icon = bsicons::bs_icon("eyeglasses"),
          shiny::HTML(texto(clave))),
        if (!is.null(porque)) bslib::accordion_panel(
          "¿Por qué importa?", icon = bsicons::bs_icon("question-circle"),
          porque),
        if (!is.null(contexto)) bslib::accordion_panel(
          "contexto", icon = bsicons::bs_icon("chat-square-text"),
          shiny::tags$p(class = "text-muted small",
                        paste("Copiá este bloque y pegalo en una conversación",
                              "para preguntar por qué salió este resultado.")),
          contexto)
      )
    )
  )
}

#' Aviso de sección todavía sin construir. Explícito y con destino.
panel_pendiente <- function(titulo, hito, detalle = NULL) {
  bslib::card(
    bslib::card_header(titulo),
    bslib::card_body(
      shiny::tags$div(
        class = "text-center text-muted py-5",
        bsicons::bs_icon("cone-striped", size = "2.5rem"),
        shiny::tags$p(class = "mt-3 mb-1",
                      shiny::tags$strong(sprintf("En construcción · %s", hito))),
        if (!is.null(detalle)) shiny::tags$p(class = "small", detalle),
        shiny::tags$p(class = "small mb-0",
                      "El plan y su avance están en ", shiny::tags$code("learn/PLAN.md"))
      )
    )
  )
}

# ---------------------------------------------------------------------------
# El bloque de contexto: mitad UI, mitad server
# ---------------------------------------------------------------------------

#' Hueco donde se dibuja el bloque de contexto.
#' @param sufijo permite más de un panel por módulo
salida_contexto <- function(ns, sufijo = "contexto") {
  shiny::verbatimTextOutput(ns(sufijo))
}

#' Rellena el hueco. Llamar dentro de moduleServer().
#'
#' @param params,metricas,corrida reactivos (o valores fijos)
dibujar_contexto <- function(output, clave, params = NULL, metricas = NULL,
                            corrida = NULL, sufijo = "contexto") {
  desenvolver <- function(x) if (is.function(x)) x() else x
  output[[sufijo]] <- shiny::renderText({
    contexto_de(clave, corrida = desenvolver(corrida),
                params = desenvolver(params), metricas = desenvolver(metricas))
  })
  invisible(TRUE)
}
