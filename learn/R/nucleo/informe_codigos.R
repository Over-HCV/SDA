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
#' @return character() de líneas R; nunca character(0): el fallback documenta.
codigo_artefacto <- function(clave, params) {
  if (!params_completos(clave, params))
    return(c(sprintf("# %s", clave),
             .codigo_incompleto(clave, params)))
  lineas <- switch(
    clave,
    "f1.analisis.histograma" = .codigo_histograma(params),
    "f1.analisis.densidad" = .codigo_densidad(params),
    "f1.analisis.boxplot" = .codigo_boxplot(params),
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
    "f1.diccionario.tabla" = .codigo_diccionario(params),
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
    if (isTRUE(p$densidad)) '  geom_density(alpha = 0.4) +' else NULL,
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
    "qqnorm(x, main = \"Q-Q normal\")",
    "qqline(x, col = \"firebrick\")",
    'cat("Shapiro-Wilk:\\n"); print(shapiro.test(x))')

.codigo_dispersion <- function(p) {
  numeros <- c(
    sprintf('cat("Pearson:   ", cor(datos$%s, datos$%s, use = "complete.obs"), "\\n")', p$x, p$y),
    sprintf('cat("Covarianza:", cov(datos$%s, datos$%s, use = "complete.obs"), "\\n")', p$x, p$y))
  # Con marginales el chunk va en R base: layout() reparte la ventana en tres
  # y no hace falta ggplot2 ni ningun paquete de composicion.
  if (isTRUE(p$marginales)) return(c(
    sprintf("completos <- complete.cases(datos[, c(\"%s\", \"%s\")])", p$x, p$y),
    sprintf("x <- datos$%s[completos]; y <- datos$%s[completos]", p$x, p$y),
    "hx <- hist(x, plot = FALSE); hy <- hist(y, plot = FALSE)",
    "layout(matrix(c(2, 0, 1, 3), 2, 2, byrow = TRUE),",
    "       widths = c(4, 1), heights = c(1, 4))",
    "par(mar = c(4, 4, 1, 1))",
    sprintf('plot(x, y, pch = 19, col = "#00000099", xlab = "%s", ylab = "%s",',
            p$x, p$y),
    "     xlim = range(hx$breaks), ylim = range(hy$breaks))",
    "par(mar = c(0, 4, 1, 1))",
    "barplot(hx$counts, axes = FALSE, space = 0)",
    "par(mar = c(4, 0, 1, 1))",
    "barplot(hy$counts, axes = FALSE, space = 0, horiz = TRUE)",
    "layout(1)",
    numeros))
  color <- if (!is.null(p$grupo) && nzchar(p$grupo))
    sprintf(", color = %s", p$grupo) else ""
  c(sprintf("ggplot(datos, aes(x = %s, y = %s%s)) +", p$x, p$y, color),
    '  geom_point(alpha = 0.6)',
    numeros)
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
    'cat("Atípicos:", length(atipicos), "de", length(x), "\\n")',
    'print(atipicos)'))
  c(sprintf("x <- datos$%s", columna),
    "cuartiles <- quantile(x, c(0.25, 0.75), na.rm = TRUE)",
    "limites <- c(cuartiles[1] - 1.5 * IQR(x, na.rm = TRUE),",
    "             cuartiles[2] + 1.5 * IQR(x, na.rm = TRUE))",
    "atipicos <- x[x < limites[1] | x > limites[2]]",
    'cat("Atípicos por IQR (Tukey):", length(atipicos),',
    '    "de", length(x), "\\n")',
    'print(round(limites, 2))',
    'boxplot(x, horizontal = TRUE, main = "Caja y bigotes de Tukey")')
}

.codigo_frecuencias <- function(p)
  c(sprintf("tabla <- sort(table(datos$%s), decreasing = TRUE)", p$clase),
    'print(cbind(n = tabla, prop = round(prop.table(tabla), 3)))',
    'barplot(tabla, horiz = TRUE, las = 1, cex.names = 0.7,',
    sprintf('        main = "Frecuencias de %s")', p$clase))

#' El diccionario que el usuario declaró viaja como TABLA en la sección (es
#' estado, no cálculo). El chunk muestra lo que R infiere por su cuenta, que es
#' con lo que hay que compararlo: donde difieran, la diferencia es la decisión.
.codigo_diccionario <- function(p)
  c("str(datos)",
    'data.frame(columna = names(datos),',
    '           clase_en_R = vapply(datos, function(v) class(v)[1], ""),',
    '           distintos = vapply(datos, function(v) length(unique(v)), 0L),',
    "           row.names = NULL)")

.codigo_vista_previa <- function(p)
  c('cat("Dimensiones:", nrow(datos), "filas x", ncol(datos), "columnas\\n")',
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
