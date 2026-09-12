# learn/R/nucleo/informe_codigos.R
#
# Responsabilidad: traducir un artefacto de la fase 1 a código R autónomo
# para el cuaderno exportado.
#
# Cada función devuelve character() de líneas que usan `datos` como nombre del
# data.frame: el cuaderno lo define una vez en "Los datos" y todos los chunks
# miran el mismo objeto. El código es base + ggplot2 a propósito: el
# estudiante debe poder ejecutarlo sin instalar nada fuera de los defaults y
# leerlo sin conocer el interior del lab.

# Entrecomilla valores de filtro: Hora = 12:00 es texto, no número.
.valores_r <- function(valores)
  paste(sprintf('"%s"', as.character(valores)), collapse = ", ")

# Qué parámetros necesita cada generador para producir código que CORRA.
#
# Sin esta tabla, un parámetro ausente no daba error: `sprintf()` con NULL
# devuelve character(0), así que la línea del `ggplot(...)` desaparecía y el
# chunk quedaba con un `+` huérfano — R roto, dentro de un cuaderno con cara de
# estar bien. Faltando algo se cae al genérico, que documenta en vez de mentir.
PARAMS_REQUERIDOS <- list(
  "f1.analisis.histograma" = "variable",
  "f1.analisis.densidad" = "variable",
  "f1.analisis.boxplot" = "variable",
  "f1.analisis.resumen" = "variable",
  "f1.analisis.boxplot_grupos" = c("variable", "grupo"),
  "f1.analisis.qq_normal_datos" = "variable",
  "f1.analisis.dispersion" = c("x", "y"),
  "f1.analisis.densidad_conjunta" = c("x", "y"),
  "f1.analisis.mosaico" = c("a", "b"),
  "f1.analisis.matriz_dispersion" = "variables",
  "f1.analisis.heatmap_correlacion" = "variables",
  "f1.analisis.coordenadas_paralelas" = "variables",
  "f1.analisis.elipsoide" = c("x", "y"),
  "f1.analisis.qq_mahalanobis" = "variables",
  "f1.calidad.atipicos" = "columna",
  "f1.balanceo.frecuencias" = "clase")

#' ¿Están los parámetros que el generador de esta clave necesita?
params_completos <- function(clave, params) {
  campos <- PARAMS_REQUERIDOS[[clave]]
  if (is.null(campos)) return(TRUE)
  todos <- vapply(campos, function(campo) {
    valor <- params[[campo]]
    !is.null(valor) && length(valor) > 0L && all(nzchar(as.character(valor)))
  }, logical(1))
  all(todos)
}

#' El código de un artefacto, elegido por su clave.
#'
#' @param params lista con los parámetros vigentes al marcar la casilla
#' @param tabla la tabla congelada del panel, cuando la clave guarda una
#'   (diccionario, frecuencias): hay código que la necesita para ser autónomo.
#' @return character() de líneas R; nunca character(0): el fallback documenta.
codigo_artefacto <- function(clave, params, tabla = NULL) {
  if (!params_completos(clave, params))
    return(c(sprintf("# %s", clave),
             .codigo_incompleto(clave, params)))
  lineas <- switch(
    clave,
    "f1.analisis.histograma" = .codigo_histograma(params),
    "f1.analisis.densidad" = .codigo_densidad(params),
    "f1.analisis.boxplot" = .codigo_boxplot(params),
    "f1.analisis.resumen" = .codigo_resumen(params),
    "f1.analisis.boxplot_grupos" = .codigo_boxplot_grupos(params),
    "f1.analisis.qq_normal_datos" = .codigo_qq(params),
    "f1.analisis.dispersion" = .codigo_dispersion(params),
    "f1.analisis.densidad_conjunta" = .codigo_densidad_conjunta(params),
    "f1.analisis.mosaico" = .codigo_mosaico(params),
    "f1.analisis.matriz_dispersion" = .codigo_pares(params),
    "f1.analisis.heatmap_correlacion" = .codigo_heatmap(params),
    "f1.analisis.coordenadas_paralelas" = .codigo_paralelas(params),
    "f1.analisis.elipsoide" = .codigo_elipsoide(params),
    "f1.analisis.qq_mahalanobis" = .codigo_qq_mahalanobis(params),
    "f1.calidad.atipicos" = .codigo_atipicos(params),
    "f1.balanceo.frecuencias" = .codigo_frecuencias(params),
    "f1.fuente.vista_previa" = .codigo_vista_previa(params),
    "f1.diccionario.tabla" = .codigo_diccionario(params, tabla),
    .codigo_generico(clave, params))
  # La clave viaja como comentario: es el puente entre el cuaderno y el lab.
  c(sprintf("# %s", clave), lineas)
}

#' La normal ajustada, como capa de una sola línea: media y desvío van inline
#' para que el chunk sea autónomo, sin variables previas.
.capa_normal_r <- function(variable)
  sprintf(paste0('  stat_function(fun = dnorm, args = list(',
                 'mean = mean(datos$%s, na.rm = TRUE), ',
                 'sd = sd(datos$%s, na.rm = TRUE)), ',
                 'color = "firebrick", linetype = "dashed") +'),
          variable, variable)

.codigo_histograma <- function(p) {
  c(sprintf("ggplot(datos, aes(x = %s)) +", p$variable),
    "  geom_histogram(aes(y = after_stat(density)),",
    sprintf("                 bins = %s, fill = \"steelblue\") +",
            p$clases %||% 30L),
    if (isTRUE(p$densidad %||% TRUE)) '  geom_density(alpha = 0.4) +' else NULL,
    if (isTRUE(p$normal)) .capa_normal_r(p$variable) else NULL,
    sprintf('  labs(x = "%s", y = "densidad")', p$variable))
}

.codigo_densidad <- function(p) {
  # Los parentesis van SIEMPRE, con banda o sin ella: `geom_density +` es un
  # error de sintaxis que solo aparece al knitear el cuaderno, no al armarlo.
  banda <- if (!is.null(p$ancho) && is.numeric(p$ancho) && p$ancho > 0)
    sprintf("bw = %s", p$ancho) else ""
  c(sprintf("ggplot(datos, aes(x = %s)) +", p$variable),
    sprintf("  geom_density(%s) +", banda),
    if (isTRUE(p$normal)) .capa_normal_r(p$variable) else NULL,
    '  labs(x = "Valor", y = "densidad")')
}

#' El resumen numérico, con la escala de medición mandando.
#'
#' `summary()` de una nominal devuelve "character" y nada más; por eso una
#' cualitativa se resume con su tabla de frecuencias y su moda. Es la misma
#' regla que apaga la media en el panel del lab, escrita en R.
.codigo_resumen <- function(p) {
  if (.es_cualitativa(p)) return(c(
    sprintf("x <- datos$%s", p$variable),
    "tabla <- sort(table(x), decreasing = TRUE)",
    "print(tabla)",
    'cat("Moda:", names(tabla)[1], "· categorías:", length(tabla),',
    '    "· faltantes:", sum(is.na(x)), "\\n")'))
  # g1 y g2 en R base, con la misma fórmula que usa el panel del lab
  # (logica/resumen_univariado.R). psych::describe() daría lo mismo; no se
  # emite para que el cuaderno no muera al knitear en una máquina donde el
  # paquete no está instalado.
  c(sprintf("x <- datos$%s", p$variable),
    "print(summary(x))",
    "v <- x[!is.na(x)]",
    "centrado <- v - mean(v)",
    "raiz <- sqrt(mean(centrado^2))",
    "asimetria <- mean(centrado^3) / raiz^3   # g1: hacia dónde va la cola",
    "curtosis <- mean(centrado^4) / raiz^4 - 3  # g2: exceso sobre la normal",
    'cat("Desviación:", round(sd(v), 4), "· RIC:", round(IQR(v), 4), "\\n")',
    'cat("Asimetría:", round(asimetria, 3),',
    '    "· Curtosis:", round(curtosis, 3), "\\n")',
    'cat("n:", length(v), "· faltantes:", sum(is.na(x)), "\\n")')
}

#' ¿La escala declarada en el diccionario hace de esta variable una cualitativa?
.es_cualitativa <- function(p)
  isTRUE((p$escala %||% "") %in% c("nominal", "ordinal")) ||
    isTRUE((p$clase %||% "") == "cualitativa")

.codigo_boxplot <- function(p)
  c(sprintf("ggplot(datos, aes(x = \"\", y = %s)) +", p$variable),
    '  geom_boxplot(fill = "steelblue", alpha = 0.5) +',
    "  coord_flip() + labs(x = NULL)")

.codigo_boxplot_grupos <- function(p)
  c(sprintf("ggplot(datos, aes(x = %s, y = %s, fill = %s)) +",
            p$grupo, p$variable, p$grupo),
    "  geom_boxplot(alpha = 0.6, show.legend = FALSE) +",
    '  theme(axis.text.x = element_text(angle = 30, hjust = 1))')

.codigo_qq <- function(p)
  c(sprintf("x <- datos$%s", p$variable),
    sprintf('qqnorm(x, main = "Q-Q normal · %s")', p$variable),
    "qqline(x, col = \"firebrick\")",
    'cat("Shapiro-Wilk:\\n"); print(shapiro.test(x))')

.codigo_dispersion <- function(p) {
  # Los tres números juntos: la covarianza lleva las unidades de las dos
  # variables, Pearson es adimensional y Spearman dice si hay relación
  # monótona donde la lineal no aparece. cor.test() agrega el p-valor.
  numeros <- c(
    sprintf('cat("Covarianza:", cov(datos$%s, datos$%s, use = "complete.obs"), "\\n")', p$x, p$y),
    sprintf('cat("Pearson:   ", cor(datos$%s, datos$%s, use = "complete.obs"), "\\n")', p$x, p$y),
    sprintf('cat("Spearman:  ", cor(datos$%s, datos$%s, use = "complete.obs",', p$x, p$y),
    '    method = "spearman"), "\\n")',
    sprintf('print(cor.test(datos$%s, datos$%s))', p$x, p$y))
  color <- if (!is.null(p$grupo) && nzchar(p$grupo))
    sprintf(", color = %s", p$grupo) else ""
  capa_puntos <- if (isTRUE(p$celdas)) "  geom_bin2d(bins = 40) +"
    else if (isTRUE(p$jitter))
      sprintf("  geom_jitter(width = 0.02, height = 0.02, alpha = %s) +",
              p$alfa %||% 0.6)
    else sprintf("  geom_point(alpha = %s) +", p$alfa %||% 0.6)
  grafico <- c(
    sprintf("grafico <- ggplot(datos, aes(x = %s, y = %s%s)) +", p$x, p$y, color),
    capa_puntos,
    if (isTRUE(p$suavizado))
      '  geom_smooth(method = "loess", formula = y ~ x, se = TRUE) +' else NULL,
    sprintf('  labs(x = "%s", y = "%s")', p$x, p$y))
  # Con marginales el dibujo lo compone ggExtra, que es la vía que sugiere el
  # enunciado del taller. El lab lo arma a mano con gtable para no sumar una
  # dependencia al bundle wasm; el cuaderno no tiene esa restricción.
  if (isTRUE(p$marginales)) return(c(
    grafico,
    'ggExtra::ggMarginal(grafico, type = "histogram", fill = "grey70",',
    '                    color = "white")',
    numeros))
  c(grafico, "grafico", numeros)
}

.codigo_densidad_conjunta <- function(p)
  c(sprintf("ggplot(datos, aes(x = %s, y = %s)) +", p$x, p$y),
    '  geom_density_2d_filled(alpha = 0.5) +',
    '  theme_minimal()')

.codigo_mosaico <- function(p)
  c(sprintf("tabla <- table(datos$%s, datos$%s)", p$a, p$b),
    'mosaicplot(tabla, shade = TRUE, las = 2,',
    sprintf('           main = "%s x %s", xlab = "%s", ylab = "%s")',
            p$a, p$b, p$a, p$b),
    'print(chisq.test(tabla))')

.codigo_pares <- function(p)
  c(sprintf("variables <- c(%s)", .valores_r(p$variables)),
    "pairs(datos[, variables], pch = 19, cex = 0.6)")

.codigo_heatmap <- function(p)
  c(sprintf("variables <- c(%s)", .valores_r(p$variables)),
    sprintf("matriz <- cor(datos[, variables], use = \"complete.obs\", method = \"%s\")",
            p$metodo %||% "pearson"),
    "heatmap(matriz, symm = TRUE, margins = c(8, 8))")

.codigo_paralelas <- function(p)
  c(sprintf("variables <- c(%s)", .valores_r(p$variables)),
    "minmax <- function(v) (v - min(v, na.rm = TRUE)) /",
    "  (max(v, na.rm = TRUE) - min(v, na.rm = TRUE))",
    "MASS::parcoord(apply(datos[, variables], 2, minmax), var.label = TRUE)")

.codigo_elipsoide <- function(p)
  c(sprintf("ggplot(datos, aes(x = %s, y = %s)) +", p$x, p$y),
    '  geom_point(alpha = 0.5) +',
    sprintf("  stat_ellipse(level = %s, type = \"norm\") +",
            p$nivel %||% 0.95),
    '  coord_equal()')

.codigo_qq_mahalanobis <- function(p)
  c(sprintf("variables <- c(%s)", .valores_r(p$variables)),
    "sub <- datos[, variables]",
    "d2 <- mahalanobis(sub, colMeans(sub, na.rm = TRUE), cov(sub))",
    "qqplot(qchisq(ppoints(nrow(sub)), df = length(variables)), d2,",
    '       xlab = "Cuantil chi-cuadrado", ylab = "Distancia de Mahalanobis")',
    'abline(0, 1, col = "firebrick")')

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
  c(sprintf("x <- datos$%s", columna),
    "# Ojo: boxplot() corta por bisagras y el panel del lab por cuartiles",
    "# (tipo 7, que es con lo que ggplot2 dibuja la caja). Las cercas pueden",
    "# diferir en décimas; el conteo de atípicos casi nunca cambia.",
    "caja <- boxplot(x, plot = FALSE)",
    "atipicos <- caja$out",
    "ric <- diff(caja$stats[c(2, 4)])",
    "cercas <- c(caja$stats[2] - 1.5 * ric, caja$stats[4] + 1.5 * ric)",
    'cat("At\u00edpicos por el criterio de Tukey:", length(atipicos),',
    '    "de", length(x), "\\n")',
    'cat("Cercas:", round(cercas, 2), "\\n")',
    "print(atipicos)",
    sprintf('boxplot(x, horizontal = TRUE, main = "%s")', columna))
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

.codigo_vista_previa <- function(p)
  c('cat("Unidades estad\u00edsticas (filas):", nrow(datos), "\\n")',
    'cat("Variables (columnas):     ", ncol(datos), "\\n")',
    'utils::head(datos, 10)')

#' Cuando faltan los parámetros, el cuaderno dice QUÉ falta en vez de emitir
#' un chunk que no corre. El que lo lea puede completarlo a mano.
.codigo_incompleto <- function(clave, params) {
  campos <- PARAMS_REQUERIDOS[[clave]]
  faltan <- campos[!vapply(campos, function(campo)
    !is.null(params[[campo]]) && length(params[[campo]]) > 0L, logical(1))]
  c("# (Este panel se exportó sin los parámetros que su código necesita.)",
    sprintf("# Falta indicar: %s", paste(faltan, collapse = ", ")),
    "# Volvé al lab, elegí las columnas y marcá la casilla de nuevo.")
}

#' Cuando no hay generador dedicado, el cuaderno no miente: documenta qué se
#' vio y con qué parámetros, y apunta a la clave para reproducirlo en el lab.
.codigo_generico <- function(clave, params) {
  c("# (Sin generador autónomo para este panel.)",
    sprintf("# Parámetros con que se produjo: %s",
            jsonlite::toJSON(params %||% list(), auto_unbox = TRUE)))
}
