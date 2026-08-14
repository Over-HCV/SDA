# libs/shiny/R/mod_resumen.R
#
# Módulo del tab "Resumen". Texto formateado con el summary del modelo
# y tarjetas con coeficientes/intervalos. Solo lectura, no inputs.

mod_resumen_ui <- function(id) {
  ns <- NS(id)
  layout_columns(
    col_widths = c(7, 5),
    card(
      full_screen = TRUE,
      card_header("summary() del modelo ajustado"),
      card_body(verbatimTextOutput(ns("summary_txt"), placeholder = TRUE))
    ),
    navset_card_tab(
      nav_panel(
        "Coeficientes",
        card_body(DT::dataTableOutput(ns("coefs")), height = "auto")
      ),
      nav_panel(
        "Métricas",
        card_body(uiOutput(ns("metricas_ui")))
      )
    )
  )
}

mod_resumen_server <- function(id, estado) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$summary_txt <- renderPrint({
      a <- req(estado$ajuste())
      if (!is.null(a$error)) cat("Error:", a$error, "\n") else cat(formatear_resumen(a), sep = "\n")
    })

    output$coefs <- DT::renderDataTable({
      a <- req(estado$ajuste())
      if (!is.null(a$error) || is.null(a$coefs)) return(NULL)
      ci <- tryCatch(confint(a$fit), error = function(e) NULL)
      df <- data.frame(
        termino = names(a$coefs),
        estimado = unname(a$coefs),
        `IC 2.5%`  = if (!is.null(ci)) ci[, 1] else NA_real_,
        `IC 97.5%` = if (!is.null(ci)) ci[, 2] else NA_real_,
        check.names = FALSE
      )
      DT::datatable(df, options = list(dom = "t"), rownames = FALSE) |>
        DT::formatRound(c("estimado", "IC 2.5%", "IC 97.5%"), 4)
    })

    output$metricas_ui <- renderUI({
      a <- req(estado$ajuste()); if (!is.null(a$error)) return(NULL)
      tagList(
        metric_box("R²", sprintf("%.4f", a$r2), theme = "primary"),
        metric_box("RMSE", sprintf("%.4f", a$rmse), theme = "success"),
        metric_box("Grado", as.character(a$grado), theme = "info"),
        metric_box("Método", a$metodo, theme = "secondary"),
        metric_box("N", as.character(a$n), theme = "dark")
      )
    })
  })
}

metric_box <- function(titulo, valor, theme = "primary") {
  div(class = sprintf("border border-%s rounded p-2 mb-1 text-%s",
                       theme, theme),
      tags$small(class = "text-muted", titulo),
      tags$h5(class = "mb-0", valor))
}
