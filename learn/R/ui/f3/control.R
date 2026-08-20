# learn/R/ui/f3/control.R
#
# Responsabilidad: subsección Control — cuándo se detiene el optimizador.
#
# Tres perillas y una semilla. Ninguna cambia el problema; todas cambian la
# respuesta que se obtiene, y esa distinción es el contenido de esta pantalla.
#
# La tolerancia va en escala log10 porque su rango útil son órdenes de
# magnitud: un slider lineal de 1e-10 a 1e-2 pasaría el 99 % del recorrido en
# valores que nadie usa.

controles_control <- function(ns) {
  shiny::tagList(
    shiny::sliderInput(ns("maxit"), "Máximo de iteraciones",
                       min = 1, max = 1000, value = 500, step = 1),
    shiny::sliderInput(ns("tol_log"), "Tolerancia (10^x)",
                       min = -12, max = -2, value = -8, step = 1),
    shiny::numericInput(ns("semilla"), "Semilla", value = 42, min = 1),
    shiny::checkboxInput(ns("registrar_traza"), "Registrar la traza", TRUE),
    shiny::tags$p(class = "text-muted small mb-0",
                  paste("Sin traza el ajuste es igual de válido y no se puede",
                        "mirar por dentro.")))
}

#' La tolerancia real a partir del slider. Existe como función para que el
#' server, el bloque de contexto y la receta guardada usen exactamente la misma
#' conversión: dos sitios haciendo 10^x por su cuenta es una divergencia
#' esperando su turno.
tolerancia_de <- function(input) 10^(input$tol_log %||% -8)

salida_control <- function(ns) {
  bslib::card(
    bslib::card_header("Qué hace cada perilla"),
    bslib::card_body(
      shiny::uiOutput(ns("resumen_control")),
      shiny::tags$dl(
        class = "row mb-0 mt-3",
        shiny::tags$dt(class = "col-sm-3", "Máximo de iteraciones"),
        shiny::tags$dd(class = "col-sm-9",
          paste("El techo. Si el ajuste lo alcanza, el resultado quedó a medio",
                "camino y la traza lo muestra cortada todavía bajando.")),
        shiny::tags$dt(class = "col-sm-3", "Tolerancia"),
        shiny::tags$dd(class = "col-sm-9",
          paste("Cuánto tiene que dejar de moverse el vector para dar por",
                "terminado. Más estricta cuesta iteraciones y no siempre",
                "cambia el resultado en las cifras que te importan.")),
        shiny::tags$dt(class = "col-sm-3", "Semilla"),
        shiny::tags$dd(class = "col-sm-9",
          paste("Fija el vector inicial. Cambia el camino; en un problema bien",
                "condicionado no cambia el destino. Que eso sea así es",
                "comprobable: cambiala y mirá la traza.")))))
}

servidor_control <- function(input, output, session) {
  output$resumen_control <- shiny::renderUI({
    franja_estado(list(
      "maximo" = input$maxit %||% 500,
      "tolerancia" = format(tolerancia_de(input), scientific = TRUE),
      "semilla" = input$semilla %||% 42,
      "traza" = if (isTRUE(input$registrar_traza)) "se registra" else "no"))
  })
  invisible(TRUE)
}
