# learn/R/ui/f3/consola.R
#
# Responsabilidad: subsección Consola — ajustar y mirar cómo se ajustó.
#
# El modo paso a paso REPRODUCE la traza ya registrada, no vuelve a calcular. Es
# una decisión, no un atajo: recalcular una iteración por clic cruzaría la
# frontera R-navegador en cada paso y en wasm eso es insufrible, además de que
# el resultado dibujado podría no ser el mismo que el de la corrida guardada.
# Reproducir garantiza que lo que se ve es exactamente lo que pasó.
#
# Por eso ■ detiene la reproducción, no el ajuste: el ajuste es síncrono y
# termina en milisegundos. Un botón de "detener el ajuste" que no detiene nada
# sería un adorno mentiroso.

controles_consola <- function(ns) {
  shiny::tagList(
    shiny::actionButton(ns("ajustar"), "Ajustar", class = "btn-primary w-100",
                        icon = shiny::icon("play")),
    shiny::tags$hr(),
    shiny::tags$p(class = "small text-muted mb-1", "Reproducción de la traza"),
    shiny::div(
      class = "d-flex gap-2",
      shiny::actionButton(ns("paso_atras"), "-1", class = "btn-sm btn-outline-secondary w-100"),
      shiny::actionButton(ns("paso_adelante"), "+1", class = "btn-sm btn-outline-secondary w-100")),
    shiny::checkboxInput(ns("reproducir"), "Reproducir sola", FALSE),
    shiny::sliderInput(ns("velocidad"), "Iteraciones por segundo",
                       min = 1, max = 20, value = 6, step = 1),
    shiny::sliderInput(ns("paso"), "Iteración", min = 1, max = 1, value = 1,
                       step = 1))
}

salida_consola <- function(ns) {
  shiny::tagList(
    bslib::card(
      bslib::card_header("Consola"),
      bslib::card_body(
        shiny::uiOutput(ns("progreso")),
        shiny::verbatimTextOutput(ns("registro")))),
    # Solo para los métodos cuyo estado se puede dibujar en el plano. En
    # k-medias es donde se ven los centroides caminar; el ACP no lo declara
    # porque su estado es una dirección, no una partición.
    shiny::conditionalPanel(
      condition = "output.hay_estado_paso", ns = ns,
      panel_resultado(
        "f3.consola.estado",
        shiny::plotOutput(ns("estado_paso"), height = "340px"),
        contexto = salida_contexto(ns, "contexto_estado"))),
    panel_resultado(
      "f3.analisis.trayectoria",
      shiny::plotOutput(ns("trayectoria_paso"), height = "320px"),
      contexto = salida_contexto(ns, "contexto_trayectoria")))
}

#' @param ajuste  reactiveVal donde queda el resultado del ajuste
#' @param paso    reactiveVal con la iteración que se está reproduciendo
servidor_consola <- function(input, output, session, ajuste, paso) {
  output$hay_estado_paso <- shiny::reactive({
    a <- ajuste()
    !is.null(a) && !is.null(a$asignaciones_por_iter)
  })
  shiny::outputOptions(output, "hay_estado_paso", suspendWhenHidden = FALSE)

  tabla_primera <- shiny::reactive({
    a <- ajuste()
    shiny::req(a, !is.null(a$traza))
    tabla <- parametros_a_tabla(a$traza)
    tabla[tabla$componente == 1L, , drop = FALSE]
  })

  iteraciones_totales <- shiny::reactive({
    tabla <- tryCatch(tabla_primera(), error = function(e) NULL)
    if (is.null(tabla) || !nrow(tabla)) return(0L)
    max(tabla$iter)
  })

  # Al terminar un ajuste el slider se reajusta al número real de iteraciones y
  # la reproducción vuelve al principio.
  shiny::observeEvent(ajuste(), {
    total <- max(1L, iteraciones_totales())
    paso(1L)
    shiny::updateSliderInput(session, "paso", min = 1, max = total, value = 1)
    shiny::updateCheckboxInput(session, "reproducir", value = FALSE)
  })

  shiny::observeEvent(input$paso, paso(input$paso))
  shiny::observeEvent(input$paso_adelante,
                      .mover_paso(session, paso, 1L, iteraciones_totales()))
  shiny::observeEvent(input$paso_atras,
                      .mover_paso(session, paso, -1L, iteraciones_totales()))

  # invalidateLater es reactividad de Shiny, no JavaScript propio (C10).
  shiny::observe({
    shiny::req(isTRUE(input$reproducir), iteraciones_totales() > 0L)
    if (shiny::isolate(paso()) >= iteraciones_totales()) {
      shiny::updateCheckboxInput(session, "reproducir", value = FALSE)
      return(invisible(NULL))
    }
    shiny::invalidateLater(round(1000 / (input$velocidad %||% 6)))
    .mover_paso(session, paso, 1L, iteraciones_totales())
  })

  output$progreso <- shiny::renderUI({
    a <- ajuste()
    if (is.null(a))
      return(shiny::tags$p(class = "text-muted mb-0",
                           "Pulsá Ajustar para estimar el modelo."))
    total <- iteraciones_totales()
    shiny::tagList(
      barra_progreso(min(paso(), max(total, 1L)), max(total, 1L),
                     etiqueta = "reproduccion"),
      franja_estado(c(
        list("estado" = if (isTRUE(a$convergio)) "convergio"
                        else "agoto iteraciones",
             "iteraciones" = a$iteraciones),
        resumen_ajuste(a))))
  })

  output$registro <- shiny::renderText({
    a <- ajuste()
    shiny::validate(shiny::need(!is.null(a), "sin ajuste todavia"))
    .lineas_registro(a, paso())
  })

  # Reproducir, no recalcular: la columna de asignaciones de esa iteración ya
  # está en el ajuste. Recalcular por clic cruzaría la frontera R-navegador en
  # cada paso, y en wasm eso es insufrible (ver la cabecera de este archivo).
  output$estado_paso <- shiny::renderPlot({
    a <- ajuste()
    shiny::validate(shiny::need(!is.null(a$asignaciones_por_iter),
                                "Este ajuste no registro su estado por iteracion."))
    columna <- min(paso() + 1L, ncol(a$asignaciones_por_iter))
    graficar_mapa_2d(coordenadas_2d(a, grupo = a$asignaciones_por_iter[, columna]),
                     ejes = etiquetas_ejes(a))
  })

  dibujar_contexto(output, "f3.consola.estado",
                   params = shiny::reactive({
                     a <- ajuste()
                     if (is.null(a)) return(NULL)
                     list(iteracion_mostrada = paso(),
                          iteraciones_totales = iteraciones_totales(),
                          semilla = a$semilla)
                   }),
                   sufijo = "contexto_estado")

  output$trayectoria_paso <- shiny::renderPlot({
    a <- ajuste()
    shiny::validate(shiny::need(!is.null(a), "Pulsá Ajustar para ver la traza."))
    shiny::validate(shiny::need(
      !is.null(a$traza),
      "Este optimizador resuelve en un paso: no hay trayectoria que reproducir."))
    tabla <- tabla_primera()
    graficar_trayectoria(tabla[tabla$iter <= paso(), , drop = FALSE],
                         componente = 1L)
  })

  dibujar_contexto(output, "f3.analisis.trayectoria",
                   params = shiny::reactive({
                     a <- ajuste()
                     if (is.null(a)) return(NULL)
                     list(optimizador = a$optimizador, semilla = a$semilla,
                          tolerancia = a$tol, maxit = a$maxit,
                          iteracion_mostrada = paso(),
                          iteraciones_totales = iteraciones_totales())
                   }),
                   sufijo = "contexto_trayectoria")
  invisible(TRUE)
}

.mover_paso <- function(session, paso, delta, total) {
  if (total < 1L) return(invisible(NULL))
  nuevo <- min(max(1L, paso() + delta), total)
  paso(nuevo)
  shiny::updateSliderInput(session, "paso", value = nuevo)
}

# El log de la consola: las últimas iteraciones hasta la que se reproduce, con
# el delta que decide la parada. Es texto y no una tabla a propósito: se
# copia y se pega en una conversación.
.lineas_registro <- function(ajuste, paso, ventana = 8L) {
  if (is.null(ajuste$traza))
    return(paste("optimizador svd: sin iteraciones.",
                 "\nresultado exacto en un paso."))
  tabla <- traza_a_tabla(ajuste$traza)
  tabla <- tabla[tabla$componente == 1L & tabla$iter <= paso, , drop = FALSE]
  if (!nrow(tabla)) return("sin iteraciones registradas")
  ultimas <- utils::tail(tabla, ventana)
  cuerpo <- sprintf("iter %3d  %s=%.6f  delta=%.3e",
                    ultimas$iter, ajuste$traza$objetivo, ultimas$objetivo,
                    ultimas$delta)
  cierre <- sprintf("tolerancia=%.1e  ->  %s", ajuste$tol,
                    if (isTRUE(ajuste$convergio)) "convergio"
                    else "se agotaron las iteraciones")
  paste(c(cuerpo, "", cierre), collapse = "\n")
}
