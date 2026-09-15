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

    # Antes era una lista escrita a mano del Hito 1 ("54 métodos", "las fases
    # todavía no calculan") y quedó mintiendo en cuanto la fase 1 y los primeros
    # métodos corrieron. Las cuentas y los nombres salen del registro.
    output$ruta <- shiny::renderUI({
      catalogo <- metodos_df()
      activos <- catalogo[catalogo$estado == "activo", , drop = FALSE]
      bloqueados <- catalogo$clave[catalogo$estado == "bloqueado"]
      nombres_activos <- if (nrow(activos))
        paste(activos$nombre, collapse = " y ") else "ninguno todavía"
      shiny::tags$ol(
        class = "mb-0 ps-3",
        shiny::tags$li(shiny::tags$strong("① Datos"),
                       ": cargá una fuente (", shiny::tags$code("ori"),
                       " es la del Taller 01), filtrá, declará el diccionario",
                       " y mirá ▣ Análisis."),
        shiny::tags$li("Marcá ", shiny::tags$strong("Añadir"),
                       " en los paneles que quieras entregar y bajalos desde ",
                       shiny::tags$strong("Informe"),
                       " como un cuaderno .Rmd que corre solo."),
        shiny::tags$li(shiny::tags$strong("② Modelado → Catálogo"),
                       sprintf(": %d métodos registrados, %d corren hoy (%s).",
                               nrow(catalogo), nrow(activos), nombres_activos)),
        if (nrow(activos)) shiny::tags$li(
          shiny::tags$strong("③ Ajuste"), " y ", shiny::tags$strong("④ Evaluación"),
          ": corré uno de esos métodos sobre tu dataset y mirá sus diagnósticos."),
        if (length(bloqueados)) shiny::tags$li(
          "Abrí la ficha de ", shiny::tags$code(bloqueados[1]),
          " (bloqueado) y leé el puente: conecta un método inalcanzable con",
          " uno que sí corre acá.")
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
