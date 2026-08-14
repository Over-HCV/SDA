# libs/galeria/R/gal_layout.R
#
# Tab "Cards": los contenedores de bslib. Es el catalogo que consultas cuando
# armas el layout de un proyecto nuevo y no te acordas como se llamaba la
# funcion que hace la grilla.

gal_layout_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # --- value_box: los 6 roles de color -----------------------------------
    h4("value_box()"),
    layout_column_wrap(
      width = 1/3, fixed_width = FALSE,
      value_box("R cuadrado", "0.8197", showcase = bsicons::bs_icon("graph-up"),
                theme = "primary"),
      value_box("RMSE", "95.61", showcase = bsicons::bs_icon("rulers"),
                theme = "success"),
      value_box("n", "30", showcase = bsicons::bs_icon("hash"),
                theme = "info"),
      value_box("AIC", "412.3", showcase = bsicons::bs_icon("sliders"),
                theme = "warning"),
      value_box("Outliers", "4", showcase = bsicons::bs_icon("exclamation-triangle"),
                theme = "danger"),
      value_box("Iteraciones", "128", showcase = bsicons::bs_icon("arrow-repeat"),
                theme = "secondary")
    ),

    hr(),

    # --- card en sus variantes ---------------------------------------------
    h4("card()"),
    layout_columns(
      col_widths = c(4, 4, 4),
      card(
        card_header("card simple"),
        card_body("Header + body. El contenedor por defecto de bslib.")
      ),
      card(
        full_screen = TRUE,
        card_header("full_screen = TRUE"),
        card_body(
          "Pasa el mouse por encima: aparece el icono de expandir en la ",
          "esquina inferior derecha."
        )
      ),
      card(
        card_header(
          "Con popover",
          # popover/tooltip cuelgan del header, no del card: si los pones en el
          # body quedan tapados por el overflow.
          popover(
            bsicons::bs_icon("info-circle"),
            title = "popover()",
            "Contenido que aparece al hacer click en el icono."
          ),
          class = "d-flex justify-content-between align-items-center"
        ),
        card_body(
          tooltip(
            span("Esto tiene tooltip ", bsicons::bs_icon("question-circle")),
            "Aparece al pasar el mouse."
          )
        )
      )
    ),

    hr(),

    # --- grillas ------------------------------------------------------------
    h4("layout_columns() — anchos explicitos"),
    layout_columns(
      col_widths = c(8, 4),
      card(card_header("col_widths = 8"), card_body("Dos tercios del ancho.")),
      card(card_header("col_widths = 4"), card_body("Un tercio."))
    ),

    br(),

    h4("layout_column_wrap() — celdas iguales que hacen wrap"),
    layout_column_wrap(
      width = 1/4, fixed_width = FALSE,
      card(card_body("1")), card(card_body("2")),
      card(card_body("3")), card(card_body("4"))
    ),

    hr(),

    # --- accordion + tabs ---------------------------------------------------
    h4("accordion() y navset_card_tab()"),
    layout_columns(
      col_widths = c(6, 6),
      accordion(
        id = ns("acc"),
        open = "Primero",
        accordion_panel("Primero", icon = bsicons::bs_icon("1-circle"),
                        "Abierto por defecto via open ="),
        accordion_panel("Segundo", icon = bsicons::bs_icon("2-circle"),
                        "Los paneles colapsan de a uno."),
        accordion_panel("Tercero", icon = bsicons::bs_icon("3-circle"),
                        "Util para esconder controles avanzados.")
      ),
      navset_card_tab(
        title = "navset_card_tab()",
        nav_panel("Uno",  "Tabs dentro de un card."),
        nav_panel("Dos",  "Cada nav_panel es un tab."),
        nav_panel("Tres", "Se usa en Diagnosticos y Resumen del Proyecto 1.")
      )
    ),

    hr(),

    # --- sidebar ------------------------------------------------------------
    h4("card() con sidebar()"),
    card(
      card_header("layout_sidebar() dentro de un card"),
      layout_sidebar(
        sidebar = sidebar(
          title = "Controles",
          sliderInput(ns("s_lateral"), "Un control", 0, 10, 5),
          checkboxInput(ns("c_lateral"), "Otro control", TRUE)
        ),
        "El sidebar colapsa con el boton de la esquina. ",
        "Es el layout del tab Ajuste del Proyecto 1."
      )
    )
  )
}

gal_layout_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Este tab es puramente declarativo: no hay estado que manejar.
  })
}
