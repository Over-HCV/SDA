# learn/R/ui/f4/desempeno.R
#
# Responsabilidad: subsección Desempeño — los números de la corrida.
#
# Qué métricas se muestran depende de la familia del método, y la vista no lo
# decide: recorre lo que `metricas_de_corrida()` devuelve y lo pinta. Con un
# solo método esto era una lista fija de cuatro cajas con nombres del ACP;
# k-medias las habría llenado de NULL sin fallar, que es la peor manera.
#
# Las value boxes se calculan sobre el ajuste completo, nunca sobre una muestra
# de dibujo (C8).

# Cómo se muestra cada métrica conocida: etiqueta legible y formato. Lo que no
# esté acá se muestra igual, con su nombre crudo — una métrica nueva aparece
# sin tocar este archivo, solo peor rotulada.
FORMATO_METRICA <- list(
  n = list("observaciones", "entero"),
  p = list("variables", "entero"),
  k = list("componentes / grupos", "entero"),
  varianza_acumulada = list("varianza retenida", "porcentaje"),
  error_reconstruccion = list("error de reconstruccion", "decimal"),
  error_relativo = list("error relativo", "porcentaje"),
  primer_valor_propio = list("primer valor propio", "decimal"),
  inercia = list("inercia intra-grupo", "decimal"),
  proporcion_explicada = list("inercia explicada", "porcentaje"),
  silueta_media = list("silueta media", "decimal"),
  grupo_menor = list("grupo mas chico", "entero"),
  grupo_mayor = list("grupo mas grande", "entero"),
  iteraciones = list("iteraciones", "entero"))

# Métricas que son banderas, no números: informan sobre otra métrica y no
# merecen una caja propia.
METRICAS_OCULTAS <- c("silueta_muestreada", "convergio")

controles_desempeno <- function(ns) {
  shiny::tagList(
    shiny::conditionalPanel(
      condition = sprintf("output.%s",
                          bandera_artefacto("f4.diagnostico.scree")), ns = ns,
      shiny::sliderInput(ns("umbral_acumulado"), "Umbral de varianza acumulada",
                         min = 0.5, max = 0.99, value = 0.8, step = 0.05)),
    shiny::tags$p(class = "text-muted small mb-0",
                  paste("Los números salen del ajuste completo, nunca de la",
                        "muestra que se dibuja.")))
}

salida_desempeno <- function(ns) {
  shiny::tagList(
    bslib::card(
      bslib::card_header("Qué salió de la corrida"),
      bslib::card_body(
        shiny::uiOutput(ns("cajas_desempeno")),
        shiny::uiOutput(ns("lectura_desempeno")))),
    panel_si_declara(ns, "f4.desempeno.grupos",
                     shiny::plotOutput(ns("tamanos"), height = "300px"),
                     contexto = salida_contexto(ns, "contexto_tamanos")),
    shiny::conditionalPanel(
      condition = sprintf("output.%s",
                          bandera_artefacto("f4.diagnostico.scree")), ns = ns,
      bslib::card(bslib::card_header("Varianza por componente"),
                  bslib::card_body(shiny::tableOutput(ns("tabla_varianza"))))))
}

servidor_desempeno <- function(input, output, session, corrida) {
  ajuste <- shiny::reactive({
    c <- corrida()
    shiny::validate(shiny::need(!is.null(c),
                                "Corré una composición para ver su desempeño."))
    c$ajuste
  })

  output$cajas_desempeno <- shiny::renderUI({
    metricas <- metricas_de_corrida(ajuste())
    visibles <- setdiff(names(metricas), METRICAS_OCULTAS)
    cajas <- lapply(visibles, function(nombre)
      .caja(.etiqueta_metrica(nombre), .valor_metrica(nombre, metricas[[nombre]]),
            .pie_metrica(nombre, metricas)))
    do.call(bslib::layout_column_wrap,
            c(list(width = "180px", fill = FALSE), cajas))
  })

  # La única línea que interpreta, y lo hace con el número a la vista para que
  # se pueda discutir. No decide por el usuario: dice qué haría falta.
  output$lectura_desempeno <- shiny::renderUI({
    a <- ajuste()
    shiny::tags$p(class = "mt-3 mb-0",
                  lectura_resultado(a, umbral = input$umbral_acumulado))
  })

  output$tamanos <- shiny::renderPlot(graficar_tamanos(resumen_grupos(ajuste())))

  output$tabla_varianza <- shiny::renderTable({
    tabla <- varianza_explicada(ajuste())
    data.frame(
      componente = tabla$etiqueta,
      `valor propio` = round(tabla$valor_propio, 4),
      proporcion = sprintf("%.1f %%", 100 * tabla$proporcion),
      acumulada = sprintf("%.1f %%", 100 * tabla$acumulada),
      check.names = FALSE)
  }, striped = TRUE, width = "100%")

  dibujar_contexto(output, "f4.desempeno.grupos",
                   corrida = shiny::reactive(corrida()),
                   params = shiny::reactive({
                     c <- corrida(); if (is.null(c)) NULL else c$params
                   }),
                   metricas = shiny::reactive({
                     c <- corrida(); if (is.null(c)) NULL else c$metricas
                   }),
                   sufijo = "contexto_tamanos")
  invisible(TRUE)
}

.etiqueta_metrica <- function(nombre) {
  formato <- FORMATO_METRICA[[nombre]]
  if (is.null(formato)) gsub("_", " ", nombre) else formato[[1]]
}

.valor_metrica <- function(nombre, valor) {
  if (is.null(valor) || !length(valor)) return("-")
  tipo <- (FORMATO_METRICA[[nombre]] %||% list(NULL, "decimal"))[[2]]
  switch(tipo,
         entero = format(valor, big.mark = "."),
         porcentaje = sprintf("%.1f %%", 100 * valor),
         decimal = sprintf("%.3f", valor),
         as.character(valor))
}

# El pie de una caja es donde va el matiz que el número solo no lleva.
.pie_metrica <- function(nombre, metricas) {
  switch(nombre,
         iteraciones = if (isTRUE(metricas$convergio)) "convergio"
                       else "agoto el techo",
         silueta_media = if (isTRUE(metricas$silueta_muestreada))
           "sobre una muestra" else "sobre todas las filas",
         k = if (!is.null(metricas$inercia)) "grupos" else "componentes",
         NULL)
}

.caja <- function(titulo, valor, pie = NULL) {
  bslib::value_box(
    title = titulo, value = valor, theme = "text-primary",
    if (!is.null(pie)) shiny::tags$span(class = "small", pie))
}
