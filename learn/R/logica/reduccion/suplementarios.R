# learn/R/logica/reduccion/suplementarios.R
#
# Responsabilidad: ubicar en un plano ya construido cosas que no lo
# construyeron.
#
# Un individuo suplementario es una fila que se proyecta con las cargas, el
# centro y la escala del ajuste, pero que no participó de la maximización: no
# movió ni un grado los ejes. Sirve para preguntar "¿dónde caería esto?" sin
# contaminar la respuesta — el carro de 2014 medido con los ejes de 1974.
#
# Una variable suplementaria es lo mismo por columnas: se correlaciona con las
# puntuaciones que ya existen y se dibuja en el círculo sin haber entrado.
#
# Que sea legítimo depende de una sola cosa, y es la que hace falta cuidar: se
# usan el centro y la escala del AJUSTE, nunca los del dato nuevo. Reescalar con
# la media del suplementario sería ponerlo en otro espacio y dibujarlo igual.

#' Proyecta filas nuevas sobre las componentes de un ajuste.
#'
#' @param ajuste    ajuste de la familia reducción, ya hecho
#' @param datos     data.frame con las columnas de `ajuste$columnas`
#' @param ejes      par de componentes en las que se quiere la coordenada
#' @param etiquetas nombres para los puntos; NULL usa los rownames o el índice
#' @return data.frame(fila, etiqueta, x, y, cos2_plano)
proyectar_individuos <- function(ajuste, datos, ejes = c(1L, 2L),
                                 etiquetas = NULL) {
  ejes <- .ejes_validos(ajuste, ejes)
  z <- .escalar_como_el_ajuste(ajuste, datos)

  coordenadas <- z$matriz %*% ajuste$cargas
  normas <- rowSums(z$matriz^2)
  plano <- rowSums(coordenadas[, ejes, drop = FALSE]^2)

  nombres <- etiquetas %||% z$etiquetas
  data.frame(fila = seq_len(nrow(coordenadas)),
             etiqueta = nombres,
             x = as.numeric(coordenadas[, ejes[1]]),
             y = as.numeric(coordenadas[, ejes[2]]),
             # Con norma cero la fila ES el centroide: cae en el origen y su
             # calidad no esta definida. NA y no 1, que seria inventarla.
             cos2_plano = ifelse(normas > 0, plano / normas, NA_real_),
             stringsAsFactors = FALSE)
}

#' Dónde apuntaría una variable que no entró al ajuste.
#'
#' Es la correlación de esa variable con cada componente, que es exactamente lo
#' que el círculo de correlaciones dibuja para las variables activas. La forma
#' del data.frame es la de `correlaciones_componentes()` a propósito: así
#' `graficar_circulo()` la recibe sin una rama nueva.
#'
#' @param valores vector con una entrada por fila USADA en el ajuste, en el
#'   mismo orden (las filas con faltantes se descartaron al ajustar)
#' @return data.frame(variable, x, y, radio)
proyectar_variable <- function(ajuste, valores, nombre = "suplementaria",
                               ejes = c(1L, 2L)) {
  ejes <- .ejes_validos(ajuste, ejes)
  puntuaciones <- ajuste$puntuaciones
  if (length(valores) != nrow(puntuaciones))
    stop(sprintf(paste("la variable suplementaria trae %d valores y el ajuste",
                       "uso %d filas: recortala a las filas completas"),
                 length(valores), nrow(puntuaciones)))
  if (!is.numeric(valores))
    stop("una variable suplementaria en el circulo tiene que ser cuantitativa")
  if (stats::sd(valores, na.rm = TRUE) == 0)
    stop("la variable suplementaria es constante: no se correlaciona con nada")

  correlacion <- function(j)
    stats::cor(valores, puntuaciones[, j], use = "complete.obs")

  x <- correlacion(ejes[1]); y <- correlacion(ejes[2])
  data.frame(variable = nombre, x = x, y = y, radio = sqrt(x^2 + y^2),
             stringsAsFactors = FALSE)
}

#' ¿Sirve este dataset como suplementario de este ajuste?
#'
#' Se pregunta antes de ofrecerlo en un selector: un dataset al que le falta una
#' columna del ajuste no se puede proyectar, y enterarse al dibujar es tarde.
#'
#' @return TRUE, o una cadena con el motivo del rechazo
sirve_como_suplementario <- function(ajuste, datos) {
  if (is.null(datos) || !nrow(datos)) return("no tiene filas")
  faltan <- setdiff(ajuste$columnas, names(datos))
  if (length(faltan))
    return(sprintf("le faltan columnas del ajuste: %s",
                   paste(faltan, collapse = ", ")))
  no_numericas <- vapply(datos[ajuste$columnas],
                         function(x) !is.numeric(x), logical(1))
  if (any(no_numericas))
    return(sprintf("estas columnas no son numericas aca: %s",
                   paste(ajuste$columnas[no_numericas], collapse = ", ")))
  TRUE
}

# El centro y la escala son los del ajuste. Si se recalcularan sobre el dato
# nuevo, el punto quedaria dibujado en un espacio que no es el del grafico.
.escalar_como_el_ajuste <- function(ajuste, datos) {
  if (is.null(ajuste$centro) || is.null(ajuste$escala))
    stop(paste("este ajuste no guarda centro ni escala, asi que no admite",
               "individuos suplementarios: un ACM se proyecta por perfiles de",
               "categoria, no reescalando"))
  veredicto <- sirve_como_suplementario(ajuste, datos)
  if (!isTRUE(veredicto))
    stop(sprintf("el dataset suplementario no se puede proyectar: %s",
                 veredicto))

  bruta <- as.matrix(datos[, ajuste$columnas, drop = FALSE])
  completas <- stats::complete.cases(bruta)
  if (!any(completas))
    stop("ninguna fila suplementaria esta completa en las columnas del ajuste")

  nombres <- rownames(datos) %||% as.character(seq_len(nrow(datos)))
  list(matriz = scale(bruta[completas, , drop = FALSE],
                      center = ajuste$centro, scale = ajuste$escala),
       etiquetas = nombres[completas])
}
