# learn/R/ui/f1/analisis/bivariado.R
#
# Responsabilidad: la pestaña Bivariado de ▣ Análisis.
#
# El hook acá es el sobreploteo: transparencia, jitter y conteo por celda están
# a un clic para que se vea que la mancha negra escondía estructura.

controles_bivariado <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("x_bi"), "Variable X", choices = character(0)),
    shiny::selectInput(ns("y_bi"), "Variable Y", choices = character(0)),
    shiny::selectInput(ns("grupo_bi"), "Colorear por",
                       choices = c("ninguno" = "")),
    shiny::sliderInput(ns("alfa"), "Transparencia", 0.05, 1, 0.6, step = 0.05),
    shiny::checkboxInput(ns("jitter"), "Jitter (valores redondeados)", FALSE),
    shiny::checkboxInput(ns("celdas"), "Contar por celda en vez de puntos",
                         FALSE),
    shiny::checkboxInput(ns("suavizado"), "Curva loess", FALSE),
    shiny::tags$hr(),
    shiny::selectInput(ns("cruce_a"), "Cruce: primera categorica",
                       choices = character(0)),
    shiny::selectInput(ns("cruce_b"), "Cruce: segunda categorica",
                       choices = character(0)))
}

actualizar_bivariado <- function(session, ds, previos = list()) {
  numericas <- .numericas_de(ds)
  categoricas <- .grupos_de(ds)
  .rellenar_selector(session, "x_bi", numericas, previos$x_bi)
  .rellenar_selector(session, "y_bi", numericas,
                     previos$y_bi %||% numericas[min(2L, length(numericas))])
  previo <- previos$grupo_bi
  shiny::updateSelectInput(
    session, "grupo_bi", choices = c("ninguno" = "", categoricas),
    selected = if (!is.null(previo) && previo %in% categoricas) previo else "")
  .rellenar_selector(session, "cruce_a", categoricas, previos$cruce_a)
  .rellenar_selector(session, "cruce_b", categoricas,
                     previos$cruce_b %||% categoricas[min(2L, length(categoricas))])
}

salida_bivariado <- function(ns) {
  shiny::tagList(
    panel_resultado("f1.analisis.dispersion",
      shiny::plotOutput(ns("dispersion"), height = "340px"),
      contexto = salida_contexto(ns, "contexto_dispersion"),
      encabezado_extra = shiny::uiOutput(ns("badge_bi"), inline = TRUE)),
    panel_resultado("f1.analisis.densidad_conjunta",
      shiny::plotOutput(ns("densidad_conjunta"), height = "340px"),
      contexto = salida_contexto(ns, "contexto_conjunta")),
    panel_resultado("f1.analisis.mosaico",
      shiny::tagList(
        shiny::plotOutput(ns("mosaico"), height = "320px"),
        shiny::tags$h6(class = "mt-3", "Residuos estandarizados"),
        shiny::tableOutput(ns("residuos"))),
      contexto = salida_contexto(ns, "contexto_mosaico")))
}

servidor_bivariado <- function(input, output, session, dataset, muestreo) {
  ns <- session$ns

  cruce <- shiny::reactive({
    ds <- dataset()
    shiny::req(ds, input$cruce_a, input$cruce_b)
    tabla_contingencia(ds$df[[input$cruce_a]], ds$df[[input$cruce_b]],
                       input$cruce_a, input$cruce_b)
  })

  output$dispersion <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$x_bi, input$y_bi)
    .exigir_operacion(ds, input$x_bi, "dispersion")
    .exigir_operacion(ds, input$y_bi, "dispersion")
    grupo <- if (nzchar(input$grupo_bi %||% "")) input$grupo_bi else NULL
    graficar_dispersion(muestreo()$datos, input$x_bi, input$y_bi, grupo,
                        alfa = input$alfa %||% 0.6,
                        jitter = isTRUE(input$jitter),
                        celdas = isTRUE(input$celdas),
                        suavizado = isTRUE(input$suavizado))
  })

  output$densidad_conjunta <- shiny::renderPlot({
    ds <- dataset()
    shiny::req(ds, input$x_bi, input$y_bi)
    .exigir_operacion(ds, input$x_bi, "densidad")
    .exigir_operacion(ds, input$y_bi, "densidad")
    graficar_densidad_conjunta(muestreo()$datos, input$x_bi, input$y_bi)
  })

  output$mosaico <- shiny::renderPlot({
    shiny::validate(shiny::need(
      !identical(input$cruce_a, input$cruce_b),
      "Elegi dos columnas distintas para el cruce."))
    graficar_mosaico(cruce())
  })

  output$residuos <- shiny::renderTable({
    largo <- contingencia_larga(cruce())
    shiny::req(nrow(largo))
    largo[order(-abs(largo$residuo)),
          c("fila", "columna", "n", "esperado", "residuo")][seq_len(min(8L, nrow(largo))), ]
  })

  output$badge_bi <- shiny::renderUI(.badge_de_muestreo(ns, muestreo()))

  parametros <- shiny::reactive({
    if (is.null(input$x_bi) || is.null(input$y_bi)) return(NULL)
    asociacion <- medir_asociacion(dataset()$df[[input$x_bi]],
                                   dataset()$df[[input$y_bi]])
    list(x = input$x_bi, y = input$y_bi,
         pearson = round(asociacion$pearson, 4),
         spearman = round(asociacion$spearman, 4),
         n = asociacion$n,
         muestreo = descripcion_muestreo(muestreo()) %||% "sin muestreo")
  })
  dibujar_contexto(output, "f1.analisis.dispersion", params = parametros,
                   sufijo = "contexto_dispersion")
  dibujar_contexto(output, "f1.analisis.densidad_conjunta", params = parametros,
                   sufijo = "contexto_conjunta")
  dibujar_contexto(output, "f1.analisis.mosaico",
                   params = shiny::reactive({
                     resultado <- cruce()
                     list(cruce = paste(input$cruce_a, "x", input$cruce_b),
                          chi2 = round(resultado$chi2, 3), gl = resultado$gl,
                          p_valor = signif(resultado$p_valor, 4),
                          cramer = round(resultado$cramer, 4))
                   }), sufijo = "contexto_mosaico")
}
