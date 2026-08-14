# learn/R/ui/f1/analisis/univariado.R
#
# Responsabilidad: la pestaña Univariado de ▣ Análisis.
#
# El hook pedagógico está en dos sliders: el número de clases del histograma y
# el ancho de banda h de la densidad. Son el mismo dilema con dos nombres, y
# moverlos cambia la historia que cuentan los mismos datos.

controles_univariado <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("variable_uni"), "Variable", choices = character(0)),
    shiny::sliderInput(ns("clases"), "Clases del histograma", 5, 100, 30),
    shiny::sliderInput(ns("ancho"), "Ancho de banda h (0 = automatico)",
                       0, 5, 0, step = 0.05),
    shiny::checkboxInput(ns("con_densidad"), "Superponer densidad", TRUE),
    shiny::checkboxInput(ns("log_x"), "Escala logaritmica en x", FALSE),
    shiny::selectInput(ns("grupo_uni"), "Comparar por grupo",
                       choices = c("ninguno" = "")),
    shiny::uiOutput(ns("nota_escala")))
}

actualizar_univariado <- function(session, ds, previos = list()) {
  .rellenar_selector(session, "variable_uni", names(ds$df),
                     previos$variable_uni %||% .numericas_de(ds)[1])
  grupos <- .grupos_de(ds)
  previo <- previos$grupo_uni
  shiny::updateSelectInput(
    session, "grupo_uni", choices = c("ninguno" = "", grupos),
    selected = if (!is.null(previo) && previo %in% grupos) previo else "")
}

salida_univariado <- function(ns) {
  shiny::tagList(
    panel_resultado("f1.analisis.histograma",
      shiny::plotOutput(ns("histograma"), height = "320px"),
      contexto = salida_contexto(ns, "contexto_histograma"),
      encabezado_extra = shiny::uiOutput(ns("badge_uni"), inline = TRUE)),
    panel_resultado("f1.analisis.densidad",
      shiny::plotOutput(ns("densidad"), height = "280px"),
      contexto = salida_contexto(ns, "contexto_densidad")),
    panel_resultado("f1.analisis.boxplot",
      shiny::tagList(
        shiny::plotOutput(ns("boxplot"), height = "200px"),
        shiny::tags$h6(class = "mt-3", "Estadisticos sobre el total de filas"),
        shiny::tableOutput(ns("resumen_uni"))),
      contexto = salida_contexto(ns, "contexto_boxplot")),
    panel_resultado("f1.analisis.boxplot_grupos",
      shiny::plotOutput(ns("boxplot_grupos"), height = "300px"),
      contexto = salida_contexto(ns, "contexto_grupos")),
    panel_resultado("f1.analisis.qq_normal_datos",
      shiny::plotOutput(ns("qq"), height = "300px"),
      contexto = salida_contexto(ns, "contexto_qq")))
}

servidor_univariado <- function(input, output, session, dataset, muestreo) {
  ns <- session$ns
  ancho_elegido <- function() if ((input$ancho %||% 0) > 0) input$ancho else NULL

  output$nota_escala <- shiny::renderUI({
    ds <- dataset()
    shiny::req(ds, input$variable_uni)
    .nota_escala_variable(ds, input$variable_uni)
  })

  output$histograma <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$variable_uni)
    .exigir_operacion(ds, input$variable_uni, "histograma")
    graficar_histograma(muestreo()$datos, input$variable_uni,
                        clases = input$clases %||% 30L,
                        densidad = isTRUE(input$con_densidad),
                        ancho = ancho_elegido(),
                        log_x = isTRUE(input$log_x))
  })

  output$densidad <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$variable_uni)
    .exigir_operacion(ds, input$variable_uni, "densidad")
    graficar_densidad(muestreo()$datos, input$variable_uni, ancho_elegido())
  })

  output$boxplot <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$variable_uni)
    .exigir_operacion(ds, input$variable_uni, "boxplot")
    graficar_boxplot(muestreo()$datos, input$variable_uni)
  })

  # Las cuentas van sobre ds$df, nunca sobre la muestra de dibujo (C8).
  output$resumen_uni <- shiny::renderTable({
    ds <- dataset()
    shiny::req(ds, input$variable_uni)
    tabla <- resumir_variable(ds$df[[input$variable_uni]],
                              .escala_de(ds, input$variable_uni))
    tabla[, c("estadistico", "mostrado", "descripcion")]
  })

  output$boxplot_grupos <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$variable_uni)
    shiny::validate(shiny::need(nzchar(input$grupo_uni %||% ""),
                                "Elegi una columna de grupo en el sidebar."))
    .exigir_operacion(ds, input$variable_uni, "boxplot")
    graficar_boxplot_grupos(muestreo()$datos, input$variable_uni,
                            input$grupo_uni, violin = TRUE)
  })

  output$qq <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$variable_uni)
    .exigir_operacion(ds, input$variable_uni, "qq")
    graficar_qq(muestreo()$datos, input$variable_uni)
  })

  output$badge_uni <- shiny::renderUI(.badge_de_muestreo(ns, muestreo()))

  parametros <- shiny::reactive({
    ds <- dataset()
    if (is.null(ds) || is.null(input$variable_uni)) return(NULL)
    list(variable = input$variable_uni,
         escala = .escala_de(ds, input$variable_uni),
         clases = input$clases, ancho = input$ancho %||% "automatico",
         muestreo = descripcion_muestreo(muestreo()) %||% "sin muestreo")
  })
  for (par in list(c("f1.analisis.histograma", "contexto_histograma"),
                   c("f1.analisis.densidad", "contexto_densidad"),
                   c("f1.analisis.boxplot", "contexto_boxplot"),
                   c("f1.analisis.boxplot_grupos", "contexto_grupos"),
                   c("f1.analisis.qq_normal_datos", "contexto_qq")))
    dibujar_contexto(output, par[1], params = parametros, sufijo = par[2])
}
