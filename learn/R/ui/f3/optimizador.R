# learn/R/ui/f3/optimizador.R
#
# Responsabilidad: subsección Optimizador — con qué algoritmo se estima.
#
# Los controles son estáticos y sus opciones se rellenan con update*Input desde
# `metodo(clave)$optimizador`. No se rinden con renderUI por la razón de
# siempre: un control reconstruido pierde su binding sin avisar (AGENT.md).
#
# Un método con solución cerrada no se esconde: se muestra igual, diciendo que
# no hay iteraciones que mirar y por qué. Desaparecer enseña menos que explicar.

controles_optimizador <- function(ns) {
  shiny::tagList(
    shiny::radioButtons(ns("optimizador"), "Algoritmo",
                        choices = c("sin metodo elegido" = "")),
    shiny::uiOutput(ns("nota_optimizador")))
}

actualizar_optimizador <- function(session, clave, previos = list()) {
  disponibles <- metodo(clave)$optimizador$metodos %||% character(0)
  if (!length(disponibles)) return(invisible(FALSE))
  previo <- previos$optimizador
  shiny::updateRadioButtons(
    session, "optimizador", choices = disponibles,
    selected = if (!is.null(previo) && previo %in% disponibles) previo
               else disponibles[1])
  invisible(TRUE)
}

salida_optimizador <- function(ns) {
  bslib::card(
    bslib::card_header("El algoritmo, paso a paso"),
    bslib::card_body(
      shiny::uiOutput(ns("descripcion_optimizador")),
      shiny::uiOutput(ns("comparacion_optimizadores"))))
}

# Las descripciones son de la app, no de un método: describen familias de
# algoritmos. Cuando sean muchas se mudan a textos/, como todo lo explicativo
# (C6); con dos, un archivo nuevo sería peor.
.PASOS_OPTIMIZADOR <- list(
  potencia = c(
    "Arrancar con un vector al azar, gobernado por la semilla.",
    "Multiplicarlo por S y volver a normalizarlo a norma 1.",
    "Repetir: el vector gira hacia la direccion de mayor varianza.",
    "Parar cuando el vector deja de moverse mas que la tolerancia.",
    "Deflacionar (S menos lambda v v') y volver a empezar con la siguiente."),
  svd = c(
    "Descomponer la matriz de una sola vez, sin iterar.",
    "Los valores singulares al cuadrado son los valores propios.",
    "No hay nada que mirar mientras corre: termina o falla."))

servidor_optimizador <- function(input, output, session, clave_metodo) {
  output$descripcion_optimizador <- shiny::renderUI({
    elegido <- input$optimizador
    shiny::validate(shiny::need(nzchar(elegido %||% ""),
                                "Elegí un modelo guardado en Objetos."))
    pasos <- .PASOS_OPTIMIZADOR[[elegido]]
    if (is.null(pasos))
      return(shiny::tags$p(class = "text-muted",
                           "Este algoritmo todavía no tiene descripción escrita."))
    shiny::tagList(
      shiny::tags$ol(class = "mb-0",
                     lapply(pasos, function(paso) shiny::tags$li(paso))))
  })

  output$comparacion_optimizadores <- shiny::renderUI({
    m <- tryCatch(metodo(clave_metodo()), error = function(e) NULL)
    shiny::req(m)
    sin_traza <- !isTRUE(m$optimizador$traza) ||
      identical(input$optimizador, "svd")
    if (!sin_traza)
      return(shiny::tags$p(
        class = "text-muted small mt-3 mb-0",
        paste("Este algoritmo deja traza: la fase la dibuja en ▣ Análisis y",
              "podés reproducirla iteración por iteración en la Consola.")))
    lista_avisos(list(list(
      severidad = "aviso", clave = "sin_traza",
      mensaje = paste("Este algoritmo resuelve en un paso: no hay iteraciones",
                      "que mirar, así que la traza de convergencia va a estar",
                      "vacía."),
      sugerencia = paste("Elegí 'potencia' para ver el mismo resultado",
                         "construyéndose. Los dos coinciden hasta el signo, y",
                         "eso lo comprueba test_acp.R."))))
  })
  invisible(TRUE)
}
