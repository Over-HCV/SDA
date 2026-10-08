# learn/R/nucleo/informe/codigos/fase1/univariado.R
#
# Responsabilidad: el código R autónomo de los paneles de UNA variable de
# la fase 1 (histograma, densidad, resumen, cajas, Q-Q).
#
# Base + ggplot2 a propósito: el estudiante debe poder ejecutarlo sin
# instalar nada fuera de los defaults y leerlo sin conocer el interior del lab.

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

# Los cuartiles anotados no son adorno: son los números que el informe cita al
# describir la caja, y el panel del lab los dibuja igual (graficos/univariado.R).
.codigo_boxplot <- function(p)
  c(sprintf("cuartiles <- quantile(datos$%s, c(0.25, 0.5, 0.75))", p$variable),
    sprintf("ggplot(datos, aes(x = \"\", y = %s)) +", p$variable),
    '  geom_boxplot(fill = "steelblue", alpha = 0.5) +',
    "  annotate(\"text\", x = 1.28, y = cuartiles, size = 3,",
    "           label = format(round(cuartiles, 2), trim = TRUE)) +",
    "  coord_flip() + labs(x = NULL)")

.codigo_boxplot_grupos <- function(p)
  c(sprintf("ggplot(datos, aes(x = %s, y = %s, fill = %s)) +",
            p$grupo, p$variable, p$grupo),
    "  geom_boxplot(alpha = 0.6, show.legend = FALSE) +",
    "  stat_summary(fun = median, geom = \"text\", vjust = -0.6, size = 3,",
    "               aes(label = format(round(after_stat(y), 2),",
    "                                  trim = TRUE))) +",
    '  theme(axis.text.x = element_text(angle = 30, hjust = 1))')

.codigo_qq <- function(p)
  c(sprintf("x <- datos$%s", p$variable),
    sprintf('qqnorm(x, main = "Q-Q normal · %s")', p$variable),
    "qqline(x, col = \"firebrick\")",
    'cat("Shapiro-Wilk:\\n"); print(shapiro.test(x))')
