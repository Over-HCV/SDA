# learn/R/logica/datos/calidad.R
#
# Responsabilidad: encontrar y arreglar lo que está roto en el dataset —
# faltantes, duplicados, atípicos y tipos mal leídos.
#
# Ninguna función imputa por su cuenta ni descarta filas en silencio: todas
# devuelven qué harían, y la UI decide. Una limpieza invisible es una mentira
# que aparece tres fases después, cuando ya nadie la puede rastrear.

#' Panorama de faltantes: por columna, por fila y por patrón de ausencia.
#'
#' El patrón importa más que el conteo. Si las mismas filas fallan siempre en
#' las mismas columnas, no es azar (MCAR): hay un mecanismo detrás.
#'
#' @return list(por_columna, por_fila, patrones, total_pct, matriz)
patron_faltantes <- function(datos) {
  matriz <- is.na(datos)
  por_columna <- data.frame(
    columna = names(datos),
    faltantes = as.integer(colSums(matriz)),
    porcentaje = round(100 * colMeans(matriz), 2),
    stringsAsFactors = FALSE)
  por_columna <- por_columna[order(-por_columna$faltantes), ]

  faltantes_fila <- as.integer(rowSums(matriz))
  claves <- apply(matriz, 1, function(fila) paste0(as.integer(fila), collapse = ""))
  conteo <- sort(table(claves), decreasing = TRUE)
  patrones <- data.frame(
    patron = names(conteo), filas = as.integer(conteo),
    columnas_faltantes = vapply(names(conteo), function(clave)
      paste(names(datos)[strsplit(clave, "")[[1]] == "1"], collapse = ", "), ""),
    stringsAsFactors = FALSE)

  list(por_columna = por_columna,
       por_fila = data.frame(fila = seq_len(nrow(datos)),
                             faltantes = faltantes_fila),
       patrones = utils::head(patrones, 12L),
       total_pct = round(100 * mean(matriz), 2),
       completas = sum(faltantes_fila == 0L),
       matriz = matriz)
}

#' Atípicos de una columna por tres criterios distintos.
#'
#' @param metodo "iqr" (cerca de Tukey), "z" (desvíos estándar) o
#'   "mahalanobis" (multivariado: usa todas las numéricas, no una)
#' @param umbral 1.5 para iqr, 3 para z, nivel de confianza para mahalanobis
#' @return data.frame(fila, valor, distancia, atipico) más atributos
detectar_atipicos <- function(datos, columna = NULL, metodo = "iqr",
                              umbral = NULL) {
  if (identical(metodo, "mahalanobis")) {
    nivel <- umbral %||% 0.975
    distancias <- mahalanobis_cuadrado(datos)
    numericas <- sum(vapply(datos, is.numeric, logical(1)))
    corte <- stats::qchisq(nivel, df = max(1L, numericas))
    return(.tabla_atipicos(seq_len(nrow(datos)), rep(NA_real_, nrow(datos)),
                           distancias, distancias > corte, corte, metodo))
  }

  valores <- as.numeric(datos[[columna]])
  if (identical(metodo, "z")) {
    corte <- umbral %||% 3
    centro <- mean(valores, na.rm = TRUE)
    desviacion <- stats::sd(valores, na.rm = TRUE)
    distancias <- if (!is.finite(desviacion) || desviacion == 0)
      rep(0, length(valores)) else abs(valores - centro) / desviacion
    return(.tabla_atipicos(seq_along(valores), valores, distancias,
                           distancias > corte, corte, metodo))
  }

  corte <- umbral %||% 1.5
  cuartiles <- stats::quantile(valores, c(0.25, 0.75), na.rm = TRUE, names = FALSE)
  rango <- cuartiles[2] - cuartiles[1]
  limites <- c(cuartiles[1] - corte * rango, cuartiles[2] + corte * rango)
  distancias <- pmax(limites[1] - valores, valores - limites[2], 0)
  .tabla_atipicos(seq_along(valores), valores, distancias,
                  valores < limites[1] | valores > limites[2], limites, metodo)
}

.tabla_atipicos <- function(filas, valores, distancias, marca, corte, metodo) {
  marca[is.na(marca)] <- FALSE
  tabla <- data.frame(fila = filas, valor = valores, distancia = distancias,
                      atipico = marca, stringsAsFactors = FALSE)
  attr(tabla, "corte") <- corte
  attr(tabla, "metodo") <- metodo
  attr(tabla, "n_atipicos") <- sum(marca)
  tabla
}

#' Imputa una columna sin traer mice ni VIM: media, mediana o moda.
#'
#' Las tres inventan datos, y las tres achican la varianza. La función devuelve
#' también cuántos valores tocó, para que el aviso sea obligatorio arriba.
#'
#' @return list(datos, imputados, metodo, relleno)
imputar <- function(datos, columna, metodo = "mediana") {
  valores <- datos[[columna]]
  faltan <- is.na(valores)
  if (!any(faltan))
    return(list(datos = datos, imputados = 0L, metodo = metodo, relleno = NA))

  relleno <- switch(metodo,
    media = mean(as.numeric(valores), na.rm = TRUE),
    mediana = stats::median(as.numeric(valores), na.rm = TRUE),
    moda = .moda(valores[!faltan]),
    stop("metodo de imputacion desconocido: ", metodo))

  copia <- datos
  copia[[columna]][faltan] <- relleno
  list(datos = copia, imputados = sum(faltan), metodo = metodo,
       relleno = relleno)
}

#' Filas repetidas: cuáles y cuántas veces. No borra nada.
marcar_duplicados <- function(datos, columnas = NULL) {
  base <- if (is.null(columnas)) datos else datos[, columnas, drop = FALSE]
  repetida <- duplicated(base)
  claves <- do.call(paste, c(base, sep = "\r"))
  conteo <- table(claves)
  data.frame(fila = seq_len(nrow(datos)), duplicada = repetida,
             repeticiones = as.integer(conteo[claves]),
             stringsAsFactors = FALSE)
}

#' Coerción explícita de tipo. Devuelve cuántos valores se perdieron al
#' convertir, porque un as.numeric() silencioso sobre texto sucio es la forma
#' más rápida de fabricar faltantes que nadie pidió.
coercionar_columna <- function(datos, columna, a = "numerica") {
  original <- datos[[columna]]
  convertido <- switch(a,
    numerica = suppressWarnings(as.numeric(as.character(original))),
    texto = as.character(original),
    factor = factor(original),
    entero = suppressWarnings(as.integer(as.character(original))),
    stop("tipo destino desconocido: ", a))
  copia <- datos
  copia[[columna]] <- convertido
  list(datos = copia, perdidos = sum(is.na(convertido) & !is.na(original)),
       destino = a)
}
