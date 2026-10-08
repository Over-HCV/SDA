# learn/R/nucleo/ajuste.R
#
# Responsabilidad: ajustar un método del catálogo a partir del registro, con un
# solo camino para el batch (run_headless.R) y la consola (lab.R).
#
# Antes este tramo vivía dentro de `correr()`: buscar el método, pisar los
# hiperparámetros por defecto, elegir optimizador e inicialización, filtrar los
# argumentos que la función pura acepta y llamarla con la semilla. Cuando la
# consola aprendió a ajustar, la alternativa era copiarlo — y dos copias de la
# misma receta divergen en cuanto alguien toca una sola (C11). Acá queda una.

#' Ajusta `metodo` sobre `datos` como lo haría `correr()`.
#'
#' @param datos     data.frame
#' @param metodo    clave del catálogo; debe estar `activo`
#' @param columnas  columnas que entran; NULL = las que el método tome solo
#' @param hiper     lista con nombre que pisa `hiper_por_defecto(metodo)`. Un
#'   nombre que el registro no declara es un error: callarlo es lo que hace
#'   que un `--hiper matrz=covarianza` mal tipeado corra el default sin avisar
#' @return list(ajuste, metodo, parametros, optimizador, inicializacion,
#'   duracion)
ajustar_por_registro <- function(datos, metodo, columnas = NULL, hiper = list(),
                                 optimizador = NULL, inicializacion = NULL,
                                 reinicios = 1L, tol = 1e-8, maxit = 500L,
                                 semilla = 42L, registrar_traza = TRUE) {
  m <- metodo(metodo)
  if (m$estado != "activo")
    stop(sprintf("'%s' esta '%s': todavia no se puede ajustar", metodo, m$estado))
  defecto <- hiper_por_defecto(metodo)
  extranos <- setdiff(names(hiper), names(defecto))
  if (length(extranos))
    stop(sprintf("'%s' no tiene el hiperparámetro %s · declara: %s", metodo,
                 paste(extranos, collapse = ", "),
                 paste(names(defecto), collapse = ", ")), call. = FALSE)
  parametros <- utils::modifyList(defecto, as.list(hiper))
  optimizador <- optimizador %||% (m$optimizador$metodos %||% NA_character_)[1]
  inicializacion <- inicializacion %||%
    (m$optimizador$inicializaciones %||% NA_character_)[1]

  inicio <- Sys.time()
  ajuste <- do.call(m$ajustar, argumentos_ajuste(metodo, c(
    list(datos = datos, columnas = columnas),
    parametros,
    list(optimizador = optimizador, inicializacion = inicializacion,
         reinicios = reinicios, tol = tol, maxit = maxit,
         semilla = semilla, registrar_traza = registrar_traza))))
  list(ajuste = ajuste, metodo = m, parametros = parametros,
       optimizador = optimizador, inicializacion = inicializacion,
       duracion = as.numeric(difftime(Sys.time(), inicio, units = "secs")))
}

#' Un valor de hiperparámetro escrito como texto, al tipo que el registro
#' declara: lo que llega de la consola o de un `clave=valor` siempre es texto,
#' y `k = "3"` no es un entero para `ajustar_kmeans()`.
convertir_hiper <- function(metodo, nombre, valor) {
  spec <- metodo(metodo)$hiper[[nombre]]
  if (is.null(spec)) return(valor)
  switch(spec$tipo %||% "",
    entero = as.integer(valor),
    real = as.numeric(valor),
    logico = as.logical(toupper(as.character(valor))),
    opcion = {
      if (!is.null(spec$opciones) && !valor %in% spec$opciones)
        stop(sprintf("%s=%s no es una opción · válidas: %s", nombre, valor,
                     paste(spec$opciones, collapse = ", ")), call. = FALSE)
      as.character(valor)
    },
    valor)
}

#' Ajusta un método de agrupamiento y deja su partición como columna `grupo`
#' del dataset: el traspaso ② → ① que permite mirar los grupos con las
#' herramientas de la fase 1 (cajas por grupo, frecuencias, dispersión).
#'
#' La columna se alinea con las filas que de verdad entraron al ajuste, igual
#' que el color del mapa en f4/plano.R: las filas con un faltante en las
#' columnas del ajuste quedan en NA, en vez de correr la partición una fila.
#' La receta queda en `ds$grupos` para que una sesión la pueda rehacer.
#'
#' @return el dataset con `grupo` (factor 1..k) y su rol declarado
agregar_grupos <- function(ds, metodo, hiper = list(), columnas = NULL,
                           reinicios = 1L, semilla = ds$semilla %||% 42L) {
  ajuste <- ajustar_por_registro(ds$df, metodo, columnas = columnas,
                                 hiper = hiper, reinicios = reinicios,
                                 semilla = semilla)$ajuste
  if (is.null(ajuste$grupos))
    stop(sprintf("'%s' no produce grupos: no hay partición que traspasar",
                 metodo), call. = FALSE)
  completas <- stats::complete.cases(ds$df[, ajuste$columnas, drop = FALSE])
  grupo <- rep(NA_integer_, nrow(ds$df))
  grupo[completas] <- as.integer(ajuste$grupos)
  ds$df$grupo <- factor(grupo, levels = sort(unique(ajuste$grupos)))
  ds$p <- ncol(ds$df)
  ds$diccionario <- actualizar_diccionario(
    rehacer_diccionario(ds$diccionario, ds$df), "grupo", "rol", "grupo")
  ds$grupos <- list(metodo = metodo, hiper = as.list(hiper),
                    columnas = columnas, reinicios = reinicios,
                    semilla = semilla)
  ds
}
