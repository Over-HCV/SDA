# learn/R/ui/f4/diagnostico.R
#
# Responsabilidad: subsección Diagnóstico — juzgar el ajuste.
#
# Qué se dibuja lo decide el registro, no este archivo: cada card aparece si el
# método de la corrida declara su clave en `artefactos`. Un scree sobre una
# partición no sería un gráfico vacío, sería un gráfico equivocado.
#
# Residuos e índices internos llegan con los métodos que los producen.

DETALLE_DIAGNOSTICO <- list(
  "Residuos y supuestos a posteriori" = paste(
    "Residuos contra ajustados, Q-Q de residuos, escala-localización, leverage",
    "y distancia de Cook. Entran con la regresión de la sesión 6."),
  "Índices internos" = paste(
    "Calinski-Harabasz contra Davies-Bouldin, junto a la silueta. Entran con",
    "la validación de grupos, en el Hito 7."))

controles_diagnostico <- function(ns) {
  shiny::tagList(
    shiny::conditionalPanel(
      condition = sprintf("output.%s",
                          bandera_artefacto("f4.diagnostico.scree")), ns = ns,
      shiny::sliderInput(ns("umbral_scree"), "Línea de referencia",
                         min = 0.5, max = 0.99, value = 0.8, step = 0.05)),
    shiny::conditionalPanel(
      condition = sprintf("output.%s",
                          bandera_artefacto("f4.diagnostico.codo")), ns = ns,
      shiny::sliderInput(ns("k_max"), "K máximo en la curva del codo",
                         min = 3, max = 15, value = 10, step = 1)),
    shiny::tags$p(class = "text-muted small mb-0",
                  paste("El codo casi nunca es evidente. La línea es una",
                        "referencia, el corte lo ponés vos en la fase 2.")))
}

salida_diagnostico <- function(ns) {
  pendientes <- lapply(names(DETALLE_DIAGNOSTICO), function(titulo)
    panel_pendiente(titulo, "Hitos 6-7", DETALLE_DIAGNOSTICO[[titulo]]))

  shiny::tagList(
    panel_si_declara(ns, "f4.diagnostico.scree",
                     shiny::plotOutput(ns("scree"), height = "360px"),
                     contexto = salida_contexto(ns, "contexto_scree")),
    panel_si_declara(ns, "f4.diagnostico.reglas_k",
                     shiny::tableOutput(ns("reglas_k")),
                     contexto = salida_contexto(ns, "contexto_reglas_k")),
    panel_si_declara(ns, "f4.diagnostico.ortogonalidad",
                     shiny::plotOutput(ns("ortogonalidad"), height = "340px"),
                     contexto = salida_contexto(ns, "contexto_ortogonalidad")),
    panel_si_declara(ns, "f4.diagnostico.codo",
                     shiny::plotOutput(ns("codo"), height = "340px"),
                     contexto = salida_contexto(ns, "contexto_codo")),
    panel_si_declara(ns, "f4.diagnostico.silueta",
                     shiny::plotOutput(ns("silueta"), height = "420px"),
                     contexto = salida_contexto(ns, "contexto_silueta")),
    panel_si_declara(ns, "f4.diagnostico.dendrograma",
                     shiny::plotOutput(ns("dendrograma"), height = "460px"),
                     contexto = salida_contexto(ns, "contexto_dendrograma")),
    panel_si_declara(ns, "f4.diagnostico.cofenetico",
                     shiny::plotOutput(ns("cofenetico"), height = "340px"),
                     contexto = salida_contexto(ns, "contexto_cofenetico")),
    plegable("Lo que falta en esta subsección", shiny::tagList(pendientes)))
}

servidor_diagnostico <- function(input, output, session, corrida) {
  ajuste <- shiny::reactive({
    c <- corrida()
    shiny::validate(shiny::need(!is.null(c),
                                "Corré una composición para ver el diagnóstico."))
    c$ajuste
  })

  umbral <- shiny::reactive(input$umbral_scree %||% 0.8)

  output$scree <- shiny::renderPlot({
    a <- ajuste()
    graficar_scree(varianza_explicada(a), k = a$k, umbral = umbral(),
                   reglas = reglas_k(a, umbral()))
  })

  # Las tres reglas como tabla y no como frase: se leen comparándolas, y el
  # número que importa cuando discrepan es cuánto discrepan.
  output$reglas_k <- shiny::renderTable(reglas_k(ajuste(), umbral()),
                                        striped = TRUE, width = "100%")

  # La identidad dibujada. Es la única card de Diagnóstico que no juzga el
  # ajuste contra un umbral: comprueba una propiedad que tiene que cumplirse, y
  # si no se cumple el problema no es de interpretación.
  output$ortogonalidad <- shiny::renderPlot(
    graficar_heatmap_correlacion(correlacion_puntuaciones(ajuste())))

  # La curva del codo reajusta el método para cada k: es cara y por eso vive en
  # su propio reactivo, que Shiny cachea hasta que cambie k_max o la corrida.
  curva_codo <- shiny::reactive(inercia_por_k(ajuste(), k_max = input$k_max %||% 10L))

  output$codo <- shiny::renderPlot(graficar_codo(curva_codo(), k = ajuste()$k))
  output$silueta <- shiny::renderPlot(graficar_silueta(silueta(ajuste())))

  # El árbol y la cofenética leen el ajuste tal cual: cambiar el corte es
  # cambiar k_corte en la fase 2, no un control de dibujo que haría que el
  # dendrograma y la silueta hablaran de particiones distintas.
  output$dendrograma <- shiny::renderPlot(
    graficar_dendrograma(arbol_jerarquico(ajuste())))
  output$cofenetico <- shiny::renderPlot(
    graficar_cofenetico(cofenetico(ajuste())))

  parametros <- shiny::reactive({
    c <- corrida()
    if (is.null(c)) return(NULL)
    c(c$params, list(umbral = input$umbral_scree, k_max = input$k_max))
  })
  metricas <- shiny::reactive({
    c <- corrida(); if (is.null(c)) NULL else c$metricas
  })
  for (par in list(c("f4.diagnostico.scree", "contexto_scree"),
                   c("f4.diagnostico.reglas_k", "contexto_reglas_k"),
                   c("f4.diagnostico.ortogonalidad", "contexto_ortogonalidad"),
                   c("f4.diagnostico.codo", "contexto_codo"),
                   c("f4.diagnostico.silueta", "contexto_silueta"),
                   c("f4.diagnostico.dendrograma", "contexto_dendrograma"),
                   c("f4.diagnostico.cofenetico", "contexto_cofenetico")))
    dibujar_contexto(output, par[1], corrida = shiny::reactive(corrida()),
                     params = parametros, metricas = metricas, sufijo = par[2])
  invisible(TRUE)
}
