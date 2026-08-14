# libs/galeria/R/gal_inputs.R
#
# Tab "Inputs": un ejemplar de cada input de Shiny, con el valor al que se
# enlaza impreso en vivo debajo. Sirve para dos cosas:
#   1. Ver como el tema afecta a cada control.
#   2. Copiar la llamada exacta cuando armes un proyecto nuevo.

gal_inputs_ui <- function(id) {
  ns <- NS(id)

  navset_card_tab(
    title = "Controles de entrada",

    nav_panel(
      "Seleccion",
      layout_column_wrap(
        width = 1/3, fixed_width = FALSE,
        card(card_header("sliderInput()"),
             sliderInput(ns("slider"), NULL, min = 0, max = 100, value = 30)),
        card(card_header("sliderInput(range)"),
             sliderInput(ns("slider_rango"), NULL, min = 0, max = 100,
                         value = c(30, 70))),
        card(card_header("numericInput()"),
             numericInput(ns("numerico"), NULL, value = 42, min = 1, max = 100)),
        card(card_header("selectInput()"),
             selectInput(ns("select"), NULL, choices = state.abb[1:8])),
        card(card_header("selectizeInput(multiple)"),
             selectizeInput(ns("selectize"), NULL, choices = state.abb[1:8],
                            selected = c("AK", "CA"), multiple = TRUE)),
        card(card_header("radioButtons()"),
             radioButtons(ns("radio"), NULL, choices = c("lm", "loess", "gam"),
                          inline = TRUE))
      )
    ),

    nav_panel(
      "Texto y fechas",
      layout_column_wrap(
        width = 1/3, fixed_width = FALSE,
        card(card_header("textInput()"),
             textInput(ns("texto"), NULL, value = "Colombia")),
        card(card_header("textAreaInput()"),
             textAreaInput(ns("area"), NULL, value = "Notas de la corrida...",
                           rows = 3)),
        card(card_header("passwordInput()"),
             passwordInput(ns("pass"), NULL, value = "secreto")),
        card(card_header("dateInput()"),
             dateInput(ns("fecha"), NULL, value = "2020-12-24")),
        card(card_header("dateRangeInput()"),
             dateRangeInput(ns("fecha_rango"), NULL,
                            start = "2020-12-01", end = "2020-12-31")),
        card(card_header("fileInput()"),
             fileInput(ns("archivo"), NULL, accept = ".csv"))
      )
    ),

    nav_panel(
      "Casillas y botones",
      layout_column_wrap(
        width = 1/2, fixed_width = FALSE,
        card(card_header("checkboxInput()"),
             checkboxInput(ns("check"), "Escala logaritmica", value = TRUE),
             checkboxInput(ns("check2"), "Recalcular automaticamente")),
        card(card_header("checkboxGroupInput()"),
             checkboxGroupInput(ns("check_grupo"), NULL,
                                choices = c("Q-Q", "Residuos", "Cook", "Leverage"),
                                selected = c("Q-Q", "Residuos"))),
        card(
          card_header("Botones por rol de color"),
          # Los 6 roles semanticos de Bootstrap. Es la forma mas rapida de ver
          # si una paleta nueva tiene contraste suficiente.
          div(
            class = "d-flex flex-wrap gap-2",
            actionButton(ns("b_primary"),   "Primary",   class = "btn-primary"),
            actionButton(ns("b_secondary"), "Secondary", class = "btn-secondary"),
            actionButton(ns("b_success"),   "Success",   class = "btn-success"),
            actionButton(ns("b_info"),      "Info",      class = "btn-info"),
            actionButton(ns("b_warning"),   "Warning",   class = "btn-warning"),
            actionButton(ns("b_danger"),    "Danger",    class = "btn-danger")
          )
        ),
        card(
          card_header("Otros disparadores"),
          div(
            class = "d-flex flex-wrap gap-2 align-items-center",
            actionButton(ns("con_icono"), "Con icono",
                         icon = icon("chart-line")),
            downloadButton(ns("bajar"), "downloadButton()"),
            actionLink(ns("enlace"), "actionLink()")
          )
        )
      )
    ),

    nav_panel(
      "Valores enlazados",
      card(
        card_header("Estado reactivo de todos los inputs de arriba"),
        card_body(
          # Espejo en vivo: mover cualquier control de esta pestana se refleja
          # aca. Es el mismo truco que usa la demo de bslib.
          verbatimTextOutput(ns("valores"))
        )
      )
    )
  )
}

gal_inputs_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    output$valores <- renderPrint({
      str(list(
        sliderInput          = input$slider,
        sliderInputRango     = input$slider_rango,
        numericInput         = input$numerico,
        selectInput          = input$select,
        selectizeMultiInput  = input$selectize,
        radioButtons         = input$radio,
        textInput            = input$texto,
        dateInput            = input$fecha,
        dateRangeInput       = input$fecha_rango,
        checkboxInput        = input$check,
        checkboxGroupInput   = input$check_grupo
      ))
    })

    output$bajar <- downloadHandler(
      filename = function() "galeria-demo.csv",
      content  = function(file) utils::write.csv(gen_sintetico(n = 20), file,
                                                  row.names = FALSE)
    )
  })
}
