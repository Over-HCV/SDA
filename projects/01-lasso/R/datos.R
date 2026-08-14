# projects/01-lasso/R/datos.R
#
# Adaptador de datos del proyecto. Su unico trabajo es traducir entre
# libs/_comun/R/datos.R y lo que modelo.R espera.
#
# Regla: si una funcion sirve para MAS de un proyecto, va en _comun.
# Si es especifica de este tema, va aca.

# ---------------------------------------------------------------------------
# Dataset del proyecto: twins.csv completo (sin filtrar casos, eso lo decide
# correr_lasso() segun las columnas que realmente use).
# ---------------------------------------------------------------------------
datos_lasso <- function() {
  cargar_twins(completos = FALSE)
}

# Etiquetas legibles para los selectores de la UI: "DEDUC1 — Dif. de educacion..."
etiquetas_vars <- function(vars = NULL) {
  dic <- twins_diccionario()
  if (is.null(vars)) vars <- names(dic)
  etiquetas <- ifelse(vars %in% names(dic),
                      sprintf("%s — %s", vars, dic[vars]),
                      vars)
  stats::setNames(vars, etiquetas)
}

# ---------------------------------------------------------------------------
# Cuantos casos completos quedan con una seleccion dada de columnas.
# La UI lo usa para avisar ANTES de ajustar: agregar HRWAGEH/HRWAGEL tira
# ~20 filas cada una, y con 147 casos eso se nota.
# ---------------------------------------------------------------------------
n_completos <- function(df, y_var, x_vars) {
  cols <- intersect(c(y_var, x_vars), names(df))
  if (!length(cols)) return(0L)
  sum(stats::complete.cases(df[, cols, drop = FALSE]))
}
