# learn/R/logica/datos_balanceo.R
#
# Responsabilidad: mirar y corregir el desbalance de una variable de clase.
#
# Las tres técnicas de acá no traen dependencias: sub-muestreo tira filas,
# sobre-muestreo repite filas, bootstrap remuestrea con reemplazo. SMOTE, que
# INTERPOLA vecinos y por tanto fabrica filas nuevas, queda registrado como
# método pendiente: pedirlo trae smotefamily al bundle y el Hito 2 no paga eso.
#
# Toda técnica lleva semilla en la firma y marca el origen de cada fila (C13):
# un gráfico que no distingue lo real de lo remuestreado engaña.

#' Frecuencias por clase, con la razón de desbalance.
#'
#' @return data.frame(clase, n, proporcion) con atributos razon y minoritaria
resumir_balance <- function(datos, columna) {
  valores <- as.character(datos[[columna]])
  conteo <- sort(table(valores[!is.na(valores)]), decreasing = TRUE)
  if (!length(conteo))
    return(data.frame(clase = character(0), n = integer(0),
                      proporcion = numeric(0)))

  tabla <- data.frame(clase = names(conteo), n = as.integer(conteo),
                      proporcion = as.numeric(conteo) / sum(conteo),
                      stringsAsFactors = FALSE)
  attr(tabla, "razon") <- max(tabla$n) / min(tabla$n)
  attr(tabla, "minoritaria") <- tabla$clase[which.min(tabla$n)]
  attr(tabla, "mayoritaria") <- tabla$clase[which.max(tabla$n)]
  tabla
}

#' Pesos inversos a la frecuencia. La alternativa a remuestrear: no toca los
#' datos, se los pasa al método. Suman n para no cambiar la escala de la
#' función objetivo.
pesos_clase <- function(datos, columna) {
  balance <- resumir_balance(datos, columna)
  if (!nrow(balance)) return(numeric(0))
  crudos <- sum(balance$n) / (nrow(balance) * balance$n)
  stats::setNames(crudos, balance$clase)
}

#' Rebalancea remuestreando filas existentes.
#'
#' @param metodo "submuestreo" (recorta las clases grandes), "sobremuestreo"
#'   (repite las chicas) o "bootstrap" (remuestrea todas con reemplazo)
#' @return list(datos, origen, antes, despues, metodo, semilla)
balancear <- function(datos, columna, metodo = "submuestreo", semilla = 42L) {
  antes <- resumir_balance(datos, columna)
  if (nrow(antes) < 2L)
    return(list(datos = datos, origen = rep("original", nrow(datos)),
                antes = antes, despues = antes, metodo = metodo,
                semilla = semilla))

  set.seed(semilla)
  clases <- as.character(datos[[columna]])
  objetivo <- switch(metodo,
    submuestreo = min(antes$n),
    sobremuestreo = max(antes$n),
    bootstrap = round(mean(antes$n)),
    stop("metodo de balanceo desconocido: ", metodo))

  elegidas <- unlist(lapply(antes$clase, function(clase) {
    disponibles <- which(clases == clase)
    con_reemplazo <- identical(metodo, "bootstrap") ||
      objetivo > length(disponibles)
    sample(disponibles, objetivo, replace = con_reemplazo)
  }))

  origen <- ifelse(duplicated(elegidas), "remuestreada", "original")
  copia <- datos[elegidas, , drop = FALSE]
  rownames(copia) <- NULL
  list(datos = copia, origen = origen, antes = antes,
       despues = resumir_balance(copia, columna), metodo = metodo,
       semilla = semilla)
}
