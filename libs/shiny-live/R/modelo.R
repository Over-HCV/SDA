# libs/shiny-live/R/modelo.R
#
# Lógica PURA de ANOVA one-way (sin reactividad, sin Shiny). Un agente puede
# llamar estas funciones con Rscript sin levantar la app.
# Depende de: _comun (tema_ggplot, paleta_cat, gen_sintetico, escribir_salida).
#
# Funciones:
#   correr_anova(datos, semilla)            -> lista (fit, F, p, tests, residuales)
#   graficar_qq(res)                        -> ggplot (QQ de residuales)
#   graficar_boxplot(res)                   -> ggplot (boxplot por grupo + jitter + media)
#   graficar_hist(res)                      -> ggplot (hist de residuales + curva normal)
#   formatear_resumen_anova(res)            -> character (para verbatimTextOutput)
#   potencia_simulada(ns, efectos, ...)     -> data.frame(n, efecto, potencia)
#   graficar_potencia(df)                   -> ggplot heatmap de potencia
#
# webR: NO usar broom/car/moments/pwr. Todo a mano (stats:: + aritmética).

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---------------------------------------------------------------------------
# Helpers a mano (stats:: + aritmética base). Sin paquetes extra.
# ---------------------------------------------------------------------------
skewness_a_mano <- function(x) {
  x <- x[is.finite(x)]; n <- length(x)
  if (n < 3) return(NA_real_)
  m <- mean(x); s <- stats::sd(x)
  if (s == 0) return(NA_real_)
  sum((x - m)^3) / n / s^3
}

kurtosis_a_mano <- function(x) {
  x <- x[is.finite(x)]; n <- length(x)
  if (n < 4) return(NA_real_)
  m <- mean(x); s <- stats::sd(x)
  if (s == 0) return(NA_real_)
  sum((x - m)^4) / n / s^4 - 3  # exceso de curtosis (Fisher)
}

# Levene clásico (median-centered): ANOVA sobre |valor - mediana del grupo|.
levene_a_mano <- function(datos) {
  ok <- !is.na(datos$valor) & !is.na(datos$grupo)
  datos <- datos[ok, , drop = FALSE]
  if (length(unique(datos$grupo)) < 2 || nrow(datos) < 3)
    return(list(stat = NA_real_, p = NA_real_))
  med <- tapply(datos$valor, datos$grupo, stats::median, na.rm = TRUE)
  desv <- abs(datos$valor - med[as.character(datos$grupo)])
  fit <- stats::aov(desv ~ datos$grupo)
  tab <- summary(fit)[[1]]
  list(stat = unname(tab[["F value"]][1]),
       p   = unname(tab[["Pr(>F)"]][1]))
}

# ---------------------------------------------------------------------------
# ANOVA one-way. Devuelve lista completa para que todos los módulos consuman
# sin recalcular.
# ---------------------------------------------------------------------------
correr_anova <- function(datos, semilla = 42) {
  set.seed(semilla)
  stopifnot(all(c("valor", "grupo") %in% names(datos)))
  datos <- datos[is.finite(datos$valor) & !is.na(datos$grupo), , drop = FALSE]
  datos$grupo <- factor(datos$grupo)
  n <- nrow(datos); k <- length(levels(datos$grupo))

  if (n < 3 || k < 2) {
    return(list(fit = NULL, F = NA_real_, p = NA_real_,
                gl_entre = NA_integer_, gl_intra = NA_integer_, MSE = NA_real_,
                medias_grupo = stats::setNames(rep(NA_real_, k), levels(datos$grupo)),
                residuals = datos$valor, shapiro_stat = NA_real_, shapiro_p = NA_real_,
                levene_stat = NA_real_, levene_p = NA_real_,
                bartlett_stat = NA_real_, bartlett_p = NA_real_,
                skewness = NA_real_, kurtosis = NA_real_,
                datos = datos, grupos = levels(datos$grupo), n = n))
  }

  fit <- stats::aov(valor ~ grupo, data = datos)
  tab <- summary(fit)[[1]]
  resid <- c(stats::residuals(fit))
  sh <- tryCatch(stats::shapiro.test(resid),
                 error = function(e) list(statistic = NA_real_, p.value = NA_real_))
  bart <- tryCatch(stats::bartlett.test(valor ~ grupo, data = datos),
                   error = function(e) list(statistic = NA_real_, p.value = NA_real_))
  lev <- levene_a_mano(datos)

  list(
    fit = fit,
    F = unname(tab[["F value"]][1]),
    p = unname(tab[["Pr(>F)"]][1]),
    gl_entre = unname(tab[["Df"]][1]),
    gl_intra = unname(tab[["Df"]][2]),
    MSE = unname(tab[["Mean Sq"]][2]),
    medias_grupo = tapply(datos$valor, datos$grupo, mean, na.rm = TRUE),
    residuals = resid,
    shapiro_stat = unname(sh$statistic), shapiro_p = unname(sh$p.value),
    levene_stat = lev$stat, levene_p = lev$p,
    bartlett_stat = unname(bart$statistic), bartlett_p = unname(bart$p.value),
    skewness = skewness_a_mano(resid),
    kurtosis = kurtosis_a_mano(resid),
    datos = datos, grupos = levels(datos$grupo), n = n
  )
}

# ---------------------------------------------------------------------------
# Plots (ggplot2 + tema_ggplot de _comun).
# ---------------------------------------------------------------------------
graficar_qq <- function(res) {
  bootstrap_comun()
  d <- data.frame(resid = res$residuals)
  ggplot2::ggplot(d, ggplot2::aes(sample = .data$resid)) +
    ggplot2::stat_qq(alpha = 0.55, color = "#0072B2", size = 2) +
    ggplot2::stat_qq_line(color = "#D55E00", linewidth = 0.8) +
    ggplot2::labs(title = "QQ de residuales",
                  subtitle = sprintf("Shapiro W = %.3f (p = %.4g)",
                                     res$shapiro_stat, res$shapiro_p),
                  x = "Teórico", y = "Muestra") +
    tema_ggplot()
}

graficar_boxplot <- function(res) {
  bootstrap_comun()
  d <- res$datos
  k <- length(levels(d$grupo))
  ggplot2::ggplot(d, ggplot2::aes(.data$grupo, .data$valor, fill = .data$grupo)) +
    ggplot2::geom_boxplot(outlier.shape = NA, alpha = 0.55) +
    ggplot2::geom_jitter(width = 0.18, alpha = 0.35, size = 1.4) +
    ggplot2::stat_summary(fun = mean, geom = "point", shape = 23,
                          size = 3.2, fill = "white", color = "black") +
    ggplot2::labs(title = "Boxplot por grupo",
                  subtitle = sprintf("F = %.2f, p = %.4g (n = %d)", res$F, res$p, res$n),
                  x = "Grupo", y = "Valor", fill = "Grupo") +
    scale_fill_cat(k) + tema_ggplot() +
    ggplot2::theme(legend.position = "none",
                   axis.text.x = ggplot2::element_text(angle = 25, hjust = 1))
}

graficar_hist <- function(res) {
  bootstrap_comun()
  d <- data.frame(resid = res$residuals)
  m <- mean(d$resid); s <- stats::sd(d$resid)
  ggplot2::ggplot(d, ggplot2::aes(.data$resid)) +
    ggplot2::geom_histogram(ggplot2::aes(y = ggplot2::after_stat(.data$density)),
                            bins = 25, fill = "#0072B2", alpha = 0.5, color = "white") +
    ggplot2::stat_function(fun = function(x) stats::dnorm(x, m, s),
                           color = "#D55E00", linewidth = 0.9) +
    ggplot2::labs(title = "Histograma de residuales",
                  subtitle = sprintf("Asimetría = %.3f   Curtosis (exceso) = %.3f",
                                     res$skewness, res$kurtosis),
                  x = "Residual", y = "Densidad") +
    tema_ggplot()
}

# ---------------------------------------------------------------------------
# Texto para verbatimTextOutput: summary(aov) legible + métricas clave.
# ---------------------------------------------------------------------------
formatear_resumen_anova <- function(res) {
  if (is.null(res$fit)) {
    return(c("ANOVA no calculable (datos insuficientes o <2 grupos)."))
  }
  out <- capture.output(print(summary(res$fit)))
  c(out, "",
    sprintf("n total = %d   grupos = %d   gl_entre = %d   gl_intra = %d",
            res$n, length(res$grupos), res$gl_entre, res$gl_intra),
    sprintf("MSE = %.4f", res$MSE),
    "",
    "Supuestos:",
    sprintf("  Shapiro (normalidad):  W = %.4f, p = %.4g",
            res$shapiro_stat, res$shapiro_p),
    sprintf("  Levene (homocedastic.): F = %.4f, p = %.4g",
            res$levene_stat, res$levene_p),
    sprintf("  Bartlett:              χ² = %.4f, p = %.4g",
            res$bartlett_stat, res$bartlett_p),
    sprintf("  Asimetría = %.3f   Curtosis = %.3f", res$skewness, res$kurtosis))
}

# ---------------------------------------------------------------------------
# Potencia simulada: para una grilla de (n, efecto), correr N_sim ANOVAs y
# contar la fracción con p < 0.05. Sustituye a pwr::pwr.anova.test (no bundled).
# Camino rápido: solo extrae el p-value del aov (sin Shapiro/Levene).
# ---------------------------------------------------------------------------
potencia_simulada <- function(ns = c(10, 20, 30, 50, 100),
                              efectos = seq(0, 20, by = 2),
                              k_grupos = 3, ruido = 1,
                              N_sim = 50, semilla = 42) {
  bootstrap_comun()
  grid <- expand.grid(efecto = efectos, n = ns, potencia = NA_real_,
                       stringsAsFactors = FALSE)
  for (i in seq_len(nrow(grid))) {
    n <- grid$n[i]; ef <- grid$efecto[i]
    sig <- 0L
    for (sim in seq_len(N_sim)) {
      d <- gen_sintetico(n = n, k_grupos = k_grupos, efecto = ef, ruido = ruido,
                         semilla = semilla + sim * 997 + i, tipo = "anova")
      fit <- stats::aov(valor ~ grupo, data = d)
      p <- summary(fit)[[1]][["Pr(>F)"]][1]
      if (!is.na(p) && p < 0.05) sig <- sig + 1L
    }
    grid$potencia[i] <- sig / N_sim
  }
  grid
}

graficar_potencia <- function(df) {
  bootstrap_comun()
  ggplot2::ggplot(df, ggplot2::aes(.data$efecto, factor(.data$n),
                                    fill = .data$potencia)) +
    ggplot2::geom_raster() +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", .data$potencia)),
                       size = 3, color = "white") +
    ggplot2::scale_fill_gradient(low = "#0072B2", high = "#D55E00",
                                  limits = c(0, 1), name = "Potencia") +
    ggplot2::labs(title = "Potencia simulada (fracción con p < 0.05)",
                  subtitle = "Filas: n por grupo. Columnas: tamaño del efecto.",
                  x = "Efecto (diferencia de medias)", y = "n por grupo") +
    tema_ggplot()
}
