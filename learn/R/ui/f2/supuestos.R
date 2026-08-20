# learn/R/ui/f2/supuestos.R
#
# Responsabilidad: subsección Supuestos — qué exige el método, evaluado sobre
# este dataset antes de ajustar.
#
# No hay una línea de checklist escrita a mano: la lista sale de
# `metodo(clave)$supuestos` y cada fila la evalúa `evaluar_supuestos()`. Añadir
# un supuesto a un método es añadir una cadena al registro, no una vista.
#
# Los avisos tienen la misma forma que los de contratos.R, así que los pinta
# `lista_avisos()` sin código nuevo.

controles_supuestos <- function(ns) {
  shiny::tagList(
    shiny::checkboxInput(ns("solo_problemas"), "Ver solo lo que falla", FALSE),
    shiny::tags$p(class = "text-muted small mb-0",
                  paste("Los supuestos se evalúan sobre el dataset y las",
                        "columnas elegidas en Especificación.")))
}

salida_supuestos <- function(ns) {
  panel_resultado(
    "f2.supuestos.semaforo",
    shiny::tagList(
      shiny::uiOutput(ns("semaforo")),
      shiny::uiOutput(ns("veredicto_supuestos"))),
    contexto = salida_contexto(ns, "contexto_supuestos"))
}

servidor_supuestos <- function(input, output, session, dataset, clave_metodo,
                               columnas) {
  avisos <- shiny::reactive({
    ds <- dataset()
    if (is.null(ds) || !nzchar(clave_metodo() %||% "")) return(list())
    tryCatch(evaluar_supuestos(clave_metodo(), ds, columnas()),
             error = function(e) list(list(severidad = "error", clave = "fallo",
                                           mensaje = conditionMessage(e),
                                           sugerencia = NA_character_)))
  })

  output$semaforo <- shiny::renderUI({
    ds <- dataset()
    shiny::validate(shiny::need(!is.null(ds),
                                "Elegí un dataset guardado en Objetos."))
    todos <- avisos()
    shiny::validate(shiny::need(
      length(todos),
      "Este método no declara supuestos comprobables todavía."))
    mostrados <- if (isTRUE(input$solo_problemas))
      Filter(function(a) a$severidad != "ok", todos) else todos
    if (!length(mostrados))
      return(shiny::tags$p(class = "text-muted",
                           "Ningún supuesto da problema con estos datos."))
    lista_avisos(mostrados)
  })

  # El veredicto va aparte del semáforo: es la única línea que cambia de verdad
  # al mover los controles, y por eso no se pliega (C5).
  output$veredicto_supuestos <- shiny::renderUI({
    todos <- avisos()
    if (!length(todos)) return(NULL)
    niveles <- vapply(todos, `[[`, "", "severidad")
    franja_estado(list(
      "supuestos" = length(todos),
      "se cumplen" = sum(niveles == "ok"),
      "con aviso" = sum(niveles == "aviso"),
      "impiden ajustar" = sum(niveles == "error")))
  })

  dibujar_contexto(output, "f2.supuestos.semaforo",
                   params = shiny::reactive({
                     if (!length(avisos())) return(NULL)
                     stats::setNames(
                       lapply(avisos(), `[[`, "severidad"),
                       vapply(avisos(), `[[`, "", "clave"))
                   }),
                   sufijo = "contexto_supuestos")
  invisible(TRUE)
}
