# learn/R/ui/f4/explicabilidad.R
#
# Responsabilidad: subsección Explicabilidad — qué dice el ajuste.
#
# Cuatro vistas de la misma cosa: cargas (qué variables forman cada eje),
# círculo (cómo se correlacionan con él), mapa 2D (dónde cayeron las
# observaciones) y biplot (las dos cosas juntas).
#
# El par de ejes es un control compartido por los cuatro paneles: mirarlos con
# ejes distintos sería comparar cosas que no se comparan.

controles_explicabilidad <- function(ns) {
  shiny::tagList(
    shiny::selectInput(ns("eje_x"), "Componente horizontal",
                       choices = c("CP1" = "1")),
    shiny::selectInput(ns("eje_y"), "Componente vertical",
                       choices = c("CP2" = "2")),
    shiny::selectInput(ns("color"), "Colorear por",
                       choices = c("sin color" = "")),
    shiny::sliderInput(ns("alfa"), "Transparencia de los puntos",
                       min = 0.1, max = 1, value = 0.7, step = 0.05),
    shiny::tags$p(class = "text-muted small mb-0",
                  paste("El color no participó del ajuste: si los grupos se",
                        "separan, es un hallazgo.")))
}

#' Los ejes disponibles son las componentes RETENIDAS, no todas: pedir la
#' quinta cuando se guardaron dos no es un error del usuario, es una opción que
#' no debería existir.
actualizar_explicabilidad <- function(session, corrida, dataset,
                                      previos = list()) {
  if (is.null(corrida)) return(invisible(FALSE))
  k <- corrida$ajuste$k
  opciones <- stats::setNames(as.character(seq_len(k)), paste0("CP", seq_len(k)))
  .rellenar_selector(session, "eje_x", opciones, previos$eje_x %||% "1")
  .rellenar_selector(session, "eje_y", opciones,
                     previos$eje_y %||% as.character(min(2L, k)))

  candidatas <- if (is.null(dataset)) character(0) else
    c(columnas_con_rol(dataset, "grupo"),
      names(dataset$df)[vapply(dataset$df, function(x)
        is.character(x) || is.factor(x), logical(1))])
  shiny::updateSelectInput(session, "color",
                           choices = c("sin color" = "", unique(candidatas)),
                           selected = previos$color %||% "")
  invisible(TRUE)
}

salida_explicabilidad <- function(ns) {
  shiny::tagList(
    panel_resultado("f4.explicabilidad.cargas",
                    shiny::plotOutput(ns("cargas"), height = "300px"),
                    contexto = salida_contexto(ns, "contexto_cargas")),
    panel_resultado("f4.explicabilidad.circulo_correlaciones",
                    shiny::plotOutput(ns("circulo"), height = "380px"),
                    contexto = salida_contexto(ns, "contexto_circulo")),
    panel_resultado("f4.explicabilidad.mapa_2d",
                    shiny::plotOutput(ns("mapa"), height = "380px"),
                    contexto = salida_contexto(ns, "contexto_mapa")),
    panel_resultado("f4.explicabilidad.biplot",
                    shiny::plotOutput(ns("biplot"), height = "420px"),
                    contexto = salida_contexto(ns, "contexto_biplot")))
}

servidor_explicabilidad <- function(input, output, session, corrida, dataset) {
  ajuste <- shiny::reactive({
    c <- corrida()
    shiny::validate(shiny::need(
      !is.null(c), "Corré una composición en Composición para ver el modelo."))
    c$ajuste
  })

  ejes <- shiny::reactive({
    c(as.integer(input$eje_x %||% "1"), as.integer(input$eje_y %||% "2"))
  })

  etiquetas <- shiny::reactive(paste0("CP", ejes()))

  # El color se recorta a las filas que de verdad entraron al ajuste: las que
  # tenían un faltante se descartaron y desalinear el vector pintaría cada
  # punto del grupo equivocado, sin fallar.
  grupo <- shiny::reactive({
    ds <- tryCatch(dataset(), error = function(e) NULL)
    columna <- input$color %||% ""
    if (is.null(ds) || !nzchar(columna)) return(NULL)
    a <- ajuste()
    completas <- stats::complete.cases(ds$df[, a$columnas, drop = FALSE])
    ds$df[[columna]][completas]
  })

  .exigir_ejes <- function() {
    shiny::validate(shiny::need(
      ejes()[1] != ejes()[2],
      "Elegí dos componentes distintas: una contra sí misma es una diagonal."))
  }

  output$cargas <- shiny::renderPlot({
    graficar_cargas(cargas(ajuste(), componentes = unique(ejes())))
  })

  output$circulo <- shiny::renderPlot({
    .exigir_ejes()
    a <- ajuste()
    graficar_circulo(correlaciones_componentes(a, ejes()), etiquetas(),
                     sobre_correlacion = identical(a$matriz, "correlacion"))
  })

  output$mapa <- shiny::renderPlot({
    .exigir_ejes()
    graficar_mapa_2d(coordenadas_2d(ajuste(), ejes(), grupo()), etiquetas(),
                     alfa = input$alfa %||% 0.7)
  })

  output$biplot <- shiny::renderPlot({
    .exigir_ejes()
    graficar_biplot(coordenadas_biplot(ajuste(), ejes(), grupo()), etiquetas(),
                    alfa = input$alfa %||% 0.7)
  })

  parametros <- shiny::reactive({
    c <- corrida()
    if (is.null(c)) return(NULL)
    c(c$params, list(ejes = paste(etiquetas(), collapse = " x "),
                     color = if (nzchar(input$color %||% "")) input$color
                             else "sin color"))
  })
  metricas <- shiny::reactive({
    c <- corrida()
    if (is.null(c)) NULL else c$metricas
  })
  for (par in list(c("f4.explicabilidad.cargas", "contexto_cargas"),
                   c("f4.explicabilidad.circulo_correlaciones", "contexto_circulo"),
                   c("f4.explicabilidad.mapa_2d", "contexto_mapa"),
                   c("f4.explicabilidad.biplot", "contexto_biplot")))
    dibujar_contexto(output, par[1], params = parametros, metricas = metricas,
                     corrida = shiny::reactive(corrida()), sufijo = par[2])
  invisible(TRUE)
}
