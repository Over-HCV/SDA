# learn/R/ui/f3/ajuste.R
#
# Responsabilidad: cablear la fase 3. No calcula ni dibuja nada por su cuenta.
#
# Lo que esta fase produce es una Receta: optimizador + control + semilla. El
# ajuste que se ejecuta acá es para MIRARLO — la corrida oficial, con sus
# métricas y su JSON, se compone en la fase 4. Se puede guardar igual desde
# acá, porque el usuario que acaba de ver converger su modelo no debería tener
# que repetirlo en otra pantalla.
#
# Mismo contrato de cuatro funciones por subsección que f1/datos.R y f2.

SUBSECCIONES_AJUSTE <- c("Optimizador", "Control", "Consola", ETIQUETA_ANALISIS)

mod_ajuste_ui <- function(id) {
  ns <- shiny::NS(id)
  subsecciones <- list(
    "Optimizador" = salida_optimizador(ns),
    "Control"     = salida_control(ns),
    "Consola"     = salida_consola(ns))
  subsecciones[[ETIQUETA_ANALISIS]] <- salida_analisis_ajuste(ns)

  armazon_fase(controles = .sidebar_ajuste(ns),
               subsecciones = subsecciones,
               estado = shiny::uiOutput(ns("estado")),
               id_pestanas = ns("pestana"))
}

.sidebar_ajuste <- function(ns) {
  visible_en <- function(pestana, contenido)
    shiny::conditionalPanel(
      sprintf("input.pestana == '%s'", pestana), ns = ns, contenido)

  shiny::tagList(
    shiny::selectInput(ns("dataset"), "Dataset", choices = character(0)),
    shiny::selectInput(ns("modelo"), "Modelo", choices = character(0)),
    shiny::tags$hr(),
    visible_en("Optimizador", controles_optimizador(ns)),
    visible_en("Control", controles_control(ns)),
    visible_en("Consola", controles_consola(ns)),
    visible_en(ETIQUETA_ANALISIS, controles_analisis_ajuste(ns)),
    .controles_receta(ns))
}

.controles_receta <- function(ns) {
  shiny::tagList(
    shiny::tags$hr(),
    shiny::actionButton(ns("guardar_receta"), "Guardar receta",
                        class = "btn-outline-primary btn-sm w-100",
                        icon = shiny::icon("save")),
    shiny::actionButton(ns("guardar_corrida"), "Guardar corrida",
                        class = "btn-outline-secondary btn-sm w-100 mt-2",
                        icon = shiny::icon("box-archive")),
    shiny::tags$p(class = "text-muted small mt-2 mb-0",
                  "La receta es reutilizable; la corrida es este resultado."))
}

mod_ajuste_server <- function(id, almacen = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    ajuste <- shiny::reactiveVal(NULL)
    paso <- shiny::reactiveVal(1L)

    dataset <- shiny::reactive({
      shiny::req(!is.null(almacen), nzchar(input$dataset %||% ""))
      almacen_obtener(almacen(), "dataset", input$dataset)
    })
    modelo <- shiny::reactive({
      shiny::req(!is.null(almacen), nzchar(input$modelo %||% ""))
      almacen_obtener(almacen(), "modelo", input$modelo)
    })
    clave_metodo <- shiny::reactive({
      m <- tryCatch(modelo(), error = function(e) NULL)
      if (is.null(m)) NULL else m$metodo
    })

    shiny::observeEvent(almacen(), {
      .rellenar_objetos(session, almacen(), "dataset", input$dataset)
      .rellenar_objetos(session, almacen(), "modelo", input$modelo)
    }, ignoreNULL = FALSE)

    shiny::observeEvent(clave_metodo(), {
      shiny::req(clave_metodo())
      actualizar_optimizador(session, clave_metodo(),
                             shiny::isolate(shiny::reactiveValuesToList(input)))
    })

    shiny::observeEvent(ajuste(), {
      actualizar_analisis_ajuste(session, ajuste(),
                                 shiny::isolate(shiny::reactiveValuesToList(input)))
    })

    # El ajuste vive acá y no dentro de la Consola porque lo consumen tres
    # subsecciones. C12: los errores se muestran, no tumban la sesión.
    shiny::observeEvent(input$ajustar, {
      ds <- tryCatch(dataset(), error = function(e) NULL)
      mo <- tryCatch(modelo(), error = function(e) NULL)
      if (is.null(ds) || is.null(mo)) {
        shiny::showNotification(
          "Elegí un dataset y un modelo guardados en Objetos.",
          type = "warning", duration = 5)
        return(invisible(NULL))
      }
      shiny::withProgress(message = "Ajustando", value = 0.3, {
        resultado <- tryCatch(.ajustar_modelo(ds, mo, input),
                              error = function(e) conditionMessage(e))
        shiny::setProgress(0.9)
        if (is.character(resultado)) {
          ajuste(NULL)
          shiny::showNotification(paste("No se pudo ajustar:", resultado),
                                  type = "error", duration = 8)
        } else {
          ajuste(resultado)
        }
      })
    })

    output$estado <- shiny::renderUI(.franja_ajuste(ajuste(), input))

    servidor_optimizador(input, output, session, clave_metodo)
    servidor_control(input, output, session)
    servidor_consola(input, output, session, ajuste, paso)
    servidor_analisis_ajuste(input, output, session, ajuste)

    shiny::observeEvent(input$guardar_receta, {
      shiny::req(!is.null(almacen))
      guardado <- almacen_agregar(almacen(), .receta_de(input))
      almacen(guardado)
      shiny::showNotification(
        sprintf("Receta guardada como %s", attr(guardado, "id_nuevo")),
        type = "message", duration = 3)
    })

    shiny::observeEvent(input$guardar_corrida, {
      a <- ajuste()
      if (is.null(a)) {
        shiny::showNotification("Ajustá primero: no hay corrida que guardar.",
                                type = "warning", duration = 5)
        return(invisible(NULL))
      }
      con_receta <- almacen_agregar(almacen(), .receta_de(input))
      id_receta <- attr(con_receta, "id_nuevo")
      corrida <- nueva_corrida(
        NULL, dataset()$id, modelo()$id, id_receta, modelo()$metodo,
        ajuste = a, traza = a$traza, metricas = metricas_de_corrida(a),
        params = c(modelo()$hiper, list(optimizador = a$optimizador,
                                        tol = a$tol, maxit = a$maxit,
                                        semilla = a$semilla)),
        estado = "listo")
      guardado <- almacen_agregar(con_receta, corrida)
      almacen(guardado)
      shiny::showNotification(
        sprintf("Corrida guardada como %s", attr(guardado, "id_nuevo")),
        type = "message", duration = 3)
    })
  })
}

# ---------------------------------------------------------------------------
# Piezas
# ---------------------------------------------------------------------------

# Los hiperparámetros salen del Modelo guardado y el control de esta fase. Que
# el ajuste se arme igual acá, en run_headless.R y en la fase 4 es la regla de
# las tres partes funcionando (C11).
.ajustar_modelo <- function(ds, mo, input) {
  do.call(metodo(mo$metodo)$ajustar, c(
    list(datos = ds$df, columnas = mo$spec),
    mo$hiper,
    list(optimizador = input$optimizador %||% "potencia",
         tol = tolerancia_de(input), maxit = input$maxit %||% 500L,
         semilla = input$semilla %||% 42L,
         registrar_traza = isTRUE(input$registrar_traza))))
}

.receta_de <- function(input) {
  nueva_receta(
    NULL, sprintf("%s tol %.0e", input$optimizador %||% "potencia",
                  tolerancia_de(input)),
    optimizador = input$optimizador %||% NA_character_,
    control = list(tol = tolerancia_de(input), maxit = input$maxit %||% 500L),
    semilla = input$semilla %||% 42L)
}

.rellenar_objetos <- function(session, almacen, tipo, previo) {
  ids <- almacen_ids(almacen, tipo)
  etiquetas <- vapply(ids, function(id)
    sprintf("%s · %s", id, almacen_obtener(almacen, tipo, id)$nombre), "")
  .rellenar_selector(session, tipo, stats::setNames(ids, etiquetas), previo)
}

.franja_ajuste <- function(ajuste, input) {
  if (is.null(ajuste))
    return(franja_estado(list("ajuste" = "sin correr",
                              "optimizador" = input$optimizador %||% "-")))
  franja_estado(list(
    "optimizador" = ajuste$optimizador,
    "estado" = if (isTRUE(ajuste$convergio)) "convergio" else "agoto iteraciones",
    "iteraciones" = ajuste$iteraciones,
    "tolerancia" = format(ajuste$tol, scientific = TRUE),
    "semilla" = ajuste$semilla,
    "explicado" = sprintf("%.1f %%",
                          100 * sum(ajuste$varianza_explicada[seq_len(ajuste$k)]))))
}
