# learn/R/logica/metricas_reduccion.R
#
# Responsabilidad: traducir un ajuste de reducción de dimensión a las tablas
# que se dibujan.
#
# El ajuste devuelve matrices; los gráficos quieren data.frames largos. Que la
# traducción viva acá y no dentro del gráfico es lo que permite exportar la
# tabla que hay detrás de cada figura (S2) y probarla sin dibujar nada.
#
# Sirve para ACP y, sin cambios, para cualquier método que devuelva cargas,
# puntuaciones y valores propios: análisis factorial, ACP robusto, MDS métrico.

#' Varianza explicada por componente y acumulada.
#'
#' @return data.frame(componente, etiqueta, valor_propio, proporcion, acumulada)
varianza_explicada <- function(ajuste) {
  valores <- ajuste$valores_propios
  proporcion <- ajuste$varianza_explicada
  data.frame(componente = seq_along(valores),
             etiqueta = names(valores) %||% paste0("CP", seq_along(valores)),
             valor_propio = as.numeric(valores),
             proporcion = as.numeric(proporcion),
             acumulada = cumsum(as.numeric(proporcion)))
}

#' Cargas en formato largo: qué pesa cada variable en cada componente.
#'
#' @param componentes cuáles mirar; NULL = las retenidas (`k`)
#' @return data.frame(variable, componente, etiqueta, carga)
cargas <- function(ajuste, componentes = NULL) {
  matriz <- ajuste$cargas
  componentes <- componentes %||% seq_len(ajuste$k)
  componentes <- intersect(componentes, seq_len(ncol(matriz)))
  partes <- lapply(componentes, function(j) {
    data.frame(variable = rownames(matriz), componente = j,
               etiqueta = colnames(matriz)[j], carga = as.numeric(matriz[, j]))
  })
  do.call(rbind, partes)
}

#' Correlación de cada variable con cada componente.
#'
#' Es la carga reescalada: r(xᵢ, CPⱼ) = vᵢⱼ · √λⱼ / sᵢ. Sobre R (datos
#' estandarizados) sᵢ vale 1 y la correlación cae dentro del círculo de radio 1,
#' que es lo que hace legible el círculo de correlaciones. Sobre S no: por eso
#' el gráfico avisa en vez de mentir con un círculo que no aplica.
#'
#' @return data.frame(variable, x, y, radio) para el par de ejes pedido
correlaciones_componentes <- function(ajuste, ejes = c(1L, 2L)) {
  ejes <- .ejes_validos(ajuste, ejes)
  escala <- if (identical(ajuste$matriz, "correlacion")) rep(1, ajuste$p)
            else ajuste$escala
  cor_de <- function(j) ajuste$cargas[, j] * sqrt(ajuste$valores_propios[j]) / escala

  x <- cor_de(ejes[1]); y <- cor_de(ejes[2])
  data.frame(variable = rownames(ajuste$cargas), x = as.numeric(x),
             y = as.numeric(y), radio = sqrt(as.numeric(x)^2 + as.numeric(y)^2))
}

#' Las observaciones en el plano de dos componentes.
#'
#' @param grupo vector con una entrada por fila usada en el ajuste, o NULL
#' @return data.frame(fila, x, y, grupo)
coordenadas_2d <- function(ajuste, ejes = c(1L, 2L), grupo = NULL) {
  ejes <- .ejes_validos(ajuste, ejes)
  puntuaciones <- ajuste$puntuaciones
  tabla <- data.frame(fila = seq_len(nrow(puntuaciones)),
                      x = puntuaciones[, ejes[1]],
                      y = puntuaciones[, ejes[2]])
  tabla$grupo <- if (is.null(grupo)) factor("todas")
                 else factor(grupo[seq_len(nrow(tabla))])
  tabla
}

#' Puntos y flechas de un biplot, en la misma escala.
#'
#' El biplot superpone dos cosas con unidades distintas: observaciones
#' (puntuaciones) y variables (cargas). Para que se puedan mirar juntas hay que
#' reescalar las flechas; el factor es una decisión de dibujo, no un resultado,
#' así que sale acá y viaja al bloque de contexto.
#'
#' @return list(puntos, flechas, escala_flechas)
coordenadas_biplot <- function(ajuste, ejes = c(1L, 2L), grupo = NULL,
                               escala_flechas = NULL) {
  ejes <- .ejes_validos(ajuste, ejes)
  puntos <- coordenadas_2d(ajuste, ejes, grupo)

  cargas_ejes <- ajuste$cargas[, ejes, drop = FALSE]
  extension_puntos <- max(abs(c(puntos$x, puntos$y)), na.rm = TRUE)
  extension_cargas <- max(abs(cargas_ejes), na.rm = TRUE)
  automatica <- if (extension_cargas > 0) extension_puntos / extension_cargas else 1
  factor <- escala_flechas %||% (automatica * 0.8)

  flechas <- data.frame(variable = rownames(ajuste$cargas),
                        x = as.numeric(cargas_ejes[, 1]) * factor,
                        y = as.numeric(cargas_ejes[, 2]) * factor)
  list(puntos = puntos, flechas = flechas, escala_flechas = factor)
}

#' Regla del codo: la primera componente donde el descenso deja de valer la
#' pena. No es una verdad, es una heurística, y el texto del scree lo dice.
componentes_sugeridas <- function(ajuste, umbral_acumulado = 0.8) {
  tabla <- varianza_explicada(ajuste)
  suficientes <- which(tabla$acumulada >= umbral_acumulado)
  if (!length(suficientes)) return(nrow(tabla))
  suficientes[1]
}

.ejes_validos <- function(ajuste, ejes) {
  ejes <- as.integer(ejes)
  if (length(ejes) != 2L) stop("hacen falta exactamente dos ejes")
  if (any(ejes < 1L) || any(ejes > ajuste$k))
    stop(sprintf("solo hay %d componentes retenidas", ajuste$k))
  ejes
}
