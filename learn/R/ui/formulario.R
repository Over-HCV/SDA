# learn/R/ui/formulario.R
#
# Responsabilidad: convertir la especificación `hiper` del catálogo en widgets.
#
# Sin esto, cada método necesitaría su propio bloque de sliders escrito a mano,
# y la regla de las tres partes (C11) se rompería en silencio: alguien añade un
# hiperparámetro al modelo y se olvida del input. Generando el formulario desde
# la MISMA declaración que usa la función de ajuste, no puede desincronizarse.
#
# Formato de un hiperparámetro (ver R/nucleo/catalogo/):
#
#   list(tipo = "entero"|"real"|"opcion"|"logico"|"formula",
#        min =, max =, def =, paso =, opciones =, escala = "log10",
#        etiqueta = "Texto visible con tildes")

#' Un widget a partir de una declaración.
widget_hiper <- function(ns, nombre, spec) {
  etiqueta <- spec$etiqueta %||% nombre
  id <- ns(paste0("hiper_", nombre))

  switch(spec$tipo %||% "real",
    entero = shiny::sliderInput(id, etiqueta, min = spec$min, max = spec$max,
                                value = spec$def, step = spec$paso %||% 1L),
    real   = shiny::sliderInput(id, etiqueta, min = spec$min, max = spec$max,
                                value = spec$def, step = spec$paso %||% 0.01),
    opcion = shiny::selectInput(id, etiqueta, choices = spec$opciones,
                                selected = spec$def),
    logico = shiny::checkboxInput(id, etiqueta, value = isTRUE(spec$def)),
    formula = shiny::textInput(id, etiqueta, value = spec$def %||% ""),
    shiny::textInput(id, etiqueta, value = as.character(spec$def %||% ""))
  )
}

#' Nota bajo el widget cuando la escala del slider no es la del parámetro.
#'
#' λ se mueve en log₁₀ porque su efecto es multiplicativo: sin eso, el 90 % del
#' recorrido del slider no cambiaría nada visible. Decirlo evita que el usuario
#' crea que el control está roto.
nota_escala <- function(spec) {
  if (is.null(spec$escala)) return(NULL)
  shiny::tags$div(
    class = "text-muted small mt-n2 mb-3",
    sprintf("El control se mueve en %s; el valor efectivo es %s^(valor).",
            spec$escala, sub("log", "", spec$escala)))
}

#' Formulario completo de un método.
#'
#' @param clave clave del método
#' @return tagList de widgets, o un aviso si el método no tiene hiperparámetros
formulario_hiper <- function(ns, clave) {
  hiper <- metodo(clave)$hiper
  if (!length(hiper))
    return(shiny::tags$p(class = "text-muted small",
                         "Este método no tiene hiperparámetros de modelo."))
  shiny::tagList(lapply(names(hiper), function(nombre) {
    shiny::tagList(widget_hiper(ns, nombre, hiper[[nombre]]),
                   nota_escala(hiper[[nombre]]))
  }))
}

#' Lee los valores del formulario y los devuelve como la lista `hiper` que
#' espera la función de ajuste. Aplica la escala declarada.
valores_hiper <- function(input, clave) {
  hiper <- metodo(clave)$hiper
  if (!length(hiper)) return(list())
  valores <- lapply(names(hiper), function(nombre) {
    crudo <- input[[paste0("hiper_", nombre)]]
    spec <- hiper[[nombre]]
    if (is.null(crudo)) return(spec$def)
    if (identical(spec$escala, "log10")) 10^crudo else crudo
  })
  stats::setNames(valores, names(hiper))
}

#' Valores por defecto sin pasar por la UI. Lo usa run_headless.R para que el
#' batch arranque exactamente igual que la app (C11).
hiper_por_defecto <- function(clave) {
  hiper <- metodo(clave)$hiper
  if (!length(hiper)) return(list())
  valores <- lapply(hiper, function(spec) {
    if (identical(spec$escala, "log10")) 10^spec$def else spec$def
  })
  stats::setNames(valores, names(hiper))
}

#' Formulario del optimizador (fase 3). Sale de `optimizador` del catálogo, no
#' de `hiper`: son cosas distintas y la app las separa en fases distintas.
formulario_optimizador <- function(ns, clave) {
  optimizador <- metodo(clave)$optimizador
  if (is.null(optimizador))
    return(shiny::tags$p(class = "text-muted small",
                         paste("Este método tiene solución cerrada: no hay",
                               "optimizador que configurar.")))
  shiny::tagList(
    if (length(optimizador$metodos) > 1)
      shiny::radioButtons(ns("optimizador"), "Algoritmo",
                          choices = optimizador$metodos,
                          selected = optimizador$metodos[1])
    else
      shiny::tags$p(class = "small", shiny::tags$strong("Algoritmo: "),
                    optimizador$metodos[1]),
    if (!is.null(optimizador$inicializaciones))
      shiny::radioButtons(ns("inicializacion"), "Inicialización",
                          choices = optimizador$inicializaciones,
                          selected = optimizador$inicializaciones[1]),
    shiny::sliderInput(ns("maxit"), "Máximo de iteraciones",
                       min = 10, max = 500, value = 100, step = 10),
    shiny::numericInput(ns("tolerancia"), "Tolerancia", value = 1e-4,
                        min = 1e-12, max = 1, step = 1e-5),
    shiny::numericInput(ns("semilla"), "Semilla", value = 42, min = 1, step = 1),
    if (isTRUE(optimizador$traza))
      shiny::checkboxInput(ns("registrar_traza"), "Registrar la traza", TRUE)
  )
}
