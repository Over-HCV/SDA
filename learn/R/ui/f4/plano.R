# learn/R/ui/f4/plano.R
#
# Responsabilidad: el contexto compartido por las cards que viven en un plano
# factorial.
#
# El par de ejes, el color, las filas que de verdad entraron al ajuste y el
# bloque ⓘ los necesitan por igual el mapa, el biplot, las cargas, el círculo,
# la contribución y la calidad. Calcularlos una vez y pasarlos es lo que permite
# partir esas cards en dos archivos sin que una mitad recalcule —y algún día
# recalcule distinto— lo que la otra ya sabe.
#
# Devuelve reactivos, no valores: quien lo recibe decide cuándo mirarlos.

#' El contexto de un plano factorial, como lista de reactivos.
#'
#' @return list(ajuste, corrida, ejes, etiquetas, grupo, nombre_color,
#'   suplementaria, exigir_ejes, parametros, metricas)
contexto_plano <- function(input, output, session, corrida, dataset) {
  ajuste <- shiny::reactive({
    c <- corrida()
    shiny::validate(shiny::need(
      !is.null(c), "Corré una composición en Composición para ver el modelo."))
    c$ajuste
  })

  ejes <- shiny::reactive({
    c(as.integer(input$eje_x %||% "1"), as.integer(input$eje_y %||% "2"))
  })

  etiquetas <- shiny::reactive({
    nombres <- etiquetas_ejes(ajuste())
    nombres[pmin(ejes(), length(nombres))]
  })

  # El color se recorta a las filas que de verdad entraron al ajuste: las que
  # tenían un faltante se descartaron y desalinear el vector pintaría cada
  # punto del grupo equivocado, sin fallar.
  grupo <- shiny::reactive({
    ds <- tryCatch(dataset(), error = function(e) NULL)
    columna <- input$color %||% ""
    if (is.null(ds) || !nzchar(columna)) return(NULL)
    a <- ajuste()
    completas <- stats::complete.cases(ds$df[, a$columnas, drop = FALSE])
    ds$df[[columna]][completas]
  })

  nombre_color <- shiny::reactive({
    columna <- input$color %||% ""
    if (nzchar(columna)) columna else NULL
  })

  # Una variable suplementaria se correlaciona con las puntuaciones que YA
  # existen, así que hay que recortarla a las mismas filas del ajuste, igual que
  # el color. Si no encaja, se avisa y el círculo se dibuja sin ella.
  suplementaria <- shiny::reactive({
    ds <- tryCatch(dataset(), error = function(e) NULL)
    columna <- input$variable_sup %||% ""
    if (is.null(ds) || !nzchar(columna)) return(NULL)
    a <- ajuste()
    completas <- stats::complete.cases(ds$df[, a$columnas, drop = FALSE])
    .o_aviso(proyectar_variable(a, ds$df[[columna]][completas], columna, ejes()))
  })

  exigir_ejes <- function() {
    shiny::validate(shiny::need(
      ejes()[1] != ejes()[2],
      "Elegí dos componentes distintas: una contra sí misma es una diagonal."))
  }

  parametros <- shiny::reactive({
    c <- corrida()
    if (is.null(c)) return(NULL)
    c(c$params,
      list(ejes = paste(etiquetas(), collapse = " x "),
           color = nombre_color() %||% "sin color",
           suplementarios = if (nzchar(input$suplementario %||% ""))
             input$suplementario else "ninguno",
           variable_suplementaria = if (nzchar(input$variable_sup %||% ""))
             input$variable_sup else "ninguna"))
  })

  metricas <- shiny::reactive({
    c <- corrida()
    if (is.null(c)) NULL else c$metricas
  })

  list(ajuste = ajuste, corrida = shiny::reactive(corrida()), ejes = ejes,
       etiquetas = etiquetas, grupo = grupo, nombre_color = nombre_color,
       suplementaria = suplementaria, exigir_ejes = exigir_ejes,
       parametros = parametros, metricas = metricas)
}

# Proyectar algo que no encaja es un error del usuario que se puede explicar: se
# avisa con el mensaje que la lógica escribió y el gráfico se sigue dibujando sin
# el suplementario, en vez de quedarse en blanco sin decir por qué.
.o_aviso <- function(expresion) {
  tryCatch(expresion, error = function(e) {
    shiny::showNotification(conditionMessage(e), type = "warning", duration = 8)
    NULL
  })
}
