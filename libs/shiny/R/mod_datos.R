# libs/shiny/R/mod_datos.R
#
# Módulo del tab "Datos". DT::dataTable con todos los datos subyacentes,
# y resaltado de los puntos seleccionados por brush desde el tab Ajuste.

mod_datos_ui <- function(id) {
  ns <- NS(id)
  layout_columns(
    col_widths = c(8, 4),
    card(
      full_screen = TRUE,
      card_header("Tabla completa (filtrable, ordenable)"),
      DT::dataTableOutput(ns("tabla"), height = "500px")
    ),
    card(
      card_header("Puntos seleccionados (brush)"),
      card_body(
        verbatimTextOutput(ns("n_brush")),
        DT::dataTableOutput(ns("brushed"), height = "350px")
      )
    )
  )
}

mod_datos_server <- function(id, estado) {
  moduleServer(id, function(input, output, session) {

    output$tabla <- DT::renderDataTable({
      d <- req(estado$datos())
      a <- tryCatch(estado$ajuste(), error = function(e) NULL)
      if (!is.null(a) && is.null(a$error)) d$pred <- as.numeric(a$pred)
      tab <- DT::datatable(d, options = list(pageLength = 12),
                           filter = "top", rownames = FALSE)
      if ("pred" %in% names(d)) DT::formatRound(tab, "pred", 3) else tab
    })

    output$brushed <- DT::renderDataTable({
      a <- req(estado$ajuste()); if (!is.null(a$error)) return(NULL)
      d <- estado$datos()
      br <- estado$brush()
      if (is.null(br) || nrow(d) == 0) return(NULL)
      sel <- brushedPoints(d, br, xvar = names(d)[1], yvar = "y")
      DT::datatable(sel, options = list(pageLength = 8,
                                         dom = "tp"),
                    rownames = FALSE)
    })

    output$n_brush <- renderText({
      a <- req(estado$ajuste()); if (!is.null(a$error)) return("")
      br <- estado$brush()
      if (is.null(br)) return("Sin selección.")
      d <- estado$datos()
      n <- nrow(brushedPoints(d, br, xvar = names(d)[1], yvar = "y"))
      sprintf("Puntos en selección: %d", n)
    })
  })
}
