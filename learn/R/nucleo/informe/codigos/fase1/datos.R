# learn/R/nucleo/informe/codigos/fase1/datos.R
#
# Responsabilidad: el código R autónomo de los paneles que describen la base
# y su preparación (vista previa, filtro, diccionario, atípicos, frecuencias).

.codigo_atipicos <- function(p) {
  columna <- p$columna %||% p$variable
  if (identical(p$metodo %||% "iqr", "z")) return(c(
    sprintf("x <- datos$%s", columna),
    "z <- abs(x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)",
    sprintf("atipicos <- x[z > %s]", p$umbral %||% 3),
    'cat("At\u00edpicos:", length(atipicos), "de", length(x), "\\n")',
    'print(atipicos)'))
  # `boxplot(x, plot = FALSE)$out` y no quantile(): son las BISAGRAS de Tukey,
  # que con n par no coinciden con los cuartiles tipo 7 de quantile(). Es el
  # criterio que dibuja la caja, y el que pide el enunciado del taller.
  u <- p$umbral %||% 1.5
  c(sprintf("x <- datos$%s", columna),
    "# Ojo: boxplot() corta por bisagras y el panel del lab por cuartiles",
    "# (tipo 7, que es con lo que ggplot2 dibuja la caja). Las cercas pueden",
    "# diferir en décimas; el conteo de atípicos casi nunca cambia.",
    sprintf("caja <- boxplot(x, range = %s, plot = FALSE)", u),
    "atipicos <- caja$out",
    "ric <- diff(caja$stats[c(2, 4)])",
    sprintf("cercas <- c(caja$stats[2] - %s * ric, caja$stats[4] + %s * ric)", u, u),
    'cat("At\u00edpicos por el criterio de Tukey:", length(atipicos),',
    '    "de", length(x), "\\n")',
    'cat("Cercas:", round(cercas, 2), "\\n")',
    "print(atipicos)",
    sprintf('boxplot(x, range = %s, horizontal = TRUE, main = "%s")', u, columna),
    "# Las cercas, escritas donde se leen: decir si un punto quedó afuera",
    "# mirando solo el eje es justo lo que se presta a equivocarse.",
    'abline(v = cercas, lty = 2, col = "grey50")',
    'text(cercas, 1.38, labels = round(cercas, 2), cex = 0.8, col = "grey30")')
}

.codigo_frecuencias <- function(p)
  c(sprintf("tabla <- sort(table(datos$%s), decreasing = TRUE)", p$clase),
    'print(cbind(n = tabla, prop = round(prop.table(tabla), 3)))',
    'cat("M\u00e1s frecuente:  ", names(tabla)[1], " (n = ", tabla[1], ")\\n",',
    '    sep = "")',
    'cat("Menos frecuente: ", names(tabla)[length(tabla)],',
    '    " (n = ", tabla[length(tabla)], ")\\n", sep = "")',
    'barplot(tabla, horiz = TRUE, las = 1, cex.names = 0.7,',
    sprintf('        main = "Frecuencias de %s")', p$clase))

#' El diccionario que el usuario declaró viaja DENTRO del chunk, como un
#' data.frame literal: es estado, no cálculo, y así el cuaderno se sostiene
#' solo. Al lado se imprime lo que R infiere por su cuenta, que es con lo que
#' hay que compararlo: donde difieran, la diferencia es la decisión.
.codigo_diccionario <- function(p, tabla = NULL) {
  declarado <- if (is.null(tabla) || !nrow(tabla)) c(
    "# (El diccionario se exportó vacío: volvé al lab y marcá la casilla.)")
    else c("# Escala, clase y rol los declara quien analiza: R no los puede",
           "# deducir del tipo de dato (un código postal es numérico y nominal;",
           "# los grados centígrados son de intervalo, no de razón).",
           "diccionario <- data.frame(",
           .lineas_data_frame(tabla),
           ")",
           "print(diccionario)")
  c(declarado,
    "# Lo que R infiere solo, para comparar:",
    'data.frame(columna = names(datos),',
    '           clase_en_R = vapply(datos, function(v) class(v)[1], ""),',
    '           distintos = vapply(datos, function(v) length(unique(v)), 0L),',
    "           row.names = NULL)")
}

#' Cada columna de una tabla como `nombre = c("a", "b"),`, plegada a 78
#' columnas: es lo que hace que el data.frame inlineado se pueda leer y
#' corregir a mano. Con 18 variables, sin plegar son renglones de 250
#' caracteres que nadie revisa.
.lineas_data_frame <- function(tabla) {
  ultimas <- c(rep(",", ncol(tabla) - 1L), "")
  unlist(lapply(seq_along(tabla), function(i)
    .plegar_vector(names(tabla)[i], tabla[[i]], ultimas[i])), use.names = FALSE)
}

.plegar_vector <- function(nombre, valores, final) {
  piezas <- paste0(strsplit(.valores_r(valores), ", ", fixed = TRUE)[[1]], ",")
  piezas[length(piezas)] <- sub(",$", "", piezas[length(piezas)])
  lineas <- character(0)
  actual <- sprintf("  %s = c(", nombre)
  sangria <- strrep(" ", nchar(actual))
  for (pieza in piezas) {
    candidata <- if (identical(actual, sprintf("  %s = c(", nombre)))
      paste0(actual, pieza) else paste(actual, pieza)
    if (nchar(candidata) > 78L) {
      lineas <- c(lineas, actual)
      actual <- paste0(sangria, pieza)
    } else actual <- candidata
  }
  c(lineas, paste0(actual, ")", final))
}

#' Filas antes y después de la preparación. `filas_al_cargar` lo define el
#' chunk de carga, antes de la sección Preparación; acá `datos` ya está filtrado.
.codigo_filtro <- function(p)
  c('filtro <- data.frame(',
    '  estado = c("filas al cargar", "filas ahora", "filas fuera"),',
    '  cantidad = c(filas_al_cargar, nrow(datos), filas_al_cargar - nrow(datos)))',
    if (length(p$filtros) && !identical(p$filtros, "ninguno"))
      sprintf("# Filtros aplicados: %s", paste(p$filtros, collapse = "; "))
    else NULL,
    'filtro')

.codigo_vista_previa <- function(p)
  c('cat("Unidades estad\u00edsticas (filas):", nrow(datos), "\\n")',
    'cat("Variables (columnas):     ", ncol(datos), "\\n")',
    'utils::head(datos, 10)')
