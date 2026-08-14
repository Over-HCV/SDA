# libs/shiny/R/modelo.R
#
# Lógica PURA de regresión (sin reactividad, sin Shiny). Este es el archivo
# que un agente puede llamar con Rscript sin levantar la app.
# Depende de: _comun (proyecto_raiz, tema_ggplot, escribir_salida).
#
# Funciones:
#   ajustar_modelo(datos, grado, metodo, semilla)  -> lista con fit, pred, r2, rmse
#   graficar_ajuste(resultado, log_y)              -> ggplot
#   diagnosticos(resultado)                        -> list(QQ, residuales, cook, leverage)
#   formatear_resumen(resultado)                   -> character (para verbatimTextOutput)

# ---------------------------------------------------------------------------
# Ajuste polinomial o loess sobre datos (x, y).
# ---------------------------------------------------------------------------
ajustar_modelo <- function(datos, grado = 3, metodo = c("lm", "loess"),
                            semilla = 42) {
  metodo <- match.arg(metodo)
  stopifnot(all(c("x", "y") %in% names(datos)))

  if (nrow(datos) < (grado + 2))
    stop("Muy pocos puntos (", nrow(datos), ") para grado=", grado)

  set.seed(semilla)

  if (metodo == "lm") {
    formula <- as.formula(sprintf("y ~ poly(x, %d, raw = TRUE)", grado))
    fit <- stats::lm(formula, data = datos)
    pred <- stats::predict(fit)
    resid <- stats::residuals(fit)
    infl <- tryCatch(stats::influence.measures(fit), error = function(e) NULL)
    cooks <- if (!is.null(infl))
              infl$infmat[, "cook.d", drop = TRUE] else rep(NA_real_, nrow(datos))
    hat   <- if (!is.null(infl))
              infl$infmat[, "hat", drop = TRUE]   else rep(NA_real_, nrow(datos))
    r2    <- summary(fit)$r.squared
    rmse  <- sqrt(mean(resid^2))
    coefs <- stats::coef(fit)
  } else {
    span <- max(0.3, 30 / nrow(datos))
    fit <- stats::loess(y ~ x, data = datos,
                        degree = min(grado, 2), span = span)
    pred <- stats::predict(fit)
    resid <- stats::residuals(fit)
    cooks <- hat <- rep(NA_real_, nrow(datos))
    r2 <- cor(datos$y, pred, use = "complete.obs")^2
    rmse <- sqrt(mean(resid^2, na.rm = TRUE))
    coefs <- NULL
  }

  list(
    fit    = fit,
    metodo = metodo,
    grado  = grado,
    semilla = semilla,
    datos  = datos,
    pred   = pred,
    resid  = resid,
    cooks  = cooks,
    hat    = hat,
    r2     = r2,
    rmse   = rmse,
    coefs  = coefs,
    n      = nrow(datos)
  )
}

# ---------------------------------------------------------------------------
# Plot principal: puntos + curva ajustada, métricas en subtítulo.
# ---------------------------------------------------------------------------
graficar_ajuste <- function(res, log_y = FALSE) {
  d <- res$datos
  d$pred <- res$pred
  d$resid <- res$resid

  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y)) +
    ggplot2::geom_point(alpha = 0.55, color = "#0072B2", size = 2) +
    ggplot2::geom_line(ggplot2::aes(y = .data$pred),
                       color = "#D55E00", linewidth = 1) +
    ggplot2::labs(
      title    = sprintf("Ajuste %s (grado = %d)", res$metodo, res$grado),
      subtitle = sprintf("R² = %.3f   RMSE = %.3f   n = %d",
                         res$r2, res$rmse, res$n),
      x = "Año", y = "Cantidad",
      caption = "Puntos: datos observados. Línea naranja: modelo ajustado."
    ) +
    tema_ggplot()

  if (log_y) p <- p + ggplot2::scale_y_log10()
  p
}

# ---------------------------------------------------------------------------
# Cuatro gráficos de diagnóstico, devueltos como lista de ggplot.
# ---------------------------------------------------------------------------
diagnosticos <- function(res) {
  d <- data.frame(
    x     = res$datos$x,
    pred  = as.numeric(res$pred),
    resid = as.numeric(res$resid),
    cooks = res$cooks,
    hat   = res$hat
  )

  qq <- ggplot2::ggplot(d, ggplot2::aes(sample = .data$resid)) +
    ggplot2::stat_qq(alpha = 0.6, color = "#0072B2") +
    ggplot2::stat_qq_line(color = "#D55E00") +
    ggplot2::labs(title = "QQ de residuales", x = "Teórico", y = "Muestra") +
    tema_ggplot()

  rvf <- ggplot2::ggplot(d, ggplot2::aes(.data$pred, .data$resid)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey60", linetype = 2) +
    ggplot2::geom_point(alpha = 0.6, color = "#0072B2") +
    ggplot2::labs(title = "Residuales vs ajuste",
                  x = "Valor ajustado", y = "Residual") +
    tema_ggplot()

  if (all(is.na(d$cooks))) {
    cook_p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 0.5, y = 0.5,
                        label = "Distancia de Cook no disponible\n(método loess)") +
      ggplot2::theme_void()
  } else {
    cook_p <- ggplot2::ggplot(d, ggplot2::aes(seq_along(.data$cooks), .data$cooks)) +
      ggplot2::geom_col(fill = "#0072B2", alpha = 0.7) +
      ggplot2::geom_hline(yintercept = 4 / nrow(d),
                          color = "#D55E00", linetype = 2) +
      ggplot2::labs(title = "Distancia de Cook",
                    x = "Índice", y = "Cook's D") +
      tema_ggplot()
  }

  if (all(is.na(d$hat))) {
    lev_p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 0.5, y = 0.5,
                        label = "Leverage no disponible\n(método loess)") +
      ggplot2::theme_void()
  } else {
    lev_p <- ggplot2::ggplot(d, ggplot2::aes(.data$hat, .data$resid)) +
      ggplot2::geom_point(alpha = 0.6, color = "#0072B2") +
      ggplot2::labs(title = "Residuales vs leverage",
                    x = "Leverage", y = "Residual estandarizado") +
      tema_ggplot()
  }

  list(qq = qq, rvf = rvf, cook = cook_p, leverage = lev_p)
}

# ---------------------------------------------------------------------------
# Texto formateado para el panel "Resumen" (model summary legible).
# ---------------------------------------------------------------------------
formatear_resumen <- function(res) {
  if (res$metodo == "lm") {
    s <- summary(res$fit)
    withr::with_options(list(width = 80), {
      out <- capture.output(print(s))
    })
    c(out, "",
      sprintf("R² = %.4f   RMSE = %.4f   n = %d   grado = %d",
              res$r2, res$rmse, res$n, res$grado))
  } else {
    c(sprintf("Método: loess (grado %d, span derivado)", res$grado),
      "",
      sprintf("Correlación pred/obs (pseudo-R²): %.4f", res$r2),
      sprintf("RMSE: %.4f", res$rmse),
      sprintf("n = %d", res$n))
  }
}
