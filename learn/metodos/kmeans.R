# learn/metodos/kmeans.R
#
# Responsabilidad: partir n observaciones en k grupos minimizando la inercia
# intra-grupo, puro.
#
# Sin Shiny, sin input, sin reactive (S1/C3): corre igual desde la app, desde
# run_headless.R y desde una consola de R.
#
# Lo que k-medias añade al marco y el ACP no podía dar:
#
#   · Un optimizador que de verdad puede terminar en el sitio equivocado. El
#     ACP siempre converge al mismo subespacio; acá la partición depende de
#     dónde arrancaron los centroides, y por eso `reinicios` no es un lujo.
#   · Una traza con estado: no solo baja un número, se mueven los centroides y
#     cambian las asignaciones. Eso es lo que hace que el paso a paso enseñe.
#
# Lloyd y MacQueen están escritos a mano, sin stats::kmeans(). No es purismo:
# stats::kmeans() devuelve el resultado y se traga las iteraciones, que es
# justamente lo único que la fase 3 quiere mostrar.
#
# La teoría está en fichas/kmeans.md.

#' Ajusta k-medias.
#'
#' @param datos          data.frame
#' @param columnas       columnas a usar; NULL = todas las numéricas
#' @param k              número de grupos
#' @param escalar        TRUE estandariza cada columna antes de medir distancias
#' @param optimizador    "Lloyd" o "MacQueen"
#' @param inicializacion "k-means++", "aleatoria" o "Forgy"
#' @param reinicios      cuántas veces se reintenta desde otro arranque
#' @param tol            corte sobre la baja de inercia entre iteraciones
#' @param maxit          techo de iteraciones por reinicio
#' @param semilla        gobierna el arranque (C13); el reinicio i usa semilla+i-1
#' @param registrar_traza FALSE ahorra memoria en barridos grandes
#' @return list con grupos, centroides, inercia, traza y los parámetros usados
ajustar_kmeans <- function(datos, columnas = NULL, k = 3L, escalar = TRUE,
                           optimizador = "Lloyd",
                           inicializacion = "k-means++", reinicios = 10L,
                           tol = 1e-8, maxit = 100L, semilla = 42L,
                           registrar_traza = TRUE) {
  optimizador <- match.arg(optimizador, c("Lloyd", "MacQueen"))
  inicializacion <- match.arg(inicializacion,
                              c("k-means++", "aleatoria", "Forgy"))

  preparado <- .preparar_matriz_kmeans(datos, columnas, escalar)
  z <- preparado$z
  n <- nrow(z)
  k <- as.integer(k)
  if (k < 2L) stop("k-medias necesita al menos dos grupos")
  if (k >= n) stop("hacen falta mas filas completas que grupos: n = ", n,
                   ", k = ", k)
  reinicios <- max(1L, as.integer(reinicios))

  semillas <- semilla + seq_len(reinicios) - 1L
  intentos <- lapply(semillas, function(s)
    .correr_kmeans(z, k, optimizador, inicializacion, tol, maxit, s,
                   registrar_traza))
  mejor <- which.min(vapply(intentos, `[[`, numeric(1), "inercia"))
  ganador <- .ordenar_grupos(intentos[[mejor]], preparado$columnas)

  inercia_total <- sum((scale(z, center = TRUE, scale = FALSE))^2)
  tamanos <- as.integer(table(factor(ganador$grupos, levels = seq_len(k))))

  structure(list(
    grupos = ganador$grupos,
    centroides = ganador$centroides,
    inercia = ganador$inercia,
    inercia_por_grupo = .inercia_por_grupo(z, ganador$grupos, ganador$centroides),
    inercia_total = inercia_total,
    proporcion_explicada = 1 - ganador$inercia / inercia_total,
    tamanos = tamanos,
    z = z,
    centro = preparado$centro, escala = preparado$escala,
    columnas = preparado$columnas,
    n = n, p = ncol(z), k = k,
    filas_descartadas = preparado$descartadas,
    escalar = escalar, optimizador = optimizador,
    inicializacion = inicializacion, reinicios = reinicios,
    tol = tol, maxit = maxit, semilla = semilla,
    semilla_ganadora = semillas[mejor],
    iteraciones = ganador$iteraciones,
    convergio = ganador$convergio,
    traza = ganador$traza,
    trazas_reinicios = stats::setNames(lapply(intentos, `[[`, "traza"),
                                       as.character(semillas)),
    asignaciones_por_iter = ganador$asignaciones),
    class = c("ajuste_kmeans", "ajuste_sda"))
}

# ---------------------------------------------------------------------------
# Preparación: qué entra a las distancias
# ---------------------------------------------------------------------------

# Escalar no es cosmética acá: la distancia euclidiana suma cuadrados de cosas
# con unidades distintas, así que sin escalar manda la columna con el rango más
# grande. Se deja elegir porque a veces las unidades ya son comparables.
.preparar_matriz_kmeans <- function(datos, columnas, escalar) {
  numericas <- names(datos)[vapply(datos, is.numeric, logical(1))]
  columnas <- intersect(columnas %||% numericas, numericas)
  if (length(columnas) < 2L)
    stop("k-medias necesita al menos dos columnas numericas")

  bruta <- as.matrix(datos[, columnas, drop = FALSE])
  completas <- stats::complete.cases(bruta)
  if (sum(completas) < 3L)
    stop("quedan menos de tres filas completas: imputa o quita columnas")
  bruta <- bruta[completas, , drop = FALSE]

  centro <- colMeans(bruta)
  escala <- if (isTRUE(escalar)) apply(bruta, 2L, stats::sd) else
    rep(1, length(columnas))
  if (isTRUE(escalar) && any(escala == 0))
    stop("hay columnas constantes: su varianza es cero y no se pueden escalar")

  z <- scale(bruta, center = centro, scale = escala)
  attributes(z) <- list(dim = dim(z), dimnames = list(NULL, columnas))
  list(z = z, columnas = columnas, centro = centro, escala = escala,
       descartadas = sum(!completas))
}

# La etiqueta de un grupo es arbitraria: la misma partición con los números
# permutados es la misma partición. Sin fijar el orden, dos corridas idénticas
# pintan el mapa 2D con otros colores y parece que cambió algo (es el mismo
# problema que el signo del autovector en el ACP).
.ordenar_grupos <- function(resultado, columnas) {
  orden <- order(resultado$centroides[, 1L])
  nuevo <- match(resultado$grupos, orden)
  resultado$grupos <- nuevo
  resultado$centroides <- resultado$centroides[orden, , drop = FALSE]
  dimnames(resultado$centroides) <- list(paste0("g", seq_along(orden)), columnas)
  if (!is.null(resultado$asignaciones))
    resultado$asignaciones[] <- match(resultado$asignaciones, orden)
  resultado
}

# ---------------------------------------------------------------------------
# Los dos optimizadores
# ---------------------------------------------------------------------------

.correr_kmeans <- function(z, k, optimizador, inicializacion, tol, maxit,
                           semilla, registrar_traza) {
  set.seed(semilla)
  centroides <- .inicializar(z, k, inicializacion)
  traza <- if (registrar_traza)
    nueva_traza("inercia intra-grupo", sentido = "desciende") else NULL

  # El arranque es asignar y recentrar UNA vez: sin recentrar, la inercia del
  # punto de partida se mide contra centroides que son observaciones sueltas y
  # sale más baja de lo que el estado vale. Esa mentira hacía que MacQueen
  # pareciera empeorar en su primer barrido.
  grupos <- .asignar(z, centroides)
  centroides <- .recentrar(z, grupos, centroides, k)
  inercia <- .inercia(z, grupos, centroides)
  asignaciones <- if (registrar_traza) matrix(grupos, ncol = 1L) else NULL
  if (!is.null(traza))
    traza <- registrar_iteracion(traza, iter = 0L, objetivo = inercia,
                                 delta = NA_real_, componente = 1L,
                                 parametros = .centroides_planos(centroides))
  convergio <- FALSE
  iteraciones <- 0L

  for (iteracion in seq_len(maxit)) {
    paso <- if (optimizador == "Lloyd")
      .paso_lloyd(z, grupos, centroides, k) else
      .paso_macqueen(z, grupos, centroides, k)
    nueva_inercia <- .inercia(z, paso$grupos, paso$centroides)
    delta <- inercia - nueva_inercia
    sin_cambio <- identical(paso$grupos, grupos)

    grupos <- paso$grupos
    centroides <- paso$centroides
    inercia <- nueva_inercia
    iteraciones <- iteracion

    if (!is.null(traza)) {
      traza <- registrar_iteracion(traza, iter = iteracion, objetivo = inercia,
                                   delta = delta, componente = 1L,
                                   parametros = .centroides_planos(centroides))
      asignaciones <- cbind(asignaciones, grupos)
    }
    if (sin_cambio || (delta >= 0 && delta < tol)) { convergio <- TRUE; break }
  }

  list(grupos = grupos, centroides = centroides, inercia = inercia,
       iteraciones = iteraciones, convergio = convergio, traza = traza,
       asignaciones = asignaciones)
}

# Lloyd: reasignar todo el mundo, y recién entonces recentrar. Los dos pasos
# bajan la inercia por separado, y por eso la traza no puede subir.
.paso_lloyd <- function(z, grupos, centroides, k) {
  nuevos <- .asignar(z, centroides)
  list(grupos = nuevos, centroides = .recentrar(z, nuevos, centroides, k))
}

# MacQueen: cada observación que cambia de grupo mueve los dos centroides en el
# acto. Converge en menos barridos y depende del orden de las filas, que es la
# diferencia que se puede ver contra Lloyd con la misma semilla.
#
# La actualización es incremental —solo el grupo que pierde y el que gana— y no
# un recentrado completo. No es una optimización opcional: recentrar los k
# grupos después de cada observación es O(n²kp) por barrido, y con cinco mil
# filas el ajuste deja de terminar.
#
# Un grupo que se quedaría con una sola observación no la suelta: vaciarlo
# obligaría a reubicar el centroide en mitad del barrido, con el resto de las
# asignaciones ya hechas contra un centroide que dejó de existir.
.paso_macqueen <- function(z, grupos, centroides, k) {
  tamanos <- tabulate(grupos, nbins = k)
  for (i in seq_len(nrow(z))) {
    origen <- grupos[i]
    destino <- which.min(colSums((t(centroides) - z[i, ])^2))
    if (destino == origen || tamanos[origen] <= 1L) next

    centroides[origen, ] <- (centroides[origen, ] * tamanos[origen] - z[i, ]) /
      (tamanos[origen] - 1L)
    centroides[destino, ] <- (centroides[destino, ] * tamanos[destino] + z[i, ]) /
      (tamanos[destino] + 1L)
    tamanos[origen] <- tamanos[origen] - 1L
    tamanos[destino] <- tamanos[destino] + 1L
    grupos[i] <- destino
  }
  list(grupos = grupos, centroides = centroides)
}

.asignar <- function(z, centroides) {
  distancias <- .distancias(z, centroides)
  max.col(-distancias, ties.method = "first")
}

# n x k de distancias al cuadrado, sin bucle sobre las filas.
.distancias <- function(z, centroides) {
  producto <- z %*% t(centroides)
  normas_z <- rowSums(z^2)
  normas_c <- rowSums(centroides^2)
  outer(normas_z, normas_c, "+") - 2 * producto
}

# Un grupo puede quedarse sin nadie. Dejarlo vacío rompe el promedio y el
# ajuste devuelve NaN en silencio; reubicarlo en los puntos peor explicados es
# lo que hace cualquier implementación seria, y además es reproducible.
.recentrar <- function(z, grupos, centroides, k) {
  for (j in seq_len(k)) {
    filas <- which(grupos == j)
    if (length(filas)) centroides[j, ] <- colMeans(z[filas, , drop = FALSE])
  }
  vacios <- setdiff(seq_len(k), unique(grupos))
  if (length(vacios)) {
    cercana <- apply(.distancias(z, centroides), 1L, min)
    lejanos <- order(cercana, decreasing = TRUE)[seq_along(vacios)]
    centroides[vacios, ] <- z[lejanos, , drop = FALSE]
  }
  centroides
}

.inercia <- function(z, grupos, centroides) {
  sum((z - centroides[grupos, , drop = FALSE])^2)
}

.inercia_por_grupo <- function(z, grupos, centroides) {
  vapply(seq_len(nrow(centroides)), function(j) {
    filas <- which(grupos == j)
    if (!length(filas)) return(0)
    sum((z[filas, , drop = FALSE] -
           rep(centroides[j, ], each = length(filas)))^2)
  }, numeric(1))
}

# Los centroides como vector con nombre, que es lo que la traza genérica sabe
# guardar: "g1_peso", "g1_altura", "g2_peso"...
.centroides_planos <- function(centroides) {
  valores <- as.numeric(t(centroides))
  nombres <- as.vector(t(outer(paste0("g", seq_len(nrow(centroides))),
                               colnames(centroides), paste, sep = "_")))
  stats::setNames(valores, nombres)
}

# ---------------------------------------------------------------------------
# Inicializaciones
# ---------------------------------------------------------------------------

.inicializar <- function(z, k, inicializacion) {
  centroides <- switch(inicializacion,
    "k-means++" = .iniciar_kmeanspp(z, k),
    "aleatoria" = .iniciar_aleatoria(z, k),
    "Forgy"     = .iniciar_forgy(z, k))
  dimnames(centroides) <- list(NULL, colnames(z))
  centroides
}

# k-means++: el primer centroide al azar, y cada siguiente con probabilidad
# proporcional a la distancia al más cercano ya elegido. Arranca separado, que
# es la mitad del problema del algoritmo.
.iniciar_kmeanspp <- function(z, k) {
  elegidos <- integer(k)
  elegidos[1] <- sample.int(nrow(z), 1L)
  for (j in seq_len(k - 1L)) {
    cercanas <- apply(.distancias(z, z[elegidos[seq_len(j)], , drop = FALSE]),
                      1L, min)
    cercanas[cercanas < 0] <- 0
    elegidos[j + 1L] <- if (sum(cercanas) <= 0) sample.int(nrow(z), 1L)
      else sample.int(nrow(z), 1L, prob = cercanas)
  }
  z[elegidos, , drop = FALSE]
}

# Puntos al azar dentro del rango de cada variable: no son observaciones, y por
# eso pueden caer en zonas vacías. Es la peor de las tres, y está para que se
# vea la diferencia en la curva de convergencia.
.iniciar_aleatoria <- function(z, k) {
  rangos <- apply(z, 2L, range)
  matriz <- vapply(seq_len(ncol(z)), function(j)
    stats::runif(k, rangos[1, j], rangos[2, j]), numeric(k))
  matrix(matriz, nrow = k, ncol = ncol(z))
}

.iniciar_forgy <- function(z, k) z[sample.int(nrow(z), k), , drop = FALSE]
