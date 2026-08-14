# learn/metodos/acp.R
#
# Responsabilidad: ajustar un análisis de componentes principales, puro.
#
# Sin Shiny, sin input, sin reactive (S1/C3): esta función corre igual desde la
# app, desde run_headless.R y desde una consola de R. Es el contrato que hace
# que la app y el batch no puedan divergir.
#
# Dos caminos al mismo resultado, y esa es la lección:
#
#   svd      · descomposición en un paso. Es lo que hace prcomp(). Exacto y
#              aburrido: no hay nada que mirar mientras corre.
#   potencia · iteración de potencia con deflación. Empieza en un vector al
#              azar, lo multiplica por S y lo normaliza; el vector gira hacia
#              la dirección de mayor varianza y se queda ahí. Deflacionando
#              (S ← S − λ v vᵀ) sale la siguiente componente.
#
# Los dos tienen que dar lo mismo hasta el signo, y test_acp.R lo comprueba.
# Que coincidan es lo que autoriza a usar el lento para enseñar y el rápido
# para trabajar.
#
# La teoría está en fichas/acp.md y en notes/SDA/NB3/main.md.

#' Ajusta un ACP.
#'
#' @param datos          data.frame
#' @param columnas       columnas a usar; NULL = todas las numéricas
#' @param n_componentes  cuántas se retienen (las demás se calculan igual, para
#'                       que el scree muestre el descenso completo)
#' @param matriz         "correlacion" (estandariza: R) o "covarianza" (S crudo)
#' @param optimizador    "potencia" o "svd"
#' @param tol            corte de convergencia sobre el cambio del vector
#' @param maxit          techo de iteraciones por componente
#' @param semilla        gobierna el vector inicial de la iteración (C13)
#' @param registrar_traza FALSE ahorra memoria en barridos grandes
#' @return list con cargas, puntuaciones, valores_propios, varianza_explicada,
#'   error_reconstruccion, traza, convergio y los parámetros con que se ajustó
ajustar_acp <- function(datos, columnas = NULL, n_componentes = 2L,
                        matriz = "correlacion", optimizador = "potencia",
                        tol = 1e-8, maxit = 200L, semilla = 42L,
                        registrar_traza = TRUE) {
  matriz <- match.arg(matriz, c("correlacion", "covarianza"))
  optimizador <- match.arg(optimizador, c("potencia", "svd"))

  preparado <- .preparar_matriz_acp(datos, columnas, matriz)
  z <- preparado$z
  p <- ncol(z)
  k <- max(1L, min(as.integer(n_componentes), p))

  covarianzas <- stats::cov(z)
  varianza_total <- sum(diag(covarianzas))

  resultado <- if (optimizador == "svd") {
    .acp_por_svd(z)
  } else {
    .acp_por_potencia(covarianzas, tol = tol, maxit = maxit, semilla = semilla,
                      registrar_traza = registrar_traza,
                      varianza_total = varianza_total)
  }

  cargas <- .fijar_signo(resultado$vectores)
  dimnames(cargas) <- list(preparado$columnas, paste0("CP", seq_len(p)))
  valores <- resultado$valores
  names(valores) <- colnames(cargas)

  puntuaciones <- z %*% cargas
  colnames(puntuaciones) <- colnames(cargas)

  # Error de reconstrucción con k componentes: la varianza que quedó fuera. Es
  # la segunda lectura del ACP (mínimo error) medida sobre la primera (máxima
  # varianza); que sean el mismo número no es casualidad, es Pitágoras.
  descartada <- sum(valores[seq_len(p) > k])

  list(
    cargas = cargas,
    puntuaciones = puntuaciones[, seq_len(k), drop = FALSE],
    valores_propios = valores,
    varianza_explicada = valores / varianza_total,
    varianza_total = varianza_total,
    error_reconstruccion = descartada,
    error_relativo = descartada / varianza_total,
    centro = preparado$centro,
    escala = preparado$escala,
    columnas = preparado$columnas,
    n = nrow(z), p = p, k = k,
    filas_descartadas = preparado$descartadas,
    matriz = matriz, optimizador = optimizador,
    tol = tol, maxit = maxit, semilla = semilla,
    iteraciones = resultado$iteraciones,
    convergio = resultado$convergio,
    traza = resultado$traza)
}

# ---------------------------------------------------------------------------
# Preparación: qué entra a la descomposición
# ---------------------------------------------------------------------------

# La decisión S vs R no se toma acá por gusto: centrar siempre, escalar solo si
# se pidió correlación. Escalar ES descomponer R, y no decidirlo es decidir que
# mande la variable con la unidad más grande (ver fichas/acp.md).
.preparar_matriz_acp <- function(datos, columnas, matriz) {
  numericas <- names(datos)[vapply(datos, is.numeric, logical(1))]
  columnas <- intersect(columnas %||% numericas, numericas)
  if (length(columnas) < 2L)
    stop("el ACP necesita al menos dos columnas numericas")

  bruta <- as.matrix(datos[, columnas, drop = FALSE])
  completas <- stats::complete.cases(bruta)
  if (sum(completas) <= length(columnas))
    stop("quedan menos filas completas que columnas: imputa o quita columnas")
  bruta <- bruta[completas, , drop = FALSE]

  centro <- colMeans(bruta)
  escala <- if (matriz == "correlacion") apply(bruta, 2L, stats::sd) else
    rep(1, length(columnas))
  if (any(escala == 0))
    stop("hay columnas constantes: su varianza es cero y no se pueden escalar")

  list(z = scale(bruta, center = centro, scale = escala),
       columnas = columnas, centro = centro, escala = escala,
       descartadas = sum(!completas))
}

# El signo de un autovector es arbitrario: v y −v describen el mismo eje. Sin
# fijarlo, dos corridas idénticas dan biplots espejados y el usuario cree que
# cambió algo. Convención: la carga de mayor magnitud queda positiva.
.fijar_signo <- function(vectores) {
  for (j in seq_len(ncol(vectores))) {
    columna <- vectores[, j]
    if (columna[which.max(abs(columna))] < 0) vectores[, j] <- -columna
  }
  vectores
}

# ---------------------------------------------------------------------------
# Los dos optimizadores
# ---------------------------------------------------------------------------

.acp_por_svd <- function(z) {
  ajuste <- stats::prcomp(z, center = FALSE, scale. = FALSE)
  list(vectores = ajuste$rotation, valores = ajuste$sdev^2,
       iteraciones = 0L, convergio = TRUE, traza = NULL)
}

# Iteración de potencia con deflación. El objetivo que se registra es la
# varianza todavía no explicada: baja en cada iteración porque el estimador de
# λ solo puede subir, y sigue bajando al pasar de una componente a la
# siguiente. Una traza que suba delataría un bug, y traza_monotona() lo mira.
.acp_por_potencia <- function(covarianzas, tol, maxit, semilla,
                              registrar_traza, varianza_total) {
  p <- ncol(covarianzas)
  set.seed(semilla)

  vectores <- matrix(0, nrow = p, ncol = p,
                     dimnames = list(rownames(covarianzas), NULL))
  valores <- numeric(p)
  traza <- if (registrar_traza)
    nueva_traza("varianza no explicada", sentido = "desciende") else NULL
  residual <- covarianzas
  restante <- varianza_total
  iteraciones <- 0L
  convergio <- TRUE

  for (j in seq_len(p)) {
    v <- stats::rnorm(p)
    v <- v / sqrt(sum(v^2))
    lambda <- 0
    convergio_j <- FALSE

    for (iteracion in seq_len(maxit)) {
      producto <- as.numeric(residual %*% v)
      norma <- sqrt(sum(producto^2))
      # Norma cero: el residual ya es la matriz nula. Las componentes que
      # quedan no explican nada y se dejan en cero, que es la verdad.
      if (norma < .Machine$double.eps) { convergio_j <- TRUE; break }

      nuevo <- producto / norma
      if (sum(nuevo * v) < 0) nuevo <- -nuevo   # sin esto el delta oscila
      delta <- sqrt(sum((nuevo - v)^2))
      v <- nuevo
      lambda <- as.numeric(t(v) %*% residual %*% v)
      iteraciones <- iteraciones + 1L

      if (!is.null(traza)) {
        traza <- registrar_iteracion(
          traza, iter = iteracion, objetivo = max(restante - lambda, 0),
          delta = delta, componente = j,
          parametros = stats::setNames(v, rownames(covarianzas)))
      }
      if (delta < tol) { convergio_j <- TRUE; break }
    }

    convergio <- convergio && convergio_j
    vectores[, j] <- v
    valores[j] <- max(lambda, 0)
    restante <- max(restante - valores[j], 0)
    residual <- residual - valores[j] * tcrossprod(v)
  }

  orden <- order(valores, decreasing = TRUE)
  list(vectores = vectores[, orden, drop = FALSE], valores = valores[orden],
       iteraciones = iteraciones, convergio = convergio, traza = traza)
}
