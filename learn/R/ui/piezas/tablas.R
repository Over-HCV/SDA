# learn/R/ui/piezas/tablas.R
#
# Responsabilidad: que ninguna tabla de la app vuelque todo (C7).
#
# Una tabla sin paginar mata el navegador con charcoal (35.115 filas) y, peor,
# no comunica nada: nadie lee 35.000 filas. El pie "mostrando X de N" es
# obligatorio porque una tabla truncada en silencio miente.

FILAS_POR_PAGINA <- 10L

#' DT con paginación, filtro y opciones sanas por defecto.
#'
#' @param df          data.frame a mostrar
#' @param filas       filas por página
#' @param filtro      "top" para filtros por columna, "none" para ninguno
#' @param seleccion   "none", "single" o "multiple"
#' @param redondear   columnas numéricas a redondear, o NULL para todas
tabla_paginada <- function(df, filas = FILAS_POR_PAGINA, filtro = "top",
                           seleccion = "none", redondear = NULL,
                           decimales = 3L) {
  if (is.null(df) || !nrow(df)) {
    return(DT::datatable(data.frame(` ` = "Sin datos", check.names = FALSE),
                         options = list(dom = "t"), rownames = FALSE))
  }

  tabla <- DT::datatable(
    df, rownames = FALSE, filter = filtro, selection = seleccion,
    options = list(
      pageLength = filas,
      lengthMenu = c(5, 10, 25, 50),
      scrollX = TRUE,
      deferRender = TRUE,
      # En servidor el filtrado ocurre en R y solo viaja la página visible.
      # En wasm no hay servidor: DT tiene que traerse la tabla entera, así
      # que ahí conviene pasarle un data.frame ya recortado.
      language = list(
        search = "Buscar:", lengthMenu = "Mostrar _MENU_ filas",
        info = "Mostrando _START_ a _END_ de _TOTAL_",
        infoEmpty = "Sin filas", infoFiltered = "(filtrado de _MAX_)",
        paginate = list(previous = "Anterior", `next` = "Siguiente"),
        zeroRecords = "Ninguna fila coincide")
    )
  )

  numericas <- redondear %||% names(df)[vapply(df, is.numeric, logical(1))]
  numericas <- intersect(numericas, names(df))
  if (length(numericas)) tabla <- DT::formatRound(tabla, numericas, decimales)
  tabla
}

#' Recorta un data.frame antes de mandarlo a DT en modo navegador.
#'
#' En wasm la tabla entera viaja al cliente; con 35.000 filas eso congela la
#' pestaña. Se recorta y el pie lo dice: nunca truncar en silencio.
recortar_para_tabla <- function(df, maximo = 2000L) {
  if (is.null(df) || nrow(df) <= maximo || !es_wasm()) return(df)
  utils::head(df, maximo)
}

#' Pie obligatorio de toda tabla.
#' @param n_mostradas filas efectivamente enviadas al navegador
#' @param n_totales   filas del data.frame original
pie_tabla <- function(n_mostradas, n_totales) {
  texto_pie <- if (n_mostradas < n_totales) {
    sprintf("Mostrando %s de %s filas · el resto no viajó al navegador",
            format(n_mostradas, big.mark = "."), format(n_totales, big.mark = "."))
  } else {
    sprintf("%s filas", format(n_totales, big.mark = "."))
  }
  shiny::tags$div(class = "text-muted small mt-1", texto_pie)
}

#' Tabla + su pie, que es como debería usarse siempre.
salida_tabla <- function(ns, id, altura = NULL) {
  shiny::tagList(
    DT::dataTableOutput(ns(id), height = altura),
    shiny::uiOutput(ns(paste0(id, "_pie")))
  )
}

#' Contraparte de salida_tabla() en el server.
#' @param datos reactivo que devuelve el data.frame completo
dibujar_tabla <- function(output, id, datos, ...) {
  output[[id]] <- DT::renderDataTable({
    df <- datos()
    tabla_paginada(recortar_para_tabla(df), ...)
  })
  output[[paste0(id, "_pie")]] <- shiny::renderUI({
    df <- datos()
    total <- if (is.null(df)) 0L else nrow(df)
    pie_tabla(nrow(recortar_para_tabla(df)) %||% 0L, total)
  })
  invisible(TRUE)
}
