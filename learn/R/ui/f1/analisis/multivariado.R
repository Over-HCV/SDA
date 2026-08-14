# learn/R/ui/f1/analisis/multivariado.R
#
# Responsabilidad: la pestaña Multivariado de ▣ Análisis.
#
# Acá empieza a verse por qué existe la reducción de dimensión: con seis
# variables la matriz de dispersión ya no cabe, el mapa de calor muestra
# bloques redundantes y el Q-Q de Mahalanobis encuentra filas raras que ninguna
# columna por separado delata.

controles_multivariado <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("variables_multi"), "Variables",
                       choices = character(0), multiple = TRUE),
    shiny::selectInput(ns("grupo_multi"), "Colorear por",
                       choices = c("ninguno" = "")),
    shiny::radioButtons(ns("metodo_cor"), "Correlacion",
                        choices = c("Pearson (lineal)" = "pearson",
                                    "Spearman (monotona)" = "spearman"),
                        selected = "pearson"),
    shiny::checkboxInput(ns("reordenar"), "Reordenar el mapa de calor", TRUE),
    shiny::selectInput(ns("normalizacion"), "Normalizar paralelas con",
                       choices = c("minmax", "z")),
    shiny::sliderInput(ns("nivel_elipse"), "Nivel del elipsoide", 0.5, 0.99,
                       0.95, step = 0.01))
}

actualizar_multivariado <- function(session, ds, previos = list()) {
  numericas <- .numericas_de(ds)
  elegidas <- previos$variables_multi
  if (!length(elegidas) || !all(elegidas %in% numericas))
    elegidas <- utils::head(numericas, 4L)
  shiny::updateSelectInput(session, "variables_multi", choices = numericas,
                           selected = elegidas)
  grupos <- .grupos_de(ds)
  previo <- previos$grupo_multi
  shiny::updateSelectInput(
    session, "grupo_multi", choices = c("ninguno" = "", grupos),
    selected = if (!is.null(previo) && previo %in% grupos) previo else "")
}

salida_multivariado <- function(ns) {
  shiny::tagList(
    panel_resultado("f1.analisis.matriz_dispersion",
      shiny::plotOutput(ns("pares"), height = "420px"),
      contexto = salida_contexto(ns, "contexto_pares"),
      encabezado_extra = shiny::uiOutput(ns("badge_multi"), inline = TRUE)),
    panel_resultado("f1.analisis.heatmap_correlacion",
      shiny::plotOutput(ns("heatmap"), height = "360px"),
      contexto = salida_contexto(ns, "contexto_heatmap")),
    panel_resultado("f1.analisis.coordenadas_paralelas",
      shiny::plotOutput(ns("paralelas"), height = "320px"),
      contexto = salida_contexto(ns, "contexto_paralelas")),
    panel_resultado("f1.analisis.elipsoide",
      shiny::plotOutput(ns("elipsoide"), height = "340px"),
      contexto = salida_contexto(ns, "contexto_elipsoide")),
    panel_resultado("f1.analisis.qq_mahalanobis",
      shiny::plotOutput(ns("qq_mahalanobis"), height = "320px"),
      contexto = salida_contexto(ns, "contexto_mahalanobis")))
}

servidor_multivariado <- function(input, output, session, dataset, muestreo) {
  ns <- session$ns

  variables <- shiny::reactive({
    elegidas <- input$variables_multi
    shiny::validate(shiny::need(length(elegidas) >= 2L,
                                "Elegi al menos dos variables en el sidebar."))
    elegidas
  })
  grupo_activo <- function()
    if (nzchar(input$grupo_multi %||% "")) input$grupo_multi else NULL

  # La matriz se calcula sobre el TOTAL: es una métrica, no un dibujo (C8).
  correlaciones <- shiny::reactive({
    ds <- dataset()
    shiny::req(ds)
    matriz_correlacion(ds$df, variables(), input$metodo_cor %||% "pearson",
                       reordenar = isTRUE(input$reordenar))
  })

  distancias <- shiny::reactive({
    ds <- dataset()
    shiny::req(ds)
    mahalanobis_cuadrado(ds$df, variables())
  })

  output$pares <- shiny::renderPlot(
    graficar_pares(muestreo()$datos, variables(), grupo_activo()))

  output$heatmap <- shiny::renderPlot(
    graficar_heatmap_correlacion(correlaciones()))

  output$paralelas <- shiny::renderPlot(
    graficar_coordenadas_paralelas(muestreo()$datos, variables(),
                                   grupo_activo(),
                                   metodo = input$normalizacion %||% "minmax"))

  output$elipsoide <- shiny::renderPlot({
    elegidas <- variables()
    graficar_elipsoide(muestreo()$datos, elegidas[1], elegidas[2],
                       niveles = c(0.5, input$nivel_elipse %||% 0.95))
  })

  output$qq_mahalanobis <- shiny::renderPlot({
    valores <- distancias()
    shiny::validate(shiny::need(any(!is.na(valores)), paste(
      "No se pudo invertir la matriz de covarianzas: hay colinealidad exacta",
      "o faltan filas completas. Quitá una variable redundante.")))
    graficar_qq_mahalanobis(valores, length(variables()))
  })

  output$badge_multi <- shiny::renderUI(.badge_de_muestreo(ns, muestreo()))

  parametros <- shiny::reactive({
    if (length(input$variables_multi %||% character(0)) < 2L) return(NULL)
    matriz <- correlaciones()
    fuera <- abs(matriz[upper.tri(matriz)])
    list(variables = paste(input$variables_multi, collapse = ", "),
         metodo = input$metodo_cor,
         correlacion_maxima = round(max(fuera, na.rm = TRUE), 4),
         muestreo = descripcion_muestreo(muestreo()) %||% "sin muestreo")
  })
  for (par in list(c("f1.analisis.matriz_dispersion", "contexto_pares"),
                   c("f1.analisis.heatmap_correlacion", "contexto_heatmap"),
                   c("f1.analisis.coordenadas_paralelas", "contexto_paralelas"),
                   c("f1.analisis.elipsoide", "contexto_elipsoide")))
    dibujar_contexto(output, par[1], params = parametros, sufijo = par[2])

  dibujar_contexto(output, "f1.analisis.qq_mahalanobis",
                   params = shiny::reactive({
                     valores <- distancias()
                     if (all(is.na(valores))) return(list(estado = "no calculable"))
                     corte <- stats::qchisq(0.975, df = length(variables()))
                     list(variables = length(variables()),
                          corte = round(corte, 3),
                          por_encima = sum(valores > corte, na.rm = TRUE))
                   }), sufijo = "contexto_mahalanobis")
}
