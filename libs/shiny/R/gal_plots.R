# libs/galeria/R/gal_plots.R
#
# Tab "Plots": salidas graficas y las tres interacciones que Shiny expone
# sobre un plotOutput (brush, click, hover).
#
# Nota sobre thematic: es el paquete que hace que los ggplot HEREDEN los
# colores y la fuente del tema bslib. Se activa en el server de este modulo
# con thematic_shiny(). No se activa en .Rprofile porque alli pelea con el
# device de httpgd (unigd) — ver "Problemas conocidos" en libs/shiny/README.md.

gal_plots_ui <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(8, 4),

      card(
        full_screen = TRUE,
        card_header("plotOutput() con brush + click + hover"),
        card_body(
          plotOutput(ns("principal"), height = "380px",
                     brush = brushOpts(ns("brush")),
                     click = ns("click"),
                     hover = hoverOpts(ns("hover"), delay = 100))
        )
      ),

      card(
        card_header("Que devuelve cada interaccion"),
        card_body(
          strong("brush"),   verbatimTextOutput(ns("info_brush")),
          strong("click"),   verbatimTextOutput(ns("info_click")),
          strong("hover"),   verbatimTextOutput(ns("info_hover"))
        )
      )
    ),

    br(),

    card(
      card_header("Controles del grafico"),
      layout_column_wrap(
        width = 1/4, fixed_width = FALSE,
        sliderInput(ns("n"), "n", min = 20, max = 400, value = 120, step = 20),
        sliderInput(ns("ruido"), "Ruido (sd)", min = 0, max = 5, value = 1,
                    step = 0.1),
        selectInput(ns("geom"), "Geometria",
                    c("puntos", "linea", "ambos"), selected = "ambos"),
        checkboxInput(ns("suavizado"), "Agregar geom_smooth()", TRUE)
      )
    ),

    br(),

    h4("Otras salidas graficas"),
    layout_columns(
      col_widths = c(6, 6),
      card(card_header("Barras por grupo"),
           plotOutput(ns("barras"), height = "280px")),
      card(card_header("Boxplot por grupo"),
           plotOutput(ns("caja"), height = "280px"))
    )
  )
}

gal_plots_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # thematic_shiny(): los ggplot toman bg/fg/accent del tema bslib activo.
    # Cambiar de preset en el menu "Tema" repinta tambien estos graficos.
    if (requireNamespace("thematic", quietly = TRUE)) {
      thematic::thematic_shiny()
    }

    datos <- reactive({
      gen_sintetico(n = input$n, ruido = input$ruido, tipo = "regresion")
    })

    grupos <- reactive({
      gen_sintetico(n = 160, k_grupos = 4, tipo = "anova")
    })

    output$principal <- renderPlot({
      d <- datos()
      p <- ggplot(d, aes(x = x, y = y))
      if (input$geom %in% c("puntos", "ambos"))
        p <- p + geom_point(alpha = 0.6, size = 2)
      if (input$geom %in% c("linea", "ambos"))
        p <- p + geom_line(aes(y = y_verdadero), linewidth = 1, linetype = "dashed")
      if (isTRUE(input$suavizado))
        p <- p + geom_smooth(method = "loess", formula = y ~ x, se = TRUE)
      p + labs(title = "Datos sinteticos", x = "x", y = "y",
               caption = "Arrastra para brush, clickea o pasa el mouse") +
        tema_ggplot()
    })

    output$info_brush <- renderPrint({
      br <- input$brush
      if (is.null(br)) return(cat("NULL — arrastra sobre el grafico"))
      sel <- brushedPoints(datos(), br, xvar = "x", yvar = "y")
      cat(sprintf("%d puntos seleccionados\nx: [%.2f, %.2f]\ny: [%.2f, %.2f]",
                  nrow(sel), br$xmin, br$xmax, br$ymin, br$ymax))
    })

    output$info_click <- renderPrint({
      cl <- input$click
      if (is.null(cl)) return(cat("NULL — clickea el grafico"))
      cat(sprintf("x = %.3f\ny = %.3f", cl$x, cl$y))
    })

    output$info_hover <- renderPrint({
      hv <- input$hover
      if (is.null(hv)) return(cat("NULL — pasa el mouse"))
      cat(sprintf("x = %.3f\ny = %.3f", hv$x, hv$y))
    })

    output$barras <- renderPlot({
      d <- grupos()
      agg <- aggregate(valor ~ grupo, data = d, FUN = mean)
      ggplot(agg, aes(x = grupo, y = valor, fill = grupo)) +
        geom_col() +
        labs(title = "Media por grupo", x = NULL, y = "valor") +
        tema_ggplot() +
        theme(legend.position = "none")
    })

    output$caja <- renderPlot({
      ggplot(grupos(), aes(x = grupo, y = valor, fill = grupo)) +
        geom_boxplot() +
        labs(title = "Distribucion por grupo", x = NULL, y = "valor") +
        tema_ggplot() +
        theme(legend.position = "none")
    })
  })
}
