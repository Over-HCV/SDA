# libs/shiny-live/R/mod_distribucion.R
#
# Módulo del tab "Distribución". QQ-plot e histograma de residuales, más una
# tabla con asimetría, curtosis y Shapiro. El QQ tiene brush que resalta los
# puntos seleccionados en un DT. Refleja la exclusión de outliers hecha en el
# tab ANOVA (consume el estado compartido).
#
# Showcase: layout_columns, card, plotOutput(brush), brushedPoints,
# DT::dataTableOutput, verbatimTextOutput.

mod_distribucion_ui <- function(id) {
  ns <- NS(id)
  tagList(
    layout_columns(
      col_widths = c(6, 6),
      card(full_screen = TRUE,
           card_header("QQ de residuales — arrastra para inspeccionar puntos"),
           card_body(plotOutput(ns("qq"), height = "360px",
                                brush = brushOpts(ns("brush_qq"), resetOnNew = TRUE)))),
      card(full_screen = TRUE,
           card_header("Histograma de residuales"),
           card_body(plotOutput(ns("hist"), height = "360px")))
    ),
    layout_columns(
      col_widths = c(5, 7),
      card(card_header("Métricas de los residuales"),
           card_body(verbatimTextOutput(ns("metricas_txt"), placeholder = TRUE))),
      card(card_header("Puntos seleccionados en el QQ (brush)"),
           card_body(DT::dataTableOutput(ns("seleccion"), height = "260px")))
    )
  )
}

mod_distribucion_server <- function(id, estado) {
  moduleServer(id, function(input, output, session) {

    res <- reactive(estado$resultado())

    output$qq <- renderPlot({
      r <- req(res()); if (!is.null(r$error)) return(NULL)
      graficar_qq(r)
    })

    output$hist <- renderPlot({
      r <- req(res()); if (!is.null(r$error)) return(NULL)
      graficar_hist(r)
    })

    output$metricas_txt <- renderText({
      r <- req(res()); if (!is.null(r$error)) return("")
      sprintf("Asimetría = %.3f   Curtosis (exceso) = %.3f\nShapiro W = %.3f (p = %.4g)",
              r$skewness, r$kurtosis, r$shapiro_stat, r$shapiro_p)
    })

    output$seleccion <- DT::renderDataTable({
      r <- req(res()); if (!is.null(r$error)) return(NULL)
      br <- input$brush_qq
      if (is.null(br)) return(NULL)
      d <- data.frame(residual = r$residuals,
                      grupo = r$datos$grupo,
                      valor = r$datos$valor)
      sel <- brushedPoints(d, br, yvar = "residual")
      if (nrow(sel) == 0) return(NULL)
      sel[order(abs(sel$residual), decreasing = TRUE), ]
    }, options = list(pageLength = 6, dom = "tp"), rownames = FALSE)
  })
}
