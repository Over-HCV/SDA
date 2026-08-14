# libs/quarto/R/precomputo.R
#
# Vuelca los 8 CSVs + 2 JSONs de PCA y clustering para charcoal y twins.
# Idempotente: si los 8 CSVs ya existen y force=FALSE, no recomputa.
#
# Schema de archivos en libs/quarto/outputs/:
#   <ds>_pca.csv        WIDE: obs, PC1, PC2, PC3, PC4
#   <ds>_rotation.csv   variable, PC1, PC2, PC3, PC4
#   <ds>_var.csv        PC, var_pct, cum_pct
#   <ds>_clusters.csv   LONG: obs, k, cluster
#   <ds>_codo.csv       k, tot_withinss  (curva del codo)
#   <ds>-precomputo.json  schema S2 vía escribir_salida()
#
# Dependencias: modelo.R (calcular_pca, agrupar_kmeans), datos.R,
#               _comun/metricas.R (escribir_salida).

DATASETS <- c("charcoal", "twins")
N_PCS    <- 4
K_RANGE  <- 2:10

# ---------------------------------------------------------------------------
# Lista de los 8 ficheros esperados (para chequeo de idempotencia).
# ---------------------------------------------------------------------------
.csv_esperados <- function(out_dir) {
  c(unlist(lapply(DATASETS, function(ds)
    paste0(ds, c("_pca.csv","_rotation.csv","_var.csv","_clusters.csv","_codo.csv")))))
}

.ya_existe <- function(out_dir) {
  todos <- file.path(out_dir, .csv_esperados(out_dir))
  all(file.exists(todos))
}

# ---------------------------------------------------------------------------
# precomputo(force = FALSE): devuelve invisiblemente la lista de paths.
# ---------------------------------------------------------------------------
precomputo <- function(force = FALSE, out_dir = "libs/quarto/outputs",
                       n_pcs = N_PCS, k_range = K_RANGE, semilla = 42) {
  raiz <- proyecto_raiz()
  out_abs <- file.path(raiz, out_dir)
  if (!dir.exists(out_abs)) dir.create(out_abs, recursive = TRUE)

  if (.ya_existe(out_abs) && !force) {
    cat("[precomputo] outputs ya existen; use force=TRUE para regenerar.\n")
    return(invisible(list(out_dir = out_abs, datasets = DATASETS)))
  }

  out_paths <- list()
  for (ds in DATASETS) {
    mat <- construir_matriz(dataset = ds)
    pca <- calcular_pca(mat, n_pcs = n_pcs)
    km  <- agrupar_kmeans(mat, k_range = k_range, semilla = semilla)

    out_paths[[ds]] <- .volcar_dataset(ds, pca, km, out_abs, semilla)
  }

  invisible(list(out_dir = out_abs, datasets = DATASETS, paths = out_paths))
}

# ---------------------------------------------------------------------------
# Vuelca los 4 CSVs + 1 JSON de un dataset. Helper interno.
# ---------------------------------------------------------------------------
.volcar_dataset <- function(ds, pca, km, out_abs, semilla) {
  pc_cols <- colnames(pca$scores)

  # --- PCA (WIDE) ---
  pca_df <- as.data.frame(pca$scores)
  pca_df <- cbind(obs = pca$obs_names, pca_df)
  pca_path <- file.path(out_abs, paste0(ds, "_pca.csv"))
  utils::write.csv(pca_df, pca_path, row.names = FALSE)

  # --- Rotation (cargas) ---
  rot_df <- cbind(variable = pca$var_names, as.data.frame(pca$rotation))
  rot_path <- file.path(out_abs, paste0(ds, "_rotation.csv"))
  utils::write.csv(rot_df, rot_path, row.names = FALSE)

  # --- Varianza explicada ---
  var_df <- data.frame(
    PC      = pc_cols,
    var_pct = as.numeric(pca$var_pct),
    cum_pct = as.numeric(pca$cum_pct)
  )
  var_path <- file.path(out_abs, paste0(ds, "_var.csv"))
  utils::write.csv(var_df, var_path, row.names = FALSE)

  # --- Clusters (LONG: obs × k) ---
  rows <- lapply(names(km$resultados), function(nm_k) {
    r <- km$resultados[[nm_k]]
    data.frame(obs = km$obs_names, k = r$k, cluster = as.integer(r$cluster))
  })
  clusters_df <- do.call(rbind, rows)
  cl_path <- file.path(out_abs, paste0(ds, "_clusters.csv"))
  utils::write.csv(clusters_df, cl_path, row.names = FALSE)

  # --- Codo (tot.withinss por k) ---
  codo_df <- data.frame(k = as.integer(names(km$tot_withinss)),
                        tot_withinss = as.numeric(km$tot_withinss))
  codo_path <- file.path(out_abs, paste0(ds, "_codo.csv"))
  utils::write.csv(codo_df, codo_path, row.names = FALSE)

  # --- JSON S2 (sin PNG: los artefactos son los CSVs temáticos) ---
  metricas <- list(
    n_obs  = nrow(pca$scores),
    n_vars = length(pca$var_names),
    var_pc1 = as.numeric(pca$var_pct[1]),
    var_pc2 = as.numeric(pca$var_pct[2])
  )
  json_path <- escribir_salida(
    proyecto  = "quarto",
    escenario = paste0(ds, "-precomputo"),
    params    = list(dataset = ds, n_pcs = pca$n_pcs,
                     k_range = as.integer(km$k_range), semilla = semilla),
    metricas  = metricas,
    plot_obj  = NULL,
    datos_df  = NULL,
    notas     = sprintf("PCA + k-means precomputados sobre %s (%d obs × %d vars).",
                        ds, metricas$n_obs, metricas$n_vars),
    out_dir   = "libs/quarto/outputs"
  )

  cat(sprintf("[precomputo] %s: %d obs, var_pc1=%.1f%%, var_pc2=%.1f%%\n",
              ds, metricas$n_obs, metricas$var_pc1, metricas$var_pc2))

  list(pca = pca_path, rotation = rot_path, var = var_path,
       clusters = cl_path, codo = codo_path, json = json_path)
}
