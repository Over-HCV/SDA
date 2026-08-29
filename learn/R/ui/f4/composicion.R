# learn/R/ui/f4/composicion.R
#
# Responsabilidad: subsección Composición — elegir los tres objetos, validar
# que se pueden juntar y correr.
#
# Es el corazón del diseño: Dataset x Modelo x Receta -> Corrida. Los tres se
# eligen por separado porque se producen por separado, y eso es lo que permite
# reusar un dataset viejo con un modelo nuevo sin rehacer la fase 1.
#
# La compatibilidad se valida ANTES de correr con validar_compatibilidad(), que
# nunca lanza: un error de composición es información para el usuario, no una
# excepción.

controles_composicion <- function(ns) {
  shiny::tagList(
    shiny::actionButton(ns("correr"), "Correr", class = "btn-primary w-100",
                        icon = shiny::icon("play")),
    shiny::tags$p(class = "text-muted small mt-2 mb-0",
                  paste("Sin receta se usa el control por defecto del método,",
                        "y la composición lo avisa.")))
}

salida_composicion <- function(ns) {
  bslib::card(
    bslib::card_header("Dataset × Modelo × Receta"),
    bslib::card_body(
      shiny::uiOutput(ns("resumen_piezas")),
      shiny::tags$h6(class = "mt-3", "Compatibilidad"),
      shiny::uiOutput(ns("compatibilidad"))))
}

servidor_composicion <- function(input, output, session, piezas, corrida) {
  avisos <- shiny::reactive({
    p <- piezas()
    validar_compatibilidad(p$dataset, p$modelo, p$receta)
  })

  output$resumen_piezas <- shiny::renderUI({
    p <- piezas()
    shiny::tagList(
      .tarjeta_pieza("Dataset", p$dataset,
                     "Guardalo en la fase 1 con 'Guardar en Objetos'."),
      .tarjeta_pieza("Modelo", p$modelo,
                     "Definilo en la fase 2 y guardalo."),
      .tarjeta_pieza("Receta", p$receta,
                     "Opcional: la fase 3 la guarda cuando ajustás."))
  })

  output$compatibilidad <- shiny::renderUI(lista_avisos(avisos()))

  shiny::observeEvent(input$correr, {
    p <- piezas()
    if (!componible(avisos())) {
      shiny::showNotification(
        "La composición tiene errores: miralos arriba antes de correr.",
        type = "error", duration = 6)
      return(invisible(NULL))
    }
    shiny::withProgress(message = "Corriendo", value = 0.3, {
      resultado <- tryCatch(.correr_composicion(p), error = conditionMessage)
      shiny::setProgress(0.9)
      if (is.character(resultado)) {
        corrida(NULL)
        shiny::showNotification(paste("No se pudo correr:", resultado),
                                type = "error", duration = 8)
      } else {
        corrida(resultado)
        shiny::showNotification("Corrida lista.", type = "message",
                                duration = 3)
      }
    })
  })
  invisible(TRUE)
}

# Arma la Corrida completa. El `params` que se guarda es el mismo bloque que
# escribe run_headless.R: si divergen, el JSON de la app y el del batch dejan de
# ser comparables y la trazabilidad se rompe en silencio (C11).
.correr_composicion <- function(p) {
  m <- metodo(p$modelo$metodo)
  control <- p$receta$control %||% list(tol = 1e-8, maxit = 500L)
  semilla <- p$receta$semilla %||% p$dataset$semilla %||% 42L
  optimizador <- if (is.null(p$receta) || is.na(p$receta$optimizador))
    (m$optimizador$metodos %||% NA_character_)[1] else p$receta$optimizador

  inicio <- Sys.time()
  ajuste <- do.call(m$ajustar, c(
    list(datos = p$dataset$df, columnas = p$modelo$spec),
    p$modelo$hiper,
    list(optimizador = optimizador, tol = control$tol %||% 1e-8,
         maxit = control$maxit %||% 500L, semilla = semilla)))

  nueva_corrida(
    NULL, p$dataset$id, p$modelo$id,
    if (is.null(p$receta)) NA_character_ else p$receta$id,
    p$modelo$metodo, ajuste = ajuste, traza = ajuste$traza,
    metricas = metricas_de_corrida(ajuste),
    params = c(p$modelo$hiper,
               list(optimizador = optimizador, tol = control$tol,
                    maxit = control$maxit, semilla = semilla,
                    columnas = paste(p$modelo$spec %||%
                                       columnas_numericas(p$dataset),
                                     collapse = ","))),
    duracion = as.numeric(difftime(Sys.time(), inicio, units = "secs")),
    estado = "listo")
}

.tarjeta_pieza <- function(titulo, objeto, ayuda) {
  cuerpo <- if (is.null(objeto))
    shiny::tags$span(class = "text-muted", ayuda)
  else shiny::tagList(shiny::tags$strong(objeto$id), " · ",
                      resumen_objeto(objeto))
  shiny::tags$div(
    class = "d-flex gap-3 align-items-baseline border-bottom py-2",
    shiny::tags$span(class = "text-muted small", style = "min-width: 5rem;",
                     titulo),
    shiny::tags$span(class = "small", cuerpo))
}
