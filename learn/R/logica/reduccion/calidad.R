# learn/R/logica/reduccion/calidad.R
#
# Responsabilidad: medir cuánto aporta cada variable a un eje y cuán bien
# representada queda cada cosa en el plano que se está mirando.
#
# Es la mitad de la interpretación que el scree no da. El scree dice cuánta
# varianza retiene el plano; esto dice DE QUIÉN es esa varianza (contribución) y
# a quién le está mintiendo el dibujo (calidad). Una variable con flecha corta no
# es una variable sin importancia: es una variable que vive en las componentes
# que no se están mirando, y las dos frases llevan a decisiones distintas.
#
# Puras (C3): entra un ajuste de la familia reducción, sale un data.frame.
# Sirven igual para el ACP y para el ACM.

#' Contribución de cada variable a cada componente, en porcentaje.
#'
#' Los autovectores son de norma 1, así que los cuadrados de las cargas de una
#' componente suman 1: en porcentaje, la contribución reparte 100 entre las
#' variables. La referencia natural es 100/p, lo que aportaría cada variable si
#' todas aportaran igual.
#'
#' @param componentes cuáles mirar; NULL = las retenidas (`k`)
#' @return data.frame(variable, componente, etiqueta, contribucion)
contribuciones <- function(ajuste, componentes = NULL) {
  matriz <- ajuste$cargas
  componentes <- componentes %||% seq_len(ajuste$k)
  componentes <- intersect(componentes, seq_len(ncol(matriz)))

  partes <- lapply(componentes, function(j) {
    cuadrados <- matriz[, j]^2
    data.frame(variable = rownames(matriz), componente = j,
               etiqueta = colnames(matriz)[j],
               contribucion = 100 * cuadrados / sum(cuadrados))
  })
  do.call(rbind, partes)
}

#' Calidad de representación de las variables: cos² por eje y en el plano.
#'
#' El cos² de una variable en un eje es el cuadrado de su correlación con ese
#' eje, y en el plano es la suma de los dos. Es la longitud de la flecha del
#' círculo de correlaciones, elevada al cuadrado y leída como proporción.
#'
#' Sobre S (covarianza) las coordenadas no son correlaciones y el cos² puede
#' pasar de 1; el gráfico lo avisa igual que `graficar_circulo()`, en vez de
#' recortar el número y fingir que la cuenta cerró.
#'
#' @return data.frame(variable, componente, etiqueta, cos2, cos2_plano)
calidad_variables <- function(ajuste, ejes = c(1L, 2L)) {
  correlaciones <- correlaciones_componentes(ajuste, ejes)
  etiquetas <- colnames(ajuste$cargas)[ejes]
  plano <- correlaciones$radio^2

  rbind(
    data.frame(variable = correlaciones$variable, componente = ejes[1],
               etiqueta = etiquetas[1], cos2 = correlaciones$x^2,
               cos2_plano = plano),
    data.frame(variable = correlaciones$variable, componente = ejes[2],
               etiqueta = etiquetas[2], cos2 = correlaciones$y^2,
               cos2_plano = plano))
}

#' Calidad y contribución de cada observación en el plano pedido.
#'
#' `cos2` divide la proyección de la fila por su distancia total al centroide:
#' es la fracción de esa fila que el plano sí está mostrando. Una fila con cos²
#' bajo está dibujada donde no está — es el caso de los dos carros de la clase
#' que caen en el mismo punto viniendo de lados opuestos del espacio.
#'
#' `contribucion` es lo contrario: cuánto de la componente lo puso esa fila. Un
#' atípico se delata acá, con un número, antes de que uno lo sospeche mirando.
#'
#' @return data.frame(fila, componente, etiqueta, cos2, contribucion, cos2_plano)
calidad_individuos <- function(ajuste, ejes = c(1L, 2L)) {
  ejes <- .ejes_validos(ajuste, ejes)
  puntuaciones <- ajuste$puntuaciones
  normas <- ajuste$norma2_filas
  if (is.null(normas))
    stop("el ajuste no guardo norma2_filas: reajusta el modelo")

  etiquetas <- colnames(puntuaciones)
  plano <- rowSums(puntuaciones[, ejes, drop = FALSE]^2) / normas

  partes <- lapply(ejes, function(j) {
    cuadrados <- puntuaciones[, j]^2
    data.frame(fila = seq_len(nrow(puntuaciones)), componente = j,
               etiqueta = etiquetas[j],
               cos2 = as.numeric(cuadrados / normas),
               # El denominador es la suma observada y no (n-1)·lambda: el mismo
               # numero por dos caminos, y este no depende de como se estimo la
               # varianza.
               contribucion = as.numeric(100 * cuadrados / sum(cuadrados)),
               cos2_plano = as.numeric(plano))
  })
  do.call(rbind, partes)
}

#' La matriz de correlaciones entre las componentes retenidas.
#'
#' Tiene que ser la identidad, y esa es toda la gracia: las componentes son
#' ortogonales por construcción, así que no comparten información. Es lo que
#' habilita usarlas como predictores (regresión sobre componentes) donde las
#' variables originales, colineales, inflaban los errores estándar.
#'
#' Verlo dibujado también es un control: si la diagonal no es 1 o hay algo
#' fuera de ella, el ajuste está mal y no es una cuestión de interpretación.
correlacion_puntuaciones <- function(ajuste) {
  puntuaciones <- ajuste$puntuaciones
  if (ncol(puntuaciones) < 2L) {
    unica <- matrix(1, 1, 1, dimnames = list(colnames(puntuaciones),
                                             colnames(puntuaciones)))
    return(unica)
  }
  stats::cor(puntuaciones)
}

#' Las puntuaciones como data.frame, para volver a entrar por la fase 1.
#'
#' Un ACP no termina en un dibujo: sus puntuaciones son variables nuevas, pocas
#' y no correlacionadas, y ese es el uso industrial del método (paso intermedio,
#' *feature engineering*, regresión sobre componentes).
#'
#' @param prefijo NULL respeta los nombres del ajuste (CP1, CP2, ...)
puntuaciones_como_dataframe <- function(ajuste, prefijo = NULL) {
  tabla <- as.data.frame(ajuste$puntuaciones)
  if (!is.null(prefijo))
    names(tabla) <- paste0(prefijo, seq_len(ncol(tabla)))
  tabla
}
