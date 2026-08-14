# learn/R/nucleo/estado.R
#
# Responsabilidad: construir los cuatro objetos que la app compone.
#
#   DATASET (fase 1)  x  MODELO (fase 2)  x  RECETA (fase 3)  ->  CORRIDA (fase 4)
#
# Todo aquí es PURO: constructores y validación, cero reactividad. El almacén
# vive en almacen.R y también es puro (devuelve copias). Shiny se limita a
# guardar el almacén dentro de un reactiveVal.

ESCALAS <- c("nominal", "ordinal", "intervalo", "razon")
CLASES  <- c("cualitativa", "discreta", "continua")
ROLES   <- c("respuesta", "predictor", "id", "grupo", "peso", "ignorar")

.ahora <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

# ---------------------------------------------------------------------------
# Diccionario de columnas
#
# Es la pieza que casi nadie modela y que aquí es de primera clase: la escala
# de medición decide qué operación y qué gráfico tienen sentido, así que la UI
# la usa para habilitar o deshabilitar controles.
# ---------------------------------------------------------------------------

#' Diccionario inicial deducido del data.frame. Es un punto de partida para
#' que el usuario corrija, no una verdad: la escala no se puede inferir del
#' tipo de dato (un código postal es numérico y es nominal).
diccionario_inicial <- function(df) {
  filas <- lapply(names(df), function(columna) {
    valores <- df[[columna]]
    n_unicos <- length(unique(valores[!is.na(valores)]))
    if (is.numeric(valores)) {
      clase  <- if (n_unicos <= 12 && all(valores %% 1 == 0, na.rm = TRUE))
                  "discreta" else "continua"
      escala <- "razon"
    } else {
      clase  <- "cualitativa"
      escala <- "nominal"
    }
    data.frame(
      columna = columna, etiqueta = columna, descripcion = "",
      escala = escala, clase = clase, rol = "predictor", unidad = "",
      faltantes_pct = round(100 * mean(is.na(valores)), 2),
      n_unicos = n_unicos, stringsAsFactors = FALSE)
  })
  do.call(rbind, filas)
}

#' Columnas con un rol dado. Ej: columnas_con_rol(ds, "respuesta")
columnas_con_rol <- function(dataset, rol) {
  d <- dataset$diccionario
  if (is.null(d) || !nrow(d)) return(character(0))
  d$columna[d$rol == rol]
}

#' Columnas numéricas según el diccionario (no según el tipo en memoria).
columnas_numericas <- function(dataset) {
  d <- dataset$diccionario
  if (is.null(d) || !nrow(d)) return(character(0))
  d$columna[d$clase %in% c("discreta", "continua")]
}

# ---------------------------------------------------------------------------
# Constructores
# ---------------------------------------------------------------------------

#' @param fuente etiqueta de procedencia. Ej: "charcoal", "sintetico", "subido"
nuevo_dataset <- function(id, nombre, df, fuente = "desconocida",
                          diccionario = NULL, transformaciones = list(),
                          particion = NULL, balanceo = NULL, semilla = 42L) {
  stopifnot(is.data.frame(df))
  list(
    tipo = "dataset", id = id, nombre = nombre, fuente = fuente,
    df = df, diccionario = diccionario %||% diccionario_inicial(df),
    transformaciones = transformaciones, particion = particion,
    balanceo = balanceo, semilla = semilla,
    n = nrow(df), p = ncol(df), creado = .ahora()
  )
}

#' @param metodo clave del catálogo. @param spec fórmula o lista de bloques
nuevo_modelo <- function(id, nombre, metodo, spec = NULL, hiper = list()) {
  if (!existe_metodo(metodo)) stop("método no registrado: ", metodo)
  list(tipo = "modelo", id = id, nombre = nombre, metodo = metodo,
       spec = spec, hiper = hiper, creado = .ahora())
}

#' Receta = cómo se ajusta, independiente de qué se ajusta.
nueva_receta <- function(id, nombre, optimizador = NA_character_,
                         control = list(tol = 1e-6, maxit = 100L),
                         cv = NULL, semilla = 42L) {
  list(tipo = "receta", id = id, nombre = nombre, optimizador = optimizador,
       control = control, cv = cv, semilla = semilla, creado = .ahora())
}

#' Corrida = el único objeto que tiene resultados.
#' @param estado "pendiente" | "corriendo" | "listo" | "error"
nueva_corrida <- function(id, dataset_id, modelo_id, receta_id, metodo,
                          ajuste = NULL, traza = NULL, metricas = list(),
                          params = list(), duracion = NA_real_,
                          estado = "pendiente", error = NA_character_) {
  list(tipo = "corrida", id = id, dataset_id = dataset_id,
       modelo_id = modelo_id, receta_id = receta_id, metodo = metodo,
       ajuste = ajuste, traza = traza, metricas = metricas, params = params,
       duracion = duracion, estado = estado, error = error, creado = .ahora())
}

# ---------------------------------------------------------------------------
# Resumen legible — lo que se ve en la columna "resumen" del CRUD
# ---------------------------------------------------------------------------

resumen_objeto <- function(objeto) {
  switch(objeto$tipo,
    dataset = sprintf("%d x %d · %s%s", objeto$n, objeto$p, objeto$fuente,
                      if (length(objeto$transformaciones))
                        sprintf(" · %d transf.", length(objeto$transformaciones)) else ""),
    modelo  = sprintf("%s%s", metodo(objeto$metodo)$nombre,
                      if (length(objeto$hiper))
                        paste0(" · ", .hiper_corto(objeto$hiper)) else ""),
    receta  = sprintf("%s · tol %g · maxit %s",
                      ifelse(is.na(objeto$optimizador), "por defecto", objeto$optimizador),
                      objeto$control$tol %||% NA, objeto$control$maxit %||% "-"),
    corrida = sprintf("%s x %s x %s · %s", objeto$dataset_id, objeto$modelo_id,
                      objeto$receta_id, objeto$estado),
    "-")
}

.hiper_corto <- function(hiper) {
  pares <- vapply(names(hiper), function(k) sprintf("%s=%s", k, hiper[[k]]), "")
  paste(utils::head(pares, 3), collapse = " ")
}
