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
