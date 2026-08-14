# libs/shiny/R/mod_diagnostico.R
#
# Módulo del tab "Diagnósticos". Muestra los 4 gráficos de diagnóstico
# (QQ, residuales vs ajuste, Cook, leverage) en un grid 2x2. El usuario
# elija cuáles mostrar vía checkboxGroupInput.

mod_diagnostico_ui <- function(id) {
  ns <- NS(id)
  navset_card_tab(
    title = "Diagnósticos del modelo",
    id = ns("diag_tab"),
    nav_panel(
      "Grid",
      card(
        card_body(
          checkboxGroupInput(
            ns("cuales"), "Mostrar:",
            choices = c("QQ" = "qq", "Residuales vs ajuste" = "rvf",
                        "Distancia de Cook" = "cook", "Leverage" = "leverage"),
            selected = c("qq", "rvf", "cook", "leverage"),
            inline = TRUE
          ),
          uiOutput(ns("grid"))
        )
      )
    ),
    nav_panel(
      "Tabla de residuales",
      DT::dataTableOutput(ns("tabla_resid"), height = "500px")
    )
  )
}

mod_diagnostico_server <- function(id, estado) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    diagnosticos_react <- reactive({
      a <- req(estado$ajuste())
      if (!is.null(a$error)) return(NULL)
      diagnosticos(a)
    })

    # Render dinámico del grid según selección de checkboxes
    output$grid <- renderUI({
      req(diagnosticos_react())
      sel <- input$cuales
      if (length(sel) == 0) {
        return(div(class = "text-muted p-4",
                   "Selecciona al menos un diagnóstico arriba."))
      }
      # Layout adaptativo: 1 col si 1-2, 2 cols si 3-4
      ancho <- if (length(sel) <= 2) 12 else 6
      do.call(layout_columns, c(
        col_widths = rep(ancho, length(sel)),
        lapply(sel, function(nm) {
          card(card_header(titulo_diag(nm)),
               card_body(plotOutput(ns(paste0("diag_", nm)),
                                    height = "300px")))
        })
      ))
    })

    # Un renderPlot por diagnóstico (siempre definidos, el UI decide mostrar)
    output$diag_qq       <- renderPlot(diagnosticos_react()$qq)
    output$diag_rvf      <- renderPlot(diagnosticos_react()$rvf)
    output$diag_cook     <- renderPlot(diagnosticos_react()$cook)
    output$diag_leverage <- renderPlot(diagnosticos_react()$leverage)

    # Tabla de residuales
    output$tabla_resid <- DT::renderDataTable({
      a <- req(estado$ajuste()); if (!is.null(a$error)) return(NULL)
      d <- a$datos
      df <- data.frame(
        x      = d$x,
        y      = d$y,
        pred   = as.numeric(a$pred),
        resid  = as.numeric(a$resid),
        cooks  = if (is.null(a$cooks)) NA_real_ else a$cooks,
        hat    = if (is.null(a$hat))   NA_real_ else a$hat
      )
      DT::datatable(df, options = list(pageLength = 15),
                    filter = "top", rownames = FALSE) |>
        DT::formatRound(c("y", "pred", "resid", "cooks", "hat"), 3)
    })
  })
}

titulo_diag <- function(nm) {
  switch(nm,
         qq       = "QQ de residuales",
         rvf      = "Residuales vs ajuste",
         cook     = "Distancia de Cook",
         leverage = "Residuales vs leverage",
         nm)
}
