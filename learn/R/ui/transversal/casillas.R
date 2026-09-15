# learn/R/ui/transversal/casillas.R
#
# Las casillas «Añadir» de la fase 1: qué se captura al marcar un panel y cómo
# la casilla se mantiene fiel a la selección.
#
# Vivían dentro de informe.R, que es la pestaña que las EXPORTA. Son otro eje:
# se marcan en ① Datos, las lee Informe, las guarda la sesión. Separarlas dejó
# a informe.R por debajo del techo de C2.

# La lista de claves con casilla vive en nucleo/informe_exploracion.R: es un
# contrato sobre qué se puede exportar, no una decisión de presentación, y ahí
# las pruebas headless pueden mirarla sin cargar Shiny.

#' La casilla "Añadir" del encabezado de un panel. Solo eso: el verbo y el
#' check. Que el panel entra al informe al marcarla es intuitivo; una etiqueta
#' larga le roba lugar al título y a los badges.
casilla_informe <- function(ns, clave)
  shiny::checkboxInput(ns(paste0("inf_", clave)), "Añadir", FALSE)

#' Una entrada de la selección: lo que se captura al marcar la casilla.
#'
#' Los parámetros se congelan AL MARCAR, no al exportar: el cuaderno debe
#' reflejar lo que el usuario estaba viendo cuando decidió añadirlo.
entrada_de <- function(clave, input, ds, id = "p1") {
  params <- params_de_artefacto(clave, input, ds)
  params <- params[!vapply(params, is.null, logical(1))]
  list(id = id, clave = clave, titulo = titulo_de(clave),
       cuando = format(Sys.time(), "%H:%M:%S"), params = params,
       tabla = tabla_de_artefacto(clave, input, ds))
}

#' Un id que no se reutiliza: la caja de texto de la lectura se llama por él,
#' y si un id vuelve después de quitar un panel, la lectura de uno aparece en
#' el otro.
.siguiente_id_entrada <- function(entradas) {
  usados <- suppressWarnings(as.integer(sub("^p", "", vapply(
    entradas, function(e) e$id %||% "p0", ""))))
  sprintf("p%d", max(c(0L, usados[!is.na(usados)])) + 1L)
}

#' Parámetros que viajan al cuaderno, por clave. Los que se pueden calcular
#' (correlación, conteo de atípicos) se calculan acá y quedan congelados.
params_de_artefacto <- function(clave, input, ds) {
  df <- ds$df
  switch(
    clave,
    "f1.fuente.vista_previa" = list(filas = ds$n, columnas = ds$p),
    "f1.filtro.filas" = list(al_cargar = ds$n_crudo %||% ds$n, ahora = ds$n,
                             filtros = .describir_filtros(ds)),
    "f1.diccionario.tabla" = list(columnas = ds$p),
    "f1.analisis.histograma" = list(
      variable = input$variable_uni, clases = input$clases,
      densidad = isTRUE(input$con_densidad), normal = isTRUE(input$con_normal)),
    "f1.analisis.densidad" = list(
      variable = input$variable_uni, ancho = input$ancho,
      normal = isTRUE(input$con_normal)),
    "f1.analisis.boxplot" = list(variable = input$variable_uni),
    "f1.analisis.resumen" = list(variable = input$variable_uni,
                                 escala = .escala_de(ds, input$variable_uni)),
    "f1.analisis.boxplot_grupos" = list(variable = input$variable_uni,
                                        grupo = input$grupo_uni),
    "f1.analisis.qq_normal_datos" = list(variable = input$variable_uni),
    "f1.analisis.dispersion" = {
      a <- medir_asociacion(df[[input$x_bi]], df[[input$y_bi]])
      list(x = input$x_bi, y = input$y_bi, grupo = input$grupo_bi,
           marginales = isTRUE(input$marginales), alfa = input$alfa,
           jitter = isTRUE(input$jitter), celdas = isTRUE(input$celdas),
           suavizado = isTRUE(input$suavizado),
           regresion = isTRUE(input$regresion),
           pearson = round(a$pearson, 4), covarianza = round(a$covarianza, 4),
           spearman = round(a$spearman, 4), n = a$n)
    },
    "f1.analisis.densidad_conjunta" = list(x = input$x_bi, y = input$y_bi),
    "f1.analisis.mosaico" = {
      tabla <- tabla_contingencia(df[[input$cruce_a]], df[[input$cruce_b]],
                                  input$cruce_a, input$cruce_b)
      list(a = input$cruce_a, b = input$cruce_b, chi2 = round(tabla$chi2, 3),
           cramer = round(tabla$cramer, 4))
    },
    "f1.analisis.matriz_dispersion" = list(variables = input$variables_multi,
                                           grupo = input$grupo_multi),
    "f1.analisis.heatmap_correlacion" = list(variables = input$variables_multi,
                                             metodo = input$metodo_cor),
    "f1.analisis.coordenadas_paralelas" =
      list(variables = input$variables_multi, grupo = input$grupo_multi,
           metodo = input$normalizacion),
    "f1.analisis.elipsoide" = list(
      x = input$variables_multi[1], y = input$variables_multi[2],
      nivel = input$nivel_elipse),
    "f1.analisis.qq_mahalanobis" = list(variables = input$variables_multi),
    "f1.calidad.atipicos" = {
      metodo <- input$metodo_atipicos %||% "iqr"
      tabla <- detectar_atipicos(
        if (identical(metodo, "mahalanobis"))
          df[, columnas_numericas(ds), drop = FALSE] else df,
        input$columna_cal, metodo, input$umbral_atipicos)
      list(columna = input$columna_cal, metodo = metodo,
           umbral = input$umbral_atipicos,
           n_atipicos = attr(tabla, "n_atipicos"))
    },
    "f1.balanceo.frecuencias" = list(clase = input$clase_bal),
    list())
}

#' Tablas cuyo estado se congela tal cual: el diccionario es estado declarado
#' por el usuario y no se puede recalcular desde el código.
tabla_de_artefacto <- function(clave, input, ds) {
  switch(
    clave,
    "f1.fuente.vista_previa" = utils::head(ds$df, 10),
    "f1.filtro.filas" = tabla_filtro(ds$n_crudo %||% ds$n, ds$n),
    "f1.diccionario.tabla" = ds$diccionario[, c("columna", "escala", "clase",
                                                "rol")],
    "f1.balanceo.frecuencias" = resumir_balance(ds$df, input$clase_bal),
    "f1.analisis.resumen" = if (!is.null(input$variable_uni))
      resumir_variable(ds$df[[input$variable_uni]],
                       .escala_de(ds, input$variable_uni))[
                         , c("estadistico", "mostrado")] else NULL,
    NULL)
}

#' La identidad de un panel dentro del cuaderno: su clave más las columnas que
#' lo distinguen.
#'
#' Existe porque la casilla es por clave y el taller necesita el MISMO panel
#' dos veces con columnas distintas —la caja de Temperatura y la de
#' Velocidad_del_Viento son las dos mitades de la pregunta 4—. Con la identidad
#' en la mano, la casilla pasa a significar "lo que estoy mirando ahora está en
#' el cuaderno": al cambiar de variable se destilda sola y volver a marcarla
#' añade la segunda, en vez de reemplazar la primera.
#'
#' Los campos que identifican salen de PARAMS_REQUERIDOS, que ya declara cuáles
#' son las columnas de cada panel; acá solo hay que leerlas de los controles.
identidad_de_entrada <- function(entrada) {
  campos <- PARAMS_REQUERIDOS[[entrada$clave]] %||% character(0)
  paste(c(entrada$clave, unlist(entrada$params[campos], use.names = FALSE)),
        collapse = "|")
}

identidad_en_pantalla <- function(clave, input) {
  columnas <- switch(
    clave,
    "f1.analisis.histograma" = ,
    "f1.analisis.densidad" = ,
    "f1.analisis.boxplot" = ,
    "f1.analisis.resumen" = ,
    "f1.analisis.qq_normal_datos" = input$variable_uni,
    "f1.analisis.boxplot_grupos" = c(input$variable_uni, input$grupo_uni),
    "f1.analisis.dispersion" = ,
    "f1.analisis.densidad_conjunta" = c(input$x_bi, input$y_bi),
    "f1.analisis.elipsoide" = input$variables_multi[1:2],
    "f1.analisis.mosaico" = c(input$cruce_a, input$cruce_b),
    "f1.analisis.matriz_dispersion" = ,
    "f1.analisis.heatmap_correlacion" = ,
    "f1.analisis.coordenadas_paralelas" = ,
    "f1.analisis.qq_mahalanobis" = input$variables_multi,
    "f1.calidad.atipicos" = input$columna_cal,
    "f1.balanceo.frecuencias" = input$clase_bal,
    character(0))
  paste(c(clave, columnas), collapse = "|")
}

#' Observadores de las casillas: marcar añade lo que hay en pantalla, desmarcar
#' lo quita. El observer de sincronización devuelve la casilla a FALSE cuando
#' esa entrada ya no está —se vació la selección, se quitó la última, o se
#' cambió de columna—, para que la UI no mienta.
servidor_casillas <- function(input, session, dataset, seleccion) {
  lapply(CASILLAS_INFORME, function(clave) {
    shiny::observeEvent(input[[paste0("inf_", clave)]], {
      actual <- seleccion()
      identidad <- identidad_en_pantalla(clave, input)
      esta <- vapply(actual, function(e)
        identical(identidad_de_entrada(e), identidad), logical(1))
      if (!isTRUE(input[[paste0("inf_", clave)]])) {
        seleccion(actual[!esta])
        return(invisible(NULL))
      }
      # Restaurar una sesión vuelve a marcar las casillas, y sin esta guarda
      # cada marca programática añadía una copia: catorce paneles se volvían
      # veinticuatro al entrar a ① Datos.
      if (any(esta)) return(invisible(NULL))
      ds <- dataset()
      shiny::req(ds)
      seleccion(c(actual, list(entrada_de(clave, input, ds,
                                          .siguiente_id_entrada(actual)))))
    }, ignoreInit = TRUE)
  })

  # Prioridad baja a propósito: tiene que correr DESPUÉS de los observadores
  # que agregan o quitan. Con la misma prioridad el orden lo decidía Shiny, y
  # a veces la sincronización veía la casilla recién marcada con la selección
  # todavía vacía, mandaba FALSE al navegador y ese FALSE volvía y borraba lo
  # que se acababa de agregar.
  shiny::observe({
    marcadas <- vapply(seleccion(), identidad_de_entrada, "")
    for (clave in CASILLAS_INFORME) {
      debe_estar <- identidad_en_pantalla(clave, input) %in% marcadas
      if (!identical(isTRUE(input[[paste0("inf_", clave)]]), debe_estar))
        shiny::updateCheckboxInput(session, paste0("inf_", clave),
                                   value = debe_estar)
    }
  }, priority = -10)
}
