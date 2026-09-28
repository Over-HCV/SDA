# learn/metodos/acm.R
#
# Responsabilidad: ajustar un análisis de correspondencias múltiples, puro.
#
# Es el ACP de las variables cualitativas, y la analogía es literal: donde el
# ACP descompone la matriz de varianzas y covarianzas, el ACM descompone la de
# Burt — los cruces de todas las variables entre sí. Ninguna de las dos guarda
# una fila de datos, y las dos resumen lo mismo: la estructura de asociación.
#
# El camino es un SVD de los residuos estandarizados de la matriz indicadora:
#
#   P = Z / (n·Q)            proporciones
#   r = filas, c = columnas  masas marginales
#   S = D_r^(-1/2) (P − r cᵀ) D_c^(-1/2)
#   svd(S) = U D Vᵀ          valores propios = d²
#
# Restar r cᵀ es lo mismo que centrar en el ACP: saca la dimensión trivial que
# solo dice que la tabla tiene marginales. Lo que queda es la desviación
# respecto a la independencia, que es la señal.
#
# La inercia total es J/Q − 1 y no depende de los datos, solo de cuántas
# categorías haya: eso hace que los porcentajes de varianza explicada del ACM
# sean pesimistas comparados con los del ACP, y es un artefacto del método, no
# un resultado (por eso existen las correcciones de Benzécri y Greenacre, que
# quedan fuera de este curso).
#
# Devuelve la misma forma que ajustar_acp() y declara `ajuste_reduccion`: la
# fase 4 lo dibuja sin una vista nueva.

#' Ajusta un ACM.
#'
#' @param datos         data.frame
#' @param columnas      columnas cualitativas; NULL = todas las no numéricas
#' @param n_componentes cuántas dimensiones se retienen
#' @param semilla       no gobierna nada acá (el SVD es determinista); se acepta
#'                      para que la corrida guarde el mismo bloque que las demás
#' @return list con cargas, puntuaciones, valores_propios, varianza_explicada,
#'   burt y los parámetros con que se ajustó
ajustar_acm <- function(datos, columnas = NULL, n_componentes = 2L,
                        semilla = 42L) {
  columnas <- columnas %||% names(datos)[!vapply(datos, is.numeric, logical(1))]
  indicadora <- matriz_indicadora(datos, columnas)
  variables <- attr(indicadora, "variables")

  n <- nrow(indicadora)
  Q <- length(unique(variables))
  J <- ncol(indicadora)
  # Las dimensiones no triviales son J − Q: cada variable gasta una en la
  # restriccion de que sus indicadoras suman 1.
  p <- max(1L, J - Q)
  k <- max(1L, min(as.integer(n_componentes), p))

  descomposicion <- .acm_por_svd(indicadora, n, Q, p)
  valores <- descomposicion$valores
  names(valores) <- paste0("Dim", seq_along(valores))

  filas <- descomposicion$filas
  colnames(filas) <- names(valores)
  categorias <- descomposicion$columnas
  dimnames(categorias) <- list(colnames(indicadora), names(valores))

  inercia_total <- J / Q - 1
  descartada <- sum(valores[seq_len(p) > k])

  structure(list(
    cargas = categorias,
    puntuaciones = filas[, seq_len(k), drop = FALSE],
    valores_propios = valores,
    varianza_explicada = valores / inercia_total,
    varianza_total = inercia_total,
    error_reconstruccion = descartada,
    error_relativo = descartada / inercia_total,
    norma2_filas = as.numeric(rowSums(filas^2)),
    # Sin centro ni escala no hay individuos suplementarios: proyectar una fila
    # nueva en un ACM exige su perfil de categorias, no una estandarizacion, y
    # eso es otra funcion. Se dejan en NULL para que falle diciendolo.
    centro = NULL, escala = NULL,
    columnas = columnas, variables = variables,
    categorias = colnames(indicadora),
    burt = matriz_burt(indicadora),
    n = n, p = p, k = k, Q = Q, J = J,
    filas_descartadas = attr(indicadora, "filas_descartadas"),
    # El campo `matriz` lo lee reglas_k(): al no ser "correlacion", el corte de
    # Kaiser pasa a ser la media de los valores propios, que en un ACM es
    # exactamente 1/Q — el umbral que la literatura usa. Sale gratis.
    matriz = "indicadora", optimizador = "svd",
    semilla = semilla, iteraciones = 0L, convergio = TRUE,
    convergio_por_componente = rep(TRUE, p), traza = NULL),
    class = c("ajuste_acm", "ajuste_reduccion", "ajuste_sda"))
}

# ---------------------------------------------------------------------------
# La descomposición
# ---------------------------------------------------------------------------

.acm_por_svd <- function(indicadora, n, Q, p) {
  proporciones <- indicadora / (n * Q)
  masa_filas <- rowSums(proporciones)
  masa_columnas <- colSums(proporciones)
  if (any(masa_columnas <= 0))
    stop("hay categorias sin observaciones: agrupalas antes de correr el ACM")

  esperado <- outer(masa_filas, masa_columnas)
  residuos <- (proporciones - esperado) /
    outer(sqrt(masa_filas), sqrt(masa_columnas))

  descomposicion <- svd(residuos)
  usar <- seq_len(min(p, length(descomposicion$d)))
  singulares <- descomposicion$d[usar]

  # Coordenadas principales: el vector singular reescalado por su masa y por el
  # valor singular. Es la misma cuenta del biplot del ACP, con pesos.
  filas <- descomposicion$u[, usar, drop = FALSE] *
    (1 / sqrt(masa_filas)) %o% singulares
  columnas <- descomposicion$v[, usar, drop = FALSE] *
    (1 / sqrt(masa_columnas)) %o% singulares
  rownames(filas) <- rownames(indicadora)

  list(valores = singulares^2, filas = filas, columnas = columnas)
}
