# learn/R/ui/f4/evaluacion.R
#
# Responsabilidad: cablear la fase 4. No calcula ni dibuja nada por su cuenta.
#
# Es la fase que compone: toma los tres objetos que produjeron las fases
# anteriores, valida que se puedan juntar, corre, y reparte el resultado a las
# subsecciones. La Corrida vive en un reactiveVal de este módulo y es lo único
# que las cuatro vistas comparten.
#
# Comparación sigue pendiente: comparar corridas exige tener varias, y varias
# exigen más de un método. Entra en el Hito 6, con su motivo escrito.

SUBSECCIONES_EVALUACION <- c("Composición", "Desempeño", "Diagnóstico",
                             "Explicabilidad", "Comparación",
                             ETIQUETA_ANALISIS)

# Todo lo que la fase 4 sabe dibujar. Cada card se muestra si el método de la
# corrida la declara en `artefactos` (SCHEMA.md §4).
CLAVES_EVALUACION <- c("f4.desempeno.grupos",
                       "f4.diagnostico.scree", "f4.diagnostico.codo",
                       "f4.diagnostico.silueta",
                       "f4.explicabilidad.cargas",
                       "f4.explicabilidad.circulo_correlaciones",
                       "f4.explicabilidad.mapa_2d",
                       "f4.explicabilidad.biplot",
                       "f4.explicabilidad.centroides")

DETALLE_COMPARACION <- paste(
  "Métricas de varias corridas lado a lado, coordenadas paralelas de",
  "hiperparámetros contra métrica y superposición de curvas. Necesita más de",
  "un método implementado para decir algo: entra en el Hito 6.")

mod_evaluacion_ui <- function(id) {
  ns <- shiny::NS(id)
  subsecciones <- list(
    "Composición"    = salida_composicion(ns),
    "Desempeño"      = salida_desempeno(ns),
    "Diagnóstico"    = salida_diagnostico(ns),
    "Explicabilidad" = salida_explicabilidad(ns),
    "Comparación"    = panel_pendiente("Comparación", "Hito 6",
                                       DETALLE_COMPARACION))
  subsecciones[[ETIQUETA_ANALISIS]] <- salida_analisis_evaluacion(ns)

  armazon_fase(controles = .sidebar_evaluacion(ns),
               subsecciones = subsecciones,
               estado = shiny::uiOutput(ns("estado")),
               id_pestanas = ns("pestana"))
}

.sidebar_evaluacion <- function(ns) {
  visible_en <- function(pestana, contenido)
    shiny::conditionalPanel(
      sprintf("input.pestana == '%s'", pestana), ns = ns, contenido)

  shiny::tagList(
    shiny::selectInput(ns("dataset"), "Dataset", choices = character(0)),
    shiny::selectInput(ns("modelo"), "Modelo", choices = character(0)),
    shiny::selectInput(ns("receta"), "Receta", choices = character(0)),
    shiny::tags$hr(),
    visible_en("Composición", controles_composicion(ns)),
    visible_en("Desempeño", controles_desempeno(ns)),
    visible_en("Diagnóstico", controles_diagnostico(ns)),
    visible_en("Explicabilidad", controles_explicabilidad(ns)),
    visible_en(ETIQUETA_ANALISIS, controles_analisis_evaluacion(ns)),
    .controles_corrida(ns))
}

.controles_corrida <- function(ns) {
  shiny::tagList(
    shiny::tags$hr(),
    shiny::actionButton(ns("guardar"), "Guardar corrida en Objetos",
                        class = "btn-outline-primary btn-sm w-100",
                        icon = shiny::icon("save")))
}

mod_evaluacion_server <- function(id, almacen = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    corrida <- shiny::reactiveVal(NULL)

    # Las tres piezas en un solo reactivo: se eligen juntas, se validan juntas
    # y se corren juntas. La receta puede faltar y eso es un aviso, no un error.
    piezas <- shiny::reactive({
      if (is.null(almacen)) return(list(dataset = NULL, modelo = NULL,
                                        receta = NULL))
      lista <- almacen()
      tomar <- function(tipo, id)
        if (nzchar(id %||% "")) almacen_obtener(lista, tipo, id) else NULL
      list(dataset = tomar("dataset", input$dataset),
           modelo = tomar("modelo", input$modelo),
           receta = tomar("receta", input$receta))
    })

    dataset <- shiny::reactive(piezas()$dataset)
    # Qué vistas tiene sentido dibujar sale del registro, no del código de cada
    # subsección: `metodo(clave)$artefactos` es la lista de lo que este método
    # produce (SCHEMA.md §4).
    clave_metodo <- shiny::reactive({
      mo <- piezas()$modelo
      if (is.null(mo)) NULL else mo$metodo
    })

    shiny::observeEvent(almacen(), {
      for (tipo in c("dataset", "modelo", "receta"))
        .rellenar_objetos(session, almacen(), tipo, input[[tipo]])
    }, ignoreNULL = FALSE)

    # Cambiar una pieza invalida el resultado: dejar en pantalla la corrida
    # anterior junto a los selectores nuevos sería mostrar un resultado que no
    # corresponde a lo que se está mirando.
    shiny::observeEvent(
      list(input$dataset, input$modelo, input$receta),
      corrida(NULL), ignoreInit = TRUE)

    shiny::observeEvent(corrida(), {
      actualizar_explicabilidad(session, corrida(), dataset(),
                                shiny::isolate(shiny::reactiveValuesToList(input)))
    })

    output$estado <- shiny::renderUI(.franja_corrida(corrida(), piezas()))

    # Las banderas que gobiernan qué cards se ven se publican una sola vez para
    # toda la fase: dos subsecciones comparten claves (el scree lo miran
    # Desempeño y Diagnóstico) y asignar el mismo output dos veces lo
    # reemplazaría en silencio.
    declarar_artefactos(output, CLAVES_EVALUACION, clave_metodo)

    servidor_composicion(input, output, session, piezas, corrida)
    servidor_desempeno(input, output, session, corrida)
    servidor_diagnostico(input, output, session, corrida)
    servidor_explicabilidad(input, output, session, corrida, dataset)
    servidor_analisis_evaluacion(input, output, session, piezas, corrida)

    shiny::observeEvent(input$guardar, {
      c <- corrida()
      if (is.null(c)) {
        shiny::showNotification("Todavía no hay corrida que guardar.",
                                type = "warning", duration = 5)
        return(invisible(NULL))
      }
      guardado <- almacen_agregar(almacen(), c)
      almacen(guardado)
      corrida(almacen_obtener(guardado, "corrida", attr(guardado, "id_nuevo")))
      shiny::showNotification(
        sprintf("Corrida guardada como %s", attr(guardado, "id_nuevo")),
        type = "message", duration = 3)
    })
  })
}

.franja_corrida <- function(corrida, piezas) {
  if (is.null(corrida)) {
    faltan <- names(Filter(is.null, piezas))
    return(franja_estado(list(
      "corrida" = "sin correr",
      "faltan" = if (length(faltan)) paste(faltan, collapse = ", ") else "nada")))
  }
  m <- corrida$metricas
  franja_estado(c(
    list("corrida" = corrida$id %||% "sin guardar",
         "composicion" = sprintf("%s x %s", corrida$dataset_id,
                                 corrida$modelo_id),
         "n" = m$n, "p" = m$p),
    resumen_ajuste(corrida$ajuste),
    list("duracion" = sprintf("%.2f s", corrida$duracion))))
}
