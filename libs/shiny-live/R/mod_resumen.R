# libs/shiny-live/R/mod_resumen.R
#
# Módulo del tab "Resumen". Texto formateado con summary(aov) + tabla DT con
# los tests de supuestos (Shapiro, Levene, Bartlett) y sus p-values, más las
# medias por grupo. Solo lectura.
#
# Showcase: layout_columns, card, navset_card_tab, verbatimTextOutput,
# DT::dataTableOutput.

mod_resumen_ui <- function(id) {
  ns <- NS(id)
  layout_columns(
    col_widths = c(7, 5),
    card(full_screen = TRUE,
         card_header("summary(aov) del modelo"),
         card_body(verbatimTextOutput(ns("summary_txt"), placeholder = TRUE))),
    navset_card_tab(
      nav_panel("Tests de supuestos",
                card_body(DT::dataTableOutput(ns("tests")), height = "auto")),
      nav_panel("Medias por grupo",
                card_body(DT::dataTableOutput(ns("medias")), height = "auto"))
    )
  )
}

mod_resumen_server <- function(id, estado) {
  moduleServer(id, function(input, output, session) {

    output$summary_txt <- renderPrint({
      r <- req(estado$resultado())
      if (!is.null(r$error)) cat("Error:", r$error, "\n")
      else cat(formatear_resumen_anova(r), sep = "\n")
    })

    output$tests <- DT::renderDataTable({
      r <- req(estado$resultado()); if (!is.null(r$error)) return(NULL)
      df <- data.frame(
        Test = c("Shapiro-Wilk (normalidad)", "Levene (homocedasticidad)",
                 "Bartlett (homocedasticidad)"),
        Estadistico = c(r$shapiro_stat, r$levene_stat, r$bartlett_stat),
        p_value = c(r$shapiro_p, r$levene_p, r$bartlett_p),
        stringsAsFactors = FALSE, check.names = FALSE
      )
      df$Conclusion <- ifelse(df$p_value < 0.05, "rechaza H0 (p<0.05)", "no rechaza H0")
      DT::datatable(df, options = list(dom = "t"), rownames = FALSE) |>
        DT::formatRound(c("Estadistico", "p_value"), 4)
    })

    output$medias <- DT::renderDataTable({
      r <- req(estado$resultado()); if (!is.null(r$error)) return(NULL)
      m <- r$medias_grupo
      df <- data.frame(grupo = names(m),
                       media = unname(m),
                       n = as.integer(table(r$datos$grupo)[names(m)]),
                       stringsAsFactors = FALSE, check.names = FALSE)
      DT::datatable(df, options = list(dom = "t"), rownames = FALSE) |>
        DT::formatRound("media", 3)
    })
  })
}
