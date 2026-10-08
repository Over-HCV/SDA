# learn/R/nucleo/informe/codigos/fase1/multivariado.R
#
# Responsabilidad: el código R autónomo de los paneles de DOS o más variables
# de la fase 1 (dispersión, mosaico, pares, correlaciones, Mahalanobis).

.codigo_dispersion <- function(p) {
  # Los tres números juntos: la covarianza lleva las unidades de las dos
  # variables, Pearson es adimensional y Spearman dice si hay relación
  # monótona donde la lineal no aparece. cor.test() agrega el p-valor.
  numeros <- c(
    sprintf('cat("Covarianza:", cov(datos$%s, datos$%s, use = "complete.obs"), "\\n")', p$x, p$y),
    sprintf('cat("Pearson:   ", cor(datos$%s, datos$%s, use = "complete.obs"), "\\n")', p$x, p$y),
    sprintf('cat("Spearman:  ", cor(datos$%s, datos$%s, use = "complete.obs",', p$x, p$y),
    '    method = "spearman"), "\\n")',
    sprintf('print(cor.test(datos$%s, datos$%s))', p$x, p$y),
    if (isTRUE(p$regresion))
      sprintf('print(summary(lm(%s ~ %s, data = datos)))', p$y, p$x) else NULL)
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
    if (isTRUE(p$regresion))
      '  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "firebrick") +'
    else NULL,
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
