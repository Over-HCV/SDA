# learn/R/ui/f4/desempeno.R
#
# Responsabilidad: subsección Desempeño — los números de la corrida.
#
# Qué métricas se muestran depende del tipo de tarea. Para reducción de
# dimensión no hay error de predicción que reportar: lo que se mide es cuánto
# se conserva al resumir, y cuánto se tiró.
#
# Las value boxes se calculan sobre el ajuste completo, nunca sobre una muestra
# de dibujo (C8).

controles_desempeno <- function(ns) {
  shiny::tagList(
    shiny::sliderInput(ns("umbral_acumulado"), "Umbral de varianza acumulada",
                       min = 0.5, max = 0.99, value = 0.8, step = 0.05),
    shiny::tags$p(class = "text-muted small mb-0",
                  paste("El 80 % es una costumbre, no un resultado. Movelo y",
                        "mirá cuántas componentes hacen falta.")))
}

salida_desempeno <- function(ns) {
  bslib::card(
    bslib::card_header("Qué conserva el resumen"),
    bslib::card_body(
      shiny::uiOutput(ns("cajas_desempeno")),
      shiny::uiOutput(ns("lectura_desempeno")),
      shiny::tableOutput(ns("tabla_varianza"))))
}

servidor_desempeno <- function(input, output, session, corrida) {
  ajuste <- shiny::reactive({
    c <- corrida()
    shiny::validate(shiny::need(!is.null(c),
                                "Corré una composición para ver su desempeño."))
    c$ajuste
  })

  output$cajas_desempeno <- shiny::renderUI({
    a <- ajuste()
    metricas <- metricas_de_corrida(a)
    bslib::layout_column_wrap(
      width = "180px", fill = FALSE,
      .caja("varianza retenida", sprintf("%.1f %%",
                                         100 * metricas$varianza_acumulada),
            sprintf("con %d de %d componentes", a$k, a$p)),
      .caja("error de reconstruccion", sprintf("%.3f",
                                               metricas$error_reconstruccion),
            sprintf("%.1f %% de la varianza total", 100 * a$error_relativo)),
      .caja("observaciones", format(a$n, big.mark = "."),
            if (a$filas_descartadas > 0)
              sprintf("%d filas con faltantes fuera", a$filas_descartadas)
            else "todas completas"),
      .caja("iteraciones", a$iteraciones,
            if (isTRUE(a$convergio)) "convergio" else "agoto el techo"))
  })

  # La única línea que interpreta, y lo hace con el número a la vista para que
  # se pueda discutir. No decide por el usuario: dice qué haría falta.
  output$lectura_desempeno <- shiny::renderUI({
    a <- ajuste()
    umbral <- input$umbral_acumulado %||% 0.8
    necesarias <- componentes_sugeridas(a, umbral)
    tabla <- varianza_explicada(a)
    shiny::tags$p(
      class = "mt-3 mb-2",
      sprintf("Para llegar al %.0f %% hacen falta %d componentes; con las %d que retuviste llevás %.1f %%.",
              100 * umbral, necesarias, a$k, 100 * tabla$acumulada[a$k]))
  })

  output$tabla_varianza <- shiny::renderTable({
    tabla <- varianza_explicada(ajuste())
    data.frame(
      componente = tabla$etiqueta,
      `valor propio` = round(tabla$valor_propio, 4),
      proporcion = sprintf("%.1f %%", 100 * tabla$proporcion),
      acumulada = sprintf("%.1f %%", 100 * tabla$acumulada),
      check.names = FALSE)
  }, striped = TRUE, width = "100%")
  invisible(TRUE)
}

.caja <- function(titulo, valor, pie = NULL) {
  bslib::value_box(
    title = titulo, value = valor, theme = "text-primary",
    if (!is.null(pie)) shiny::tags$span(class = "small", pie))
}
