# projects/__SLUG__/R/datos.R
#
# Adaptador de datos del proyecto. Traduce entre libs/_comun/R/datos.R y lo
# que modelo.R espera.
#
# Regla: si una funcion sirve para MAS de un proyecto, va en _comun.
# Si es especifica de este tema, va aca.
#
# TODO: elegi tu fuente segun la columna "Datos" de tu fila en
#       libs/topics-map.md, y borra las que no uses.
#
#   ch  -> cargar_charcoal()            panel pais x flujo x anio
#   tw  -> cargar_twins()               183 pares x 16 vars (NA = ".")
#   syn -> gen_sintetico()              sintetico controlado
#   piv -> pivot_paises()               matriz pais x anio (PCA/clustering)

datos_proyecto <- function(n = 120, ruido = 1, semilla = 42) {
  # TODO: cambiar por tu fuente real. Ejemplos:
  #   cargar_twins(completos = TRUE)
  #   filtrar_charcoal(paises = "Colombia", flujos = "Production")
  #   pivot_paises(anio_min = 1990, anio_max = 2020)
  gen_sintetico(n = n, ruido = ruido, semilla = semilla, tipo = "regresion")
}

# ---------------------------------------------------------------------------
# Cuantos casos completos quedan con una seleccion de columnas.
# La UI lo usa para avisar ANTES de ajustar, en vez de fallar despues.
# ---------------------------------------------------------------------------
n_completos <- function(df, columnas) {
  cols <- intersect(columnas, names(df))
  if (!length(cols)) return(0L)
  sum(stats::complete.cases(df[, cols, drop = FALSE]))
}
