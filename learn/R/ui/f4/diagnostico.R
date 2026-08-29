# learn/R/ui/f4/diagnostico.R
#
# Responsabilidad: subsección Diagnóstico — juzgar el ajuste.
#
# Para reducción de dimensión el diagnóstico es uno solo y es el importante:
# cuántas componentes valían la pena. Residuos, silueta, dendrograma y compañía
# llegan con los métodos que los producen.

DETALLE_DIAGNOSTICO <- list(
  "Residuos y supuestos a posteriori" = paste(
    "Residuos contra ajustados, Q-Q de residuos, escala-localización, leverage",
    "y distancia de Cook. Entran con la regresión de la sesión 6."),
  "Validación de grupos" = paste(
    "Silueta, codo de la inercia, dendrograma con corte móvil e índices",
    "internos. Entran con el agrupamiento de la sesión 5."))

controles_diagnostico <- function(ns) {
  shiny::tagList(
    shiny::sliderInput(ns("umbral_scree"), "Línea de referencia",
                       min = 0.5, max = 0.99, value = 0.8, step = 0.05),
    shiny::tags$p(class = "text-muted small mb-0",
                  paste("El codo casi nunca es evidente. La línea es una",
                        "referencia, el corte lo ponés vos en la fase 2.")))
}

salida_diagnostico <- function(ns) {
  pendientes <- lapply(names(DETALLE_DIAGNOSTICO), function(titulo)
    panel_pendiente(titulo, "Hitos 4-5", DETALLE_DIAGNOSTICO[[titulo]]))

  shiny::tagList(
    panel_resultado(
      "f4.diagnostico.scree",
      shiny::plotOutput(ns("scree"), height = "360px"),
      contexto = salida_contexto(ns, "contexto_scree")),
    plegable("Lo que falta en esta subsección", shiny::tagList(pendientes)))
}

servidor_diagnostico <- function(input, output, session, corrida) {
  output$scree <- shiny::renderPlot({
    c <- corrida()
    shiny::validate(shiny::need(!is.null(c),
                                "Corré una composición para ver el scree."))
    graficar_scree(varianza_explicada(c$ajuste), k = c$ajuste$k,
                   umbral = input$umbral_scree %||% 0.8)
  })

  dibujar_contexto(output, "f4.diagnostico.scree",
                   corrida = shiny::reactive(corrida()),
                   params = shiny::reactive({
                     c <- corrida()
                     if (is.null(c)) return(NULL)
                     c(c$params, list(umbral = input$umbral_scree))
                   }),
                   metricas = shiny::reactive({
                     c <- corrida()
                     if (is.null(c)) NULL else c$metricas
                   }),
                   sufijo = "contexto_scree")
  invisible(TRUE)
}
