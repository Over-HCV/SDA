# libs/shiny-live/R/mod_potencia.R
#
# Módulo del tab "Potencia". Simula la potencia estadística de un ANOVA one-way
# sobre una grilla de (n, efecto) y la muestra como heatmap. La simulación es
# pesada (N_sim × #celdas ANOVAs), así que se dispara con un botón y se envuelve
# en withProgress(). Sustituye a pwr::pwr.anova.test (no disponible en webR).
#
# Showcase: layout_columns, card, sliderInput, numericInput, actionButton,
# eventReactive, observeEvent, plotOutput, withProgress, showNotification.

mod_potencia_ui <- function(id) {
  ns <- NS(id)
  layout_columns(
    col_widths = c(4, 8),
    card(card_header("Parámetros de la simulación"),
         card_body(
           sliderInput(ns("k_grupos"), "Grupos (k)", min = 2, max = 8, value = 3, step = 1),
           sliderInput(ns("n_max"), "n máximo a evaluar", min = 20, max = 200, value = 100, step = 10),
           sliderInput(ns("efecto_max"), "Efecto máximo", min = 4, max = 30, value = 20, step = 2),
           numericInput(ns("N_sim"), "Repeticiones por celda (N_sim)",
                        value = 30, min = 5, max = 200, step = 5),
           numericInput(ns("ruido"), "Ruido (sd)", value = 1, min = 0.1, max = 5, step = 0.1),
           tags$hr(),
           actionButton(ns("calcular"), "Calcular potencia",
                        class = "btn-primary w-100"),
           helpText("Cada celda corre N_sim ANOVAs. En webR es ~2-5× más lento.")
         )),
    card(full_screen = TRUE,
         card_header("Heatmap de potencia (fracción con p < 0.05)"),
         card_body(plotOutput(ns("heatmap"), height = "460px")))
  )
}

mod_potencia_server <- function(id, estado = NULL) {
  moduleServer(id, function(input, output, session) {

    resultado_sim <- eventReactive(input$calcular, {
      ns <- seq(10, input$n_max, length.out = 5) |> round() |> unique() |> sort()
      ns <- pmax(ns, input$k_grupos)
      efectos <- seq(0, input$efecto_max, by = 2)
      total <- length(ns) * length(efectos) * input$N_sim

      withProgress(message = "Simulando potencia...", value = 0, max = total, {
        pot <- potencia_simulada(
          ns = ns, efectos = efectos, k_grupos = input$k_grupos,
          ruido = input$ruido, N_sim = input$N_sim,
          semilla = if (!is.null(estado)) estado$params()$semilla else 42)
        incProgress(total, detail = "listo")
      })
      pot
    })

    output$heatmap <- renderPlot({
      df <- req(resultado_sim())
      graficar_potencia(df)
    })

    observeEvent(input$calcular, {
      showNotification(sprintf("Simulación: %d celdas × %d reps",
                               5 * length(seq(0, input$efecto_max, by = 2)), input$N_sim),
                       type = "message", duration = 2)
    })
  })
}
