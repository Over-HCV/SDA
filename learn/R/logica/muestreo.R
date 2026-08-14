# learn/R/logica/muestreo.R
#
# Responsabilidad: decidir qué filas se dibujan cuando el dataset es grande,
# y dejar constancia de la decisión (C8).
#
# La regla de oro: los GRÁFICOS reciben la muestra, las MÉTRICAS reciben el
# total. Truncar en silencio convierte un gráfico en una mentira, así que la
# función devuelve siempre con qué semilla y sobre cuántas filas se muestreó,
# y la UI está obligada a dibujar el badge con esos números.

UMBRAL_MUESTREO <- 5000L

#' Muestra reproducible para dibujar.
#'
#' @param datos data.frame a dibujar
#' @param umbral a partir de cuántas filas se muestrea
#' @param semilla obligatoria: sin ella el gráfico no es reproducible (C13)
#' @param usar_todo TRUE cuando el usuario pide explícitamente el total
#' @return list(datos, n_total, n_muestra, semilla, muestreado)
muestrear_para_grafico <- function(datos, umbral = UMBRAL_MUESTREO,
                                   semilla = 42L, usar_todo = FALSE) {
  n_total <- nrow(datos)
  if (isTRUE(usar_todo) || n_total <= umbral) {
    return(list(datos = datos, n_total = n_total, n_muestra = n_total,
                semilla = semilla, muestreado = FALSE))
  }
  set.seed(semilla)
  filas <- sort(sample.int(n_total, umbral))
  list(datos = datos[filas, , drop = FALSE], n_total = n_total,
       n_muestra = umbral, semilla = semilla, muestreado = TRUE)
}

#' Lo que viaja al JSON de la corrida y al bloque de contexto para el chat.
#' Devuelve NULL cuando no se muestreó: así el bloque no se llena de ruido.
descripcion_muestreo <- function(muestreo) {
  if (!isTRUE(muestreo$muestreado)) return(NULL)
  sprintf("%d de %d filas · semilla %s",
          muestreo$n_muestra, muestreo$n_total, muestreo$semilla)
}
