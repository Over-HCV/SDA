# libs/shiny/R/gal_tablas.R
#
# Tab "Galeria > Tablas": DT en sus variantes y las salidas de texto.
# DT es el que mas sufre con un tema custom (trae CSS propio), asi que este
# tab es el que hay que mirar primero al cambiar de preset.

gal_tablas_ui <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(7, 5),

      card(
        full_screen = TRUE,
        card_header("DT::datatable() completo — filtro, orden, paginacion"),
        DT::dataTableOutput(ns("completa"))
      ),

      card(
        card_header("Seleccion de filas (server -> UI)"),
        card_body(
          # DT expone <id>_rows_selected como input reactivo. Es la via mas
          # simple de cross-filter entre una tabla y un plot.
          verbatimTextOutput(ns("seleccion")),
          plotOutput(ns("plot_sel"), height = "240px")
        )
      )
    ),

    br(),

    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("datatable(dom = 't') — sin controles, para tablas cortas"),
        DT::dataTableOutput(ns("compacta"))
      ),
      card(
        card_header("formatRound() + formatStyle()"),
        DT::dataTableOutput(ns("formateada"))
      )
    ),

    br(),

    h4("Salidas de texto"),
    layout_columns(
      col_widths = c(6, 6),
      card(card_header("verbatimTextOutput() — summary de un modelo"),
           verbatimTextOutput(ns("verbatim"))),
      card(card_header("tableOutput() — el render base de Shiny"),
           tableOutput(ns("base")))
    )
  )
}

gal_tablas_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    datos <- reactive({
      d <- gen_sintetico(n = 60, tipo = "regresion")
      d$grupo <- factor(rep(LETTERS[1:4], length.out = nrow(d)))
      d
    })

    output$completa <- DT::renderDataTable({
      DT::datatable(
        datos(),
        options   = list(pageLength = 8),
        filter    = "top",
        selection = "multiple",
        rownames  = FALSE
      )
    })

    output$seleccion <- renderPrint({
      sel <- input$completa_rows_selected
      if (!length(sel)) return(cat("Sin filas seleccionadas.\n",
                                   "Clickea filas en la tabla de la izquierda."))
      cat(sprintf("Filas seleccionadas: %s", paste(sel, collapse = ", ")))
    })

    output$plot_sel <- renderPlot({
      d <- datos()
      sel <- input$completa_rows_selected
      d$estado <- ifelse(seq_len(nrow(d)) %in% sel, "seleccionado", "resto")
      ggplot(d, aes(x = x, y = y, color = estado, size = estado)) +
        geom_point(alpha = 0.8) +
        scale_size_manual(values = c(seleccionado = 3.5, resto = 1.5)) +
        labs(title = "Cross-filter tabla -> plot", x = "x", y = "y") +
        tema_ggplot() +
        theme(legend.position = "bottom")
    })

    output$compacta <- DT::renderDataTable({
      d <- aggregate(valor ~ grupo, data = gen_sintetico(n = 100, tipo = "anova"),
                     FUN = mean)
      names(d) <- c("grupo", "media")
      DT::datatable(d, options = list(dom = "t"), rownames = FALSE) |>
        DT::formatRound("media", 3)
    })

    output$formateada <- DT::renderDataTable({
      d <- datos()[1:10, c("x", "y", "y_verdadero")]
      d$resid <- d$y - d$y_verdadero
      DT::datatable(d, options = list(dom = "t"), rownames = FALSE) |>
        DT::formatRound(c("x", "y", "y_verdadero", "resid"), 3) |>
        # Residuales negativos en rojo, positivos en verde.
        DT::formatStyle("resid",
                        color = DT::styleInterval(0, c("#c0392b", "#27ae60")),
                        fontWeight = "bold")
    })

    output$verbatim <- renderPrint({
      d <- datos()
      summary(lm(y ~ poly(x, 3, raw = TRUE), data = d))
    })

    output$base <- renderTable({
      d <- gen_sintetico(n = 100, tipo = "anova")
      agg <- aggregate(valor ~ grupo, data = d,
                       FUN = function(v) c(media = mean(v), sd = stats::sd(v)))
      out <- data.frame(grupo = agg$grupo,
                        media = agg$valor[, "media"],
                        sd    = agg$valor[, "sd"])
      out
    }, digits = 3)
  })
}
