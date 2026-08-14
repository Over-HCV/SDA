# learn/R/logica/datos/particion.R
#
# Responsabilidad: repartir las filas en conjuntos, con semilla y sin trampa.
#
# La partición no copia los datos: devuelve un vector de asignación del largo
# de las filas. Así el objeto Dataset guarda tres números y una semilla en vez
# de tres data.frames, y la corrida sigue siendo reproducible desde el JSON.

#' Reparte las filas.
#'
#' @param tipo "holdout" o "kfold"
#' @param proporcion fracción de entrenamiento en holdout
#' @param k número de pliegues en kfold
#' @param estratificar nombre de columna cuya distribución se conserva en cada
#'   parte; NULL reparte al azar
#' @return list(tipo, asignacion, proporcion, k, estratificar, semilla)
particionar <- function(datos, tipo = "holdout", proporcion = 0.7, k = 5L,
                        estratificar = NULL, semilla = 42L) {
  n <- nrow(datos)
  set.seed(semilla)

  estratos <- if (is.null(estratificar)) rep("todo", n)
              else as.character(datos[[estratificar]])
  estratos[is.na(estratos)] <- "sin_dato"
  asignacion <- character(n)

  for (estrato in unique(estratos)) {
    filas <- which(estratos == estrato)
    mezcladas <- sample(filas)
    asignacion[mezcladas] <- if (identical(tipo, "kfold")) {
      paste0("pliegue_", rep_len(seq_len(k), length(mezcladas)))
    } else {
      corte <- max(1L, floor(length(mezcladas) * proporcion))
      c(rep("entrenamiento", corte),
        rep("prueba", length(mezcladas) - corte))
    }
  }

  list(tipo = tipo, asignacion = asignacion, proporcion = proporcion,
       k = if (identical(tipo, "kfold")) k else NA_integer_,
       estratificar = estratificar %||% NA_character_, semilla = semilla)
}

#' Tamaños de cada parte. Es la barra apilada de la subsección.
resumir_particion <- function(particion) {
  if (is.null(particion)) return(data.frame())
  conteo <- table(particion$asignacion)
  data.frame(parte = names(conteo), n = as.integer(conteo),
             proporcion = as.numeric(conteo) / sum(conteo),
             stringsAsFactors = FALSE)
}

#' Distribución de una columna dentro de cada parte. Lo que prueba que la
#' estratificación hizo lo que promete, en vez de creerle.
balance_por_particion <- function(datos, particion, columna) {
  if (is.null(particion) || !nrow(datos)) return(data.frame())
  partes <- particion$asignacion
  filas <- lapply(unique(partes), function(parte) {
    trozo <- datos[partes == parte, , drop = FALSE]
    balance <- resumir_balance(trozo, columna)
    if (!nrow(balance)) return(NULL)
    data.frame(parte = parte, clase = balance$clase, n = balance$n,
               proporcion = balance$proporcion, stringsAsFactors = FALSE)
  })
  do.call(rbind, Filter(Negate(is.null), filas))
}

#' Extrae una parte concreta. Se usa recién en la fase 4, pero vive acá porque
#' es la contraparte de particionar() y nadie más debe interpretar el vector.
filas_de_particion <- function(datos, particion, parte = "entrenamiento") {
  if (is.null(particion)) return(datos)
  datos[particion$asignacion == parte, , drop = FALSE]
}
