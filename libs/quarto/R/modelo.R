# libs/quarto/R/modelo.R
#
# Lógica PURA de PCA y k-means sobre una matriz genérica. Sin reactividad,
# sin UI, sin I/O. Un agente puede llamarla con Rscript.
# Depende de: stats (prcomp, kmeans). Nada más.
#
# Funciones:
#   calcular_pca(mat, n_pcs)        -> list(scores, rotation, sdev, var_pct,
#                                           cum_pct, obs_names, var_names)
#   agrupar_kmeans(mat, k_range)    -> list(resultados, tot_withinss,
#                                           obs_names, k_range)

# ---------------------------------------------------------------------------
# PCA genérico. Estandariza (scale.=TRUE) antes de proyectar.
#   mat    = matriz numérica (filas = obs, cols = variables).
#   n_pcs  = nº de PCs a devolver (recortado al rango válido).
# ---------------------------------------------------------------------------
calcular_pca <- function(mat, n_pcs = 4) {
  stopifnot(is.matrix(mat), is.numeric(mat))
  n_pcs <- min(n_pcs, min(nrow(mat), ncol(mat)) - 1)
  n_pcs <- max(n_pcs, 1)

  # scale.=TRUE => cada columna con var=1 (corr matrix). center por defecto.
  pc <- stats::prcomp(mat, scale. = TRUE, center = TRUE)

  sdev  <- pc$sdev[seq_len(n_pcs)]
  var_pct <- (sdev^2 / sum(pc$sdev^2)) * 100
  cum_pct <- cumsum(var_pct)

  scores   <- pc$x[,       seq_len(n_pcs), drop = FALSE]
  rotation <- pc$rotation[, seq_len(n_pcs), drop = FALSE]

  # Nombrar PC1..PCn de forma estable
  pc_nms <- paste0("PC", seq_len(n_pcs))
  colnames(scores)   <- pc_nms
  colnames(rotation) <- pc_nms
  names(sdev) <- names(var_pct) <- names(cum_pct) <- pc_nms

  list(
    scores    = scores,
    rotation  = rotation,
    sdev      = sdev,
    var_pct   = var_pct,
    cum_pct   = cum_pct,
    obs_names = rownames(mat) %||% as.character(seq_len(nrow(mat))),
    var_names = colnames(mat) %||% paste0("V", seq_len(ncol(mat))),
    n_pcs     = n_pcs
  )
}

# Atajo null-coalesce (compatible con R < 4.4 que no trae %||% nativo).
`%||%` <- function(a, b) if (is.null(a)) b else a

# ---------------------------------------------------------------------------
# k-means para un rango de k. Estandariza mat primero (consistencia con PCA).
# Devuelve resultados por k + tot.withinss por k (para curva del codo).
# ---------------------------------------------------------------------------
agrupar_kmeans <- function(mat, k_range = 2:10, nstart = 25, semilla = 42) {
  stopifnot(is.matrix(mat), is.numeric(mat))
  k_range <- k_range[k_range >= 2 & k_range <= nrow(mat) - 1]
  if (!length(k_range)) stop("k_range inválido para n=", nrow(mat))

  z <- scale(mat, center = TRUE, scale = TRUE)

  set.seed(semilla)
  resultados <- lapply(k_range, function(k) {
    fit <- stats::kmeans(z, centers = k, nstart = nstart)
    list(
      cluster   = fit$cluster,
      withinss  = fit$withinss,
      centers   = fit$centers,
      tot_withinss = fit$tot.withinss,
      k         = k
    )
  })
  names(resultados) <- paste0("k", k_range)

  tot_withinss <- vapply(resultados, function(r) r$tot_withinss, numeric(1))
  names(tot_withinss) <- as.character(k_range)

  list(
    resultados    = resultados,
    obs_names     = rownames(mat) %||% as.character(seq_len(nrow(mat))),
    k_range       = k_range,
    tot_withinss  = tot_withinss,
    semilla       = semilla
  )
}
