# learn/R/logica/contingencia.R
#
# Responsabilidad: cruzar dos cualitativas y decir si el cruce dice algo.
#
# La tabla sola no se interpreta: una celda grande puede serlo solo porque su
# fila y su columna son grandes. El residuo estandarizado es la respuesta —
# cuánto se aparta esa celda de lo que se esperaría si no hubiera relación —
# y por eso viaja junto a la tabla, no aparte.

#' Tabla de contingencia con esperados, residuos y prueba ji-cuadrado.
#'
#' @return list(tabla, esperados, residuos, chi2, gl, p_valor, cramer, aviso)
tabla_contingencia <- function(x, y, etiqueta_x = "x", etiqueta_y = "y") {
  completos <- !is.na(x) & !is.na(y)
  tabla <- table(as.character(x[completos]), as.character(y[completos]))
  names(dimnames(tabla)) <- c(etiqueta_x, etiqueta_y)

  vacia <- list(tabla = tabla, esperados = tabla, residuos = tabla,
                chi2 = NA_real_, gl = NA_integer_, p_valor = NA_real_,
                cramer = NA_real_, aviso = "faltan categorias para cruzar")
  if (nrow(tabla) < 2L || ncol(tabla) < 2L) return(vacia)

  prueba <- tryCatch(suppressWarnings(stats::chisq.test(tabla)),
                     error = function(e) NULL)
  if (is.null(prueba)) return(vacia)

  n <- sum(tabla)
  menor <- min(dim(tabla)) - 1L
  aviso <- if (any(prueba$expected < 5))
    "hay celdas con esperado < 5: la aproximacion ji-cuadrado se debilita"
  else NA_character_

  list(tabla = tabla, esperados = prueba$expected, residuos = prueba$stdres,
       chi2 = unname(prueba$statistic), gl = unname(prueba$parameter),
       p_valor = prueba$p.value,
       cramer = if (menor > 0) sqrt(unname(prueba$statistic) / (n * menor))
                else NA_real_,
       aviso = aviso)
}

#' Pasa la tabla a formato largo con proporciones, listo para el mosaico.
contingencia_larga <- function(cruce) {
  tabla <- cruce$tabla
  if (!length(tabla)) return(data.frame())
  largo <- as.data.frame(tabla, stringsAsFactors = FALSE)
  names(largo) <- c("fila", "columna", "n")
  largo$residuo <- as.numeric(cruce$residuos)
  largo$esperado <- as.numeric(cruce$esperados)
  largo$proporcion <- largo$n / sum(largo$n)
  largo
}

# ---------------------------------------------------------------------------
# De varias cualitativas a una matriz: lo que el ACM descompone
# ---------------------------------------------------------------------------

#' Matriz indicadora: una columna 0/1 por cada categoría de cada variable.
#'
#' Es la generalización de la tabla de contingencia a más de dos variables. Cada
#' fila tiene exactamente un 1 por variable, así que la suma de la fila es Q (el
#' número de variables) y la de una columna es la frecuencia de esa categoría.
#'
#' Las filas con faltantes se descartan: imputar una categoría es inventar una
#' respuesta que nadie dio.
#'
#' @return matriz n x J con nombres "variable=categoria", con atributo
#'   "variables" (a qué variable pertenece cada columna)
matriz_indicadora <- function(datos, columnas) {
  columnas <- intersect(columnas, names(datos))
  if (length(columnas) < 2L)
    stop("hacen falta al menos dos variables cualitativas")

  marco <- datos[, columnas, drop = FALSE]
  completas <- stats::complete.cases(marco)
  marco <- marco[completas, , drop = FALSE]
  if (!nrow(marco)) stop("ninguna fila esta completa en esas columnas")

  # Una columna con mas categorias que la mitad de las filas no es una variable
  # cualitativa, es un identificador: cada categoria tendria una o dos personas y
  # el ACM describiria filas, no asociaciones. Se mira aca y no por el tipo en
  # memoria, porque un codigo postal es numerico y es nominal.
  niveles <- vapply(marco, function(x) length(unique(x)), integer(1))
  demasiados <- niveles > max(2L, nrow(marco) %/% 2L)
  if (any(demasiados))
    stop(sprintf("estas columnas tienen casi una categoria por fila: %s",
                 paste(columnas[demasiados], collapse = ", ")))

  bloques <- lapply(columnas, function(columna) {
    valores <- factor(as.character(marco[[columna]]))
    bloque <- stats::model.matrix(~ valores - 1)
    colnames(bloque) <- paste0(columna, "=", levels(valores))
    bloque
  })

  indicadora <- do.call(cbind, bloques)
  rownames(indicadora) <- rownames(marco)
  attr(indicadora, "variables") <- rep(columnas,
                                       vapply(bloques, ncol, integer(1)))
  attr(indicadora, "filas_descartadas") <- sum(!completas)
  indicadora
}

#' Matriz de Burt: todos los cruces de las variables entre sí, en bloques.
#'
#' `t(Z) %*% Z` y nada más. En la diagonal quedan las frecuencias de cada
#' variable consigo misma; fuera de ella, las tablas de contingencia dos a dos.
#' Es el equivalente cualitativo de la matriz de varianzas y covarianzas: resume
#' la estructura de asociación sin guardar una sola fila de datos.
matriz_burt <- function(indicadora) crossprod(indicadora)
