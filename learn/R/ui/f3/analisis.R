# learn/R/ui/f3/analisis.R
#
# Responsabilidad: subsección ▣ Análisis de la fase 3 — la convergencia mirada
# de frente.
#
# Tres vistas sobre la misma traza: el objetivo, las cargas y el criterio de
# parada. Las otras cuatro que promete el diseño (camino sobre la superficie,
# sensibilidad a la semilla, ruta de regularización, curva de aprendizaje)
# necesitan métodos que todavía no existen y se anuncian como pendientes con su
# hito, no se esconden.

DETALLE_ANALISIS_AJUSTE <- list(
  "Camino sobre la superficie" = paste(
    "El recorrido del optimizador dibujado sobre el mapa de la objetivo.",
    "Necesita la superficie de pérdida de la fase 2: entra con k-medias."),
  "Sensibilidad a la semilla" = paste(
    "Varios reinicios superpuestos para distinguir óptimo local de global.",
    "En el ACP todos los reinicios llegan al mismo sitio —la comprobación",
    "está en test_acp.R—, así que la vista se gana su lugar con k-medias."),
  "Ruta de regularización" = paste(
    "Los coeficientes contra lambda. Entra con LASSO."),
  "Curva de aprendizaje" = paste(
    "Error de ajuste y de validación contra el tamaño de muestra. Necesita",
    "métodos supervisados con partición."))

controles_analisis_ajuste <- function(ns) {
  shiny::tagList(
    shiny::checkboxInput(ns("escala_log"),
                         "Escala logarítmica en el objetivo", FALSE),
    shiny::selectInput(ns("componente_traza"), "Componente",
                       choices = c("1" = "1")),
    shiny::tags$p(class = "text-muted small mb-0",
                  paste("Al final del ajuste las mejoras son diminutas: en",
                        "escala lineal la curva parece plana mucho antes de",
                        "estarlo.")))
}

actualizar_analisis_ajuste <- function(session, ajuste, previos = list()) {
  if (is.null(ajuste) || is.null(ajuste$traza)) return(invisible(FALSE))
  componentes <- sort(unique(traza_a_tabla(ajuste$traza)$componente))
  previo <- previos$componente_traza
  shiny::updateSelectInput(
    session, "componente_traza", choices = as.character(componentes),
    selected = if (!is.null(previo) && previo %in% as.character(componentes))
      previo else "1")
  invisible(TRUE)
}

salida_analisis_ajuste <- function(ns) {
  pendientes <- lapply(names(DETALLE_ANALISIS_AJUSTE), function(titulo)
    panel_pendiente(titulo, "Hitos 4-5", DETALLE_ANALISIS_AJUSTE[[titulo]]))

  shiny::tagList(
    panel_resultado(
      "f3.analisis.convergencia",
      shiny::tagList(
        shiny::plotOutput(ns("convergencia"), height = "300px"),
        shiny::plotOutput(ns("deltas"), height = "220px")),
      contexto = salida_contexto(ns, "contexto_convergencia")),
    plegable("Lo que falta en esta subsección", shiny::tagList(pendientes)))
}

servidor_analisis_ajuste <- function(input, output, session, ajuste) {
  .exigir_traza <- function(a) {
    shiny::validate(shiny::need(!is.null(a),
                                "Pulsá Ajustar en la Consola para ver la traza."))
    shiny::validate(shiny::need(
      !is.null(a$traza),
      paste("El optimizador 'svd' resuelve en un paso y no deja traza.",
            "Elegí 'potencia' y volvé a ajustar para ver el mismo resultado",
            "construyéndose.")))
    invisible(TRUE)
  }

  output$convergencia <- shiny::renderPlot({
    a <- ajuste()
    .exigir_traza(a)
    graficar_convergencia(traza_a_tabla(a$traza),
                          escala_log = isTRUE(input$escala_log),
                          objetivo = a$traza$objetivo)
  })

  output$deltas <- shiny::renderPlot({
    a <- ajuste()
    .exigir_traza(a)
    tabla <- traza_a_tabla(a$traza)
    componente <- as.integer(input$componente_traza %||% "1")
    graficar_deltas(tabla[tabla$componente == componente, , drop = FALSE],
                    tol = a$tol)
  })

  dibujar_contexto(output, "f3.analisis.convergencia",
                   params = shiny::reactive({
                     a <- ajuste()
                     if (is.null(a)) return(NULL)
                     list(optimizador = a$optimizador, tolerancia = a$tol,
                          maxit = a$maxit, semilla = a$semilla,
                          iteraciones = a$iteraciones,
                          convergio = isTRUE(a$convergio),
                          objetivo = a$traza$objetivo %||% "sin traza")
                   }),
                   sufijo = "contexto_convergencia")
  invisible(TRUE)
}
