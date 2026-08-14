# learn/R/ui/f0/inicio.R
#
# Inicio · dónde estoy, qué hay hecho, por dónde sigo.
#
# Todo lo que muestra sale del registro y del almacén, nunca de constantes
# escritas a mano: si el catálogo crece, el mapa del curso crece solo.

TITULOS_SESION <- c(
  "1" = "Herramientas básicas", "2" = "Herramientas básicas (II)",
  "3" = "Normal multivariada y visualización", "4" = "Componentes principales",
  "5" = "Agrupamiento", "6" = "Regresión múltiple",
  "7" = "Regresión múltiple (II)", "8" = "Análisis de varianza")

mod_inicio_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    bslib::layout_columns(
      col_widths = c(5, 7),
      bslib::card(
        bslib::card_header("Estado de la sesión"),
        bslib::card_body(shiny::uiOutput(ns("estado")))),
      bslib::card(
        bslib::card_header("Por dónde empezar"),
        bslib::card_body(shiny::uiOutput(ns("ruta"))))
    ),
    bslib::card(
      class = "mt-3",
      bslib::card_header("Mapa del curso"),
      bslib::card_body(shiny::uiOutput(ns("mapa_curso"))),
      bslib::card_footer(
        class = "small text-muted",
        paste("Cada barra cuenta métodos listos sobre métodos registrados en",
              "esa sesión. Los bloqueados no cuentan como pendientes: no van a",
              "estar nunca."))
    ),
    bslib::card(
      class = "mt-3",
      bslib::card_header("Últimas corridas"),
      bslib::card_body(shiny::uiOutput(ns("corridas"))))
  )
}

mod_inicio_server <- function(id, almacen) {
  shiny::moduleServer(id, function(input, output, session) {

    output$estado <- shiny::renderUI({
      cuentas <- almacen()
      cobertura <- cobertura_textos()
      shiny::tagList(
        franja_estado(list(
          "datasets" = almacen_contar(cuentas, "dataset"),
          "modelos"  = almacen_contar(cuentas, "modelo"),
          "recetas"  = almacen_contar(cuentas, "receta"),
          "corridas" = almacen_contar(cuentas, "corrida"))),
        shiny::tags$div(
          class = "mt-3",
          barra_progreso(cobertura$fichas_escritas, cobertura$fichas_esperadas,
                         "Fichas de método escritas"),
          barra_progreso(cobertura$textos_escritos, cobertura$textos_esperados,
                         "Textos de gráficos escritos"))
      )
    })

    output$ruta <- shiny::renderUI({
      shiny::tags$ol(
        class = "mb-0 ps-3",
        shiny::tags$li(shiny::tags$strong("Modelado → Catálogo"),
                       ": mirá los 54 métodos y abrí una ficha."),
        shiny::tags$li("Probá el filtro ", shiny::tags$em("Solo los que corren",
                       " en este modo"), " para ver qué cambia entre navegador",
                       " y servidor."),
        shiny::tags$li("Abrí la ficha de ", shiny::tags$code("mlp"),
                       " (bloqueado) y leé el puente: conecta un método",
                       " inalcanzable con uno que sí corre acá."),
        shiny::tags$li("Fases 1, 3 y 4 navegables, todavía no",
                       " calculan. Avance está en ",
                       shiny::tags$code("learn/PLAN.md"), ".")
      )
    })

    output$mapa_curso <- shiny::renderUI({
      progreso <- progreso_por_sesion()
      if (!nrow(progreso)) return(shiny::tags$p("Catálogo vacío."))
      shiny::tagList(lapply(seq_len(nrow(progreso)), function(i) {
        fila <- progreso[i, ]
        etiqueta <- sprintf("Sesión %d · %s", fila$sesion,
                            TITULOS_SESION[[as.character(fila$sesion)]] %||% "")
        shiny::tags$div(class = "mb-2",
                        barra_progreso(fila$activos, fila$total, etiqueta))
      }))
    })

    output$corridas <- shiny::renderUI({
      recientes <- corridas_recientes(almacen())
      if (!length(recientes))
        return(shiny::tags$p(class = "text-muted mb-0",
                             paste("Todavía no hay corridas. Se crean en la",
                                   "fase 4, componiendo un dataset, un modelo",
                                   "y una receta.")))
      shiny::tags$ul(class = "list-unstyled mb-0", lapply(recientes, function(cor)
        shiny::tags$li(class = "border-bottom py-1",
                       shiny::tags$code(cor$id), " ", resumen_objeto(cor),
                       shiny::tags$span(class = "text-muted small ms-2",
                                        cor$creado))))
    })
  })
}
