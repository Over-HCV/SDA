# libs/shiny/R/gal_tipografia.R
#
# Tab "Galeria > Tipografia": la escala de texto, los roles de color y las
# variables Sass que efectivamente tiene el tema activo.
#
# El bloque de variables se lee del tema EN VIVO con bs_get_variables(), asi
# que refleja lo que hayas movido en el widget "Theme customizer" (bs_themer).
# Es la forma de responder "¿que valor tiene font-size-base ahora mismo?"

# Variables que vale la pena vigilar al disenar un tema.
.VARS_TEMA <- c(
  "bg", "fg", "primary", "secondary", "success", "info", "warning", "danger",
  "body-bg", "body-color", "font-size-base", "font-family-base",
  "border-radius", "enable-rounded", "enable-shadows", "enable-gradients",
  "spacer", "card-bg", "border-color"
)

gal_tipografia_ui <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(7, 5),

      card(
        card_header("Escala tipografica"),
        card_body(
          h1("h1 — Titulo principal"),
          h2("h2 — Seccion"),
          h3("h3 — Subseccion"),
          h4("h4 — Encabezado menor"),
          h5("h5"), h6("h6"),
          hr(),
          p("Parrafo normal. La fuente base sale de ",
            code("base_font"), " en ", code("bs_theme()"), "."),
          p(class = "lead", "Parrafo .lead — mas grande, para bajadas."),
          p(tags$small("tags$small() — texto secundario.")),
          p(strong("strong"), " · ", em("em"), " · ",
            code("code inline"), " · ",
            tags$a("un enlace", href = "#")),
          hr(),
          tags$pre("bloque pre / verbatim\n  indentado\n  monoespaciado"),
          tags$blockquote(class = "blockquote",
                          "Una cita en blockquote.")
        )
      ),

      div(
        card(
          card_header("Roles de color del tema"),
          card_body(
            # Cada barra usa las clases utilitarias bg-* de Bootstrap: si un
            # preset tiene mal contraste, se ve de inmediato aca.
            !!!lapply(
              c("primary", "secondary", "success", "info", "warning",
                "danger", "light", "dark"),
              function(rol) {
                div(
                  class = paste0("p-2 mb-1 bg-", rol,
                                 if (rol %in% c("light")) " text-dark" else " text-white"),
                  rol
                )
              }
            )
          )
        ),

        card(
          card_header("Fuente activa"),
          card_body(verbatimTextOutput(ns("fuente")))
        )
      )
    ),

    br(),

    card(
      card_header("Variables Sass del tema activo (bs_get_variables)"),
      card_body(
        p("Cambia de preset en el menu ", strong("Tema"),
          " o mueve el widget ", strong("Theme customizer"),
          " y esta tabla se actualiza."),
        DT::dataTableOutput(ns("variables"))
      )
    ),

    br(),

    card(
      card_header("Como llevar esto a codigo"),
      card_body(
        tags$ol(
          tags$li("Abri el widget ", strong("Theme customizer"),
                  " (arriba a la derecha) y ajusta colores/fuentes."),
          tags$li("Mira la CONSOLA de R: el widget imprime el ",
                  code("bs_theme()"), " equivalente."),
          tags$li("Pega esos argumentos en ",
                  code("libs/_comun/R/temas_bslib.R"), " como preset nuevo."),
          tags$li("El CSS fino que Sass no cubre va en ",
                  code("libs/_comun/scss/custom.scss"), ".")
        ),
        tags$pre(
          'tema_mio <- bs_theme(\n',
          '  bg = "#e5e5e5", fg = "#0d0c0c", primary = "#dd2020",\n',
          '  base_font = font_google("Press Start 2P"),\n',
          '  code_font = font_google("Press Start 2P"),\n',
          '  "font-size-base" = "0.75rem", "enable-rounded" = FALSE\n',
          ') |>\n',
          '  bs_add_rules(list(\n',
          '    sass::sass_file("libs/_comun/scss/retro.scss"),\n',
          '    sass::sass_file("libs/_comun/scss/custom.scss")\n',
          '  ))'
        )
      )
    )
  )
}

gal_tipografia_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # getCurrentTheme() devuelve el tema vigente, incluidos los cambios que
    # haya hecho bs_themer() en esta sesion.
    vars_actuales <- reactive({
      t <- session$getCurrentTheme()
      if (!bslib::is_bs_theme(t)) return(NULL)
      vals <- tryCatch(bslib::bs_get_variables(t, .VARS_TEMA),
                       error = function(e) NULL)
      if (is.null(vals)) return(NULL)
      data.frame(
        variable = names(vals),
        valor    = unname(ifelse(is.na(vals), "(sin definir)", vals)),
        stringsAsFactors = FALSE
      )
    })

    output$variables <- DT::renderDataTable({
      df <- vars_actuales()
      validate(need(!is.null(df),
                    "El tema activo no es un bs_theme (o no se pudo compilar)."))
      DT::datatable(df, options = list(pageLength = 20, dom = "t"),
                    rownames = FALSE)
    })

    output$fuente <- renderPrint({
      df <- vars_actuales()
      if (is.null(df)) return(cat("No disponible."))
      ff <- df$valor[df$variable == "font-family-base"]
      fs <- df$valor[df$variable == "font-size-base"]
      cat("font-family-base:\n  ", if (length(ff)) ff else "?", "\n\n",
          "font-size-base:\n  ", if (length(fs)) fs else "?", sep = "")
    })
  })
}
