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
    # Los métodos iterativos que arrancan de un punto (k-medias) tienen una
    # perilla más que los que arrancan de la matriz entera (ACP). El control
    # existe siempre y se muestra según el registro: reconstruirlo con
    # renderUI le costaría el binding (AGENT.md).
    shiny::conditionalPanel(
      condition = "output.hay_inicializacion", ns = ns,
      shiny::radioButtons(ns("inicializacion"), "Inicialización",
                          choices = c("por defecto" = ""))),
    shiny::uiOutput(ns("nota_optimizador")))
}

actualizar_optimizador <- function(session, clave, previos = list()) {
  m <- metodo(clave)
  arranques <- m$optimizador$inicializaciones %||% character(0)
  if (length(arranques)) {
    previo_arranque <- previos$inicializacion
    shiny::updateRadioButtons(
      session, "inicializacion", choices = arranques,
      selected = if (!is.null(previo_arranque) && previo_arranque %in% arranques)
                   previo_arranque else arranques[1])
  }
  disponibles <- m$optimizador$metodos %||% character(0)
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
    "No hay nada que mirar mientras corre: termina o falla."),
  Lloyd = c(
    "Colocar k centroides segun la inicializacion elegida.",
    "Asignar cada observacion al centroide mas cercano.",
    "Recalcular cada centroide como el promedio de los suyos.",
    "Repetir: los dos pasos bajan la inercia por separado.",
    "Parar cuando nadie cambia de grupo o la inercia deja de bajar."),
  MacQueen = c(
    "Colocar k centroides segun la inicializacion elegida.",
    "Recorrer las observaciones de a una, en orden.",
    "Mover la observacion al centroide mas cercano y recentrar en el acto.",
    "Converge en menos barridos, y depende del orden de las filas.",
    "Parar cuando un barrido completo no mueve a nadie."))

servidor_optimizador <- function(input, output, session, clave_metodo) {
  output$hay_inicializacion <- shiny::reactive({
    m <- tryCatch(metodo(clave_metodo()), error = function(e) NULL)
    !is.null(m) && length(m$optimizador$inicializaciones %||% character(0)) > 0
  })
  shiny::outputOptions(output, "hay_inicializacion", suspendWhenHidden = FALSE)

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
      sugerencia = paste("Si el método ofrece un algoritmo iterativo, elegilo",
                         "para ver el mismo resultado construyéndose: las",
                         "pruebas del método comprueban que coinciden."))))
  })
  invisible(TRUE)
}
