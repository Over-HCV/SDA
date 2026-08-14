# projects/01-lasso/R/modelo.R
#
# Logica PURA del tema "Seleccion de variables con penalizacion LASSO"
# (fila 23 de libs/topics-map.md).
#
# INVARIANTE del proyecto: aqui no hay `input`, ni `reactive`, ni `session`.
# Todo entra como valores planos y sale como listas/data.frames, para que
# run_headless.R pueda ejecutar exactamente lo mismo que la app.
#
# Funciones expuestas:
#   correr_lasso()     -> ajuste glmnet + CV + metricas al lambda pedido
#   graficar_camino()  -> camino de coeficientes con la linea del lambda actual
#   graficar_cv()      -> curva de validacion cruzada (lambda.min / lambda.1se)
#   tabla_coefs()      -> data.frame de coeficientes al lambda actual
#   graficar_ajuste()  -> observado vs predicho (el plot "principal" del S2)

suppressPackageStartupMessages(library(glmnet))

# Predictores por defecto: todo menos la respuesta y los salarios crudos
# (HRWAGEH/HRWAGEL construyen DLHRWAGE, meterlos seria fuga de informacion).
LASSO_Y_DEFECTO <- "DLHRWAGE"
LASSO_X_DEFECTO <- c("DEDUC1", "DEDUC2", "AGE", "AGESQ", "DTEN",
                     "DMARRIED", "DUNCOV", "EDUCH", "EDUCL",
                     "WHITEH", "WHITEL", "MALEH", "MALEL")

# ---------------------------------------------------------------------------
# Ajuste principal.
#
#   df       : data.frame con la respuesta y los predictores
#   y_var    : nombre de la respuesta
#   x_vars   : nombres de los predictores
#   alpha    : 1 = LASSO, 0 = ridge, intermedio = elastic net
#   lambda   : penalizacion a evaluar. NULL = usar lambda.1se del CV.
#   nfolds   : folds del CV
#   semilla  : el CV parte los folds al azar; sin semilla no es reproducible
#
# Devuelve una lista con el fit completo, el CV, y las metricas AL LAMBDA
# elegido (no al optimo), porque es ese lambda el que el usuario mueve.
# ---------------------------------------------------------------------------
correr_lasso <- function(df,
                          y_var  = LASSO_Y_DEFECTO,
                          x_vars = LASSO_X_DEFECTO,
                          alpha  = 1,
                          lambda = NULL,
                          nfolds = 10,
                          semilla = 42,
                          estandarizar = TRUE) {

  stopifnot(is.data.frame(df), length(x_vars) >= 2)
  faltan <- setdiff(c(y_var, x_vars), names(df))
  if (length(faltan))
    stop("Columnas ausentes: ", paste(faltan, collapse = ", "))

  # glmnet no acepta NA: nos quedamos con casos completos en las columnas
  # que realmente usamos (no en todo el data.frame).
  d <- df[, c(y_var, x_vars), drop = FALSE]
  d <- d[stats::complete.cases(d), , drop = FALSE]

  if (nrow(d) < 20)
    stop("Muy pocos casos completos (", nrow(d), ") para ajustar.")

  y <- as.numeric(d[[y_var]])
  X <- as.matrix(d[, x_vars, drop = FALSE])

  # Predictores constantes rompen la estandarizacion de glmnet.
  sd_col <- apply(X, 2, stats::sd)
  constantes <- names(sd_col)[!is.finite(sd_col) | sd_col == 0]
  if (length(constantes)) {
    X <- X[, setdiff(colnames(X), constantes), drop = FALSE]
    x_vars <- setdiff(x_vars, constantes)
  }
  if (ncol(X) < 2) stop("Quedaron menos de 2 predictores con varianza.")

  set.seed(semilla)

  fit <- glmnet::glmnet(X, y, alpha = alpha, standardize = estandarizar)
  cvfit <- glmnet::cv.glmnet(X, y, alpha = alpha, nfolds = nfolds,
                             standardize = estandarizar)

  # Lambda efectivo: el que pidieron, o el 1se del CV (mas parsimonioso que
  # el min, y el que se suele reportar).
  lambda_usado <- if (is.null(lambda)) cvfit$lambda.1se else lambda
  lambda_usado <- max(lambda_usado, min(fit$lambda))

  pred <- as.numeric(stats::predict(fit, newx = X, s = lambda_usado))
  resid <- y - pred

  co <- as.matrix(stats::coef(fit, s = lambda_usado))
  coefs <- stats::setNames(as.numeric(co), rownames(co))

  # R2 dentro de muestra. OJO: con regularizacion no es una medida de ajuste
  # honesta (no hay grados de libertad claros); se muestra como referencia
  # descriptiva, y el CV es el que manda para elegir lambda.
  ss_tot <- sum((y - mean(y))^2)
  ss_res <- sum(resid^2)
  r2 <- if (ss_tot > 0) 1 - ss_res / ss_tot else NA_real_

  no_cero <- sum(coefs[names(coefs) != "(Intercept)"] != 0)

  list(
    fit      = fit,
    cvfit    = cvfit,
    X = X, y = y,
    y_var = y_var, x_vars = x_vars,
    alpha = alpha, nfolds = nfolds, semilla = semilla,
    lambda      = lambda_usado,
    lambda_min  = cvfit$lambda.min,
    lambda_1se  = cvfit$lambda.1se,
    coefs   = coefs,
    no_cero = no_cero,
    pred = pred, resid = resid,
    r2   = r2,
    rmse = sqrt(mean(resid^2)),
    n    = nrow(X),
    p    = ncol(X),
    # El error de CV en el lambda elegido: la metrica honesta.
    cv_error = .cv_en_lambda(cvfit, lambda_usado),
    descartados = constantes
  )
}

# Interpola el error de CV en el lambda mas cercano de la grilla del cv.glmnet.
.cv_en_lambda <- function(cvfit, lambda) {
  i <- which.min(abs(cvfit$lambda - lambda))
  as.numeric(cvfit$cvm[i])
}

# ---------------------------------------------------------------------------
# Camino de coeficientes. Es EL grafico del tema: al mover lambda se ve como
# cada coeficiente se apaga.
# ---------------------------------------------------------------------------
graficar_camino <- function(res) {
  beta <- as.matrix(res$fit$beta)          # p x n_lambda
  lam  <- res$fit$lambda

  largo <- data.frame(
    variable = rep(rownames(beta), times = ncol(beta)),
    lambda   = rep(lam, each = nrow(beta)),
    coef     = as.numeric(beta),
    stringsAsFactors = FALSE
  )

  activos <- names(res$coefs)[names(res$coefs) != "(Intercept)" &
                                res$coefs != 0]

  p <- ggplot2::ggplot(largo,
                       ggplot2::aes(x = log(lambda), y = coef, group = variable)) +
    ggplot2::geom_line(ggplot2::aes(color = variable %in% activos),
                       linewidth = 0.7, alpha = 0.9) +
    ggplot2::scale_color_manual(
      values = c(`TRUE` = "#c0392b", `FALSE` = "grey70"),
      labels = c(`TRUE` = "activo", `FALSE` = "anulado"),
      name = NULL
    ) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.4) +
    # Las tres verticales: donde estas, y las dos referencias del CV.
    ggplot2::geom_vline(xintercept = log(res$lambda),
                        linewidth = 1, color = "#c0392b") +
    ggplot2::geom_vline(xintercept = log(res$lambda_min),
                        linetype = "dashed", color = "#2980b9") +
    ggplot2::geom_vline(xintercept = log(res$lambda_1se),
                        linetype = "dotted", color = "#27ae60") +
    ggplot2::labs(
      title = sprintf("Camino de coeficientes (alpha = %.2f)", res$alpha),
      subtitle = sprintf(
        "lambda = %.5f | activos = %d de %d\nrojo = actual · azul = lambda.min · verde = lambda.1se",
        res$lambda, res$no_cero, res$p),
      x = "log(lambda)", y = "coeficiente"
    )

  if (exists("tema_ggplot", mode = "function")) p <- p + tema_ggplot()
  p
}

# ---------------------------------------------------------------------------
# Curva de validacion cruzada.
# ---------------------------------------------------------------------------
graficar_cv <- function(res) {
  cv <- res$cvfit
  d <- data.frame(lambda = cv$lambda, cvm = cv$cvm,
                  lo = cv$cvlo, hi = cv$cvup)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = log(lambda), y = cvm)) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = lo, ymax = hi),
                           color = "grey75", width = 0) +
    ggplot2::geom_point(color = "#c0392b", size = 1.6) +
    ggplot2::geom_vline(xintercept = log(res$lambda),
                        linewidth = 1, color = "#c0392b") +
    ggplot2::geom_vline(xintercept = log(res$lambda_min),
                        linetype = "dashed", color = "#2980b9") +
    ggplot2::geom_vline(xintercept = log(res$lambda_1se),
                        linetype = "dotted", color = "#27ae60") +
    ggplot2::labs(
      title = sprintf("Error de validacion cruzada (%d folds)", res$nfolds),
      subtitle = sprintf("MSE de CV en lambda actual = %.4f", res$cv_error),
      x = "log(lambda)", y = "MSE de CV"
    )

  if (exists("tema_ggplot", mode = "function")) p <- p + tema_ggplot()
  p
}

# ---------------------------------------------------------------------------
# Observado vs predicho. Es el plot principal que va al PNG del contrato S2.
# ---------------------------------------------------------------------------
graficar_ajuste <- function(res) {
  d <- data.frame(observado = res$y, predicho = res$pred)

  p <- ggplot2::ggplot(d, ggplot2::aes(x = predicho, y = observado)) +
    ggplot2::geom_abline(slope = 1, intercept = 0,
                         linetype = "dashed", color = "grey50") +
    ggplot2::geom_point(alpha = 0.65, size = 2.2, color = "#c0392b") +
    ggplot2::labs(
      title = sprintf("Observado vs predicho — %s", res$y_var),
      subtitle = sprintf(
        "alpha = %.2f | lambda = %.5f | %d predictores activos | R2 = %.3f | RMSE = %.3f | n = %d",
        res$alpha, res$lambda, res$no_cero, res$r2, res$rmse, res$n),
      x = "predicho", y = "observado"
    )

  if (exists("tema_ggplot", mode = "function")) p <- p + tema_ggplot()
  p
}

# ---------------------------------------------------------------------------
# Tabla de coeficientes al lambda actual, ordenada por magnitud.
# ---------------------------------------------------------------------------
tabla_coefs <- function(res, incluir_ceros = TRUE) {
  co <- res$coefs
  d <- data.frame(
    variable = names(co),
    coef     = as.numeric(co),
    stringsAsFactors = FALSE
  )
  d$activo <- ifelse(d$coef != 0, "si", "no")
  d$abs <- abs(d$coef)
  d <- d[order(-d$abs), ]
  d$abs <- NULL
  if (!incluir_ceros) d <- d[d$coef != 0, , drop = FALSE]
  rownames(d) <- NULL
  d
}
