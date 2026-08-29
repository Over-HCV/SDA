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

#' Sello ⓘ del encabezado: para qué sirve esta card, en dos o tres frases.
#'
#' Antes mostraba clave y rutas, que es un subconjunto estricto de lo que ya
#' trae el bloque "Contexto" del pie — y las 25 cards lo pasan. Repetir la
#' traza acá no informaba de nada; la pregunta que ninguna otra parte de la
#' card responde es para qué sirve mirarla.
#'
#' Está en el encabezado y no en el cuerpo a propósito: es orientación, no
#' resultado, así que no puede robarle espacio al gráfico.
#'
#' El disparador es un <span> y no el icono: `bs_icon()` devuelve un <svg> con
#' `aria-hidden="true"`, y Bootstrap le pone `tabindex="0"` al disparador. Con
#' el icono de disparador el foco caía sobre un elemento oculto a los lectores
#' de pantalla y el navegador bloqueaba la interacción. Por lo mismo va un solo
#' componente y no un popover envolviendo a un tooltip.
sello_clave <- function(clave) {
  bslib::popover(
    shiny::tags$span(
      class = "text-muted d-inline-flex", tabindex = "0", role = "button",
      `aria-label` = "¿Para qué sirve?",
      bsicons::bs_icon("info-circle")),
    title = "¿Para qué sirve?",
    shiny::HTML(texto_bloque(clave)),
    placement = "left"
  )
}

#' Card estándar de un artefacto.
#'
#' @param clave     clave registrada en artefactos/
#' @param contenido el resultado: plotOutput, tableOutput, lo que sea
#' @param contexto  salida_contexto(ns), o NULL para no ofrecer el bloque
#' @param altura    alto del cuerpo, ej. "420px"
#' @param encabezado_extra UI a la derecha del título (badges, botones chicos)
panel_resultado <- function(clave, contenido, contexto = NULL,
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
        if (!is.null(contexto)) bslib::accordion_panel(
          "Contexto", icon = bsicons::bs_icon("chat-square-text"),
          shiny::tags$p(class = "text-muted small",
                        paste("Este bloque sirve para orientarse",
                              "y preguntar sobre un resultado específico.")),
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

# ---------------------------------------------------------------------------
# Paneles gobernados por el registro
# ---------------------------------------------------------------------------
#
# Con un solo método implementado, la fase 4 podía dibujar sus cuatro cards
# siempre: todas eran del ACP. Con dos familias en el catálogo, un scree sobre
# una partición no es un gráfico vacío, es un gráfico equivocado.
#
# SCHEMA.md ya lo prometía: "las pestañas de análisis de la fase 4 se generan
# desde `artefactos`". Estas dos funciones lo cumplen sin renderUI: la card se
# construye una vez y se muestra según lo que el método declara (la trampa del
# sidebar rendido está documentada en AGENT.md).

#' El id del output booleano que gobierna la visibilidad de una clave.
bandera_artefacto <- function(clave) paste0("declara_", gsub("[.]", "_", clave))

#' Un panel de resultado que solo aparece si el método de la corrida declara
#' esa clave de artefacto.
panel_si_declara <- function(ns, clave, contenido, contexto = NULL) {
  shiny::conditionalPanel(
    condition = sprintf("output.%s", bandera_artefacto(clave)), ns = ns,
    panel_resultado(clave, contenido, contexto = contexto))
}

#' Publica las banderas que consumen los `panel_si_declara()` de una vista.
#'
#' @param claves        claves de artefacto que la vista puede dibujar
#' @param clave_metodo   reactive que devuelve la clave del método, o NULL
declarar_artefactos <- function(output, claves, clave_metodo) {
  for (clave in claves) local({
    esta <- clave
    bandera <- bandera_artefacto(esta)
    output[[bandera]] <- shiny::reactive({
      elegido <- tryCatch(clave_metodo(), error = function(e) NULL)
      if (!length(elegido) || !nzchar(elegido)) return(FALSE)
      declarados <- tryCatch(metodo(elegido)$artefactos,
                             error = function(e) character(0))
      esta %in% declarados
    })
    shiny::outputOptions(output, bandera, suspendWhenHidden = FALSE)
  })
  invisible(TRUE)
}
