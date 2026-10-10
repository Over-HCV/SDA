# learn/metodos/clases_latentes.R
#
# Responsabilidad: ajustar un modelo de clases latentes (mezcla de
# multinomiales) por EM escrito a mano, puro.
#
# Sin Shiny, sin input, sin reactive (S1/C3).
#
# Es la versión cualitativa de las mezclas gaussianas. Donde la mezcla
# gaussiana dice "cada grupo es una campana con su media y su covarianza", acá
# cada clase es una tabla de probabilidades por variable, y dentro de la clase
# las variables se suponen independientes (independencia local):
#
#   P(x_i) = Σ_c π_c Π_j θ_{j, x_ij, c}
#
# Lo que este método añade a k-modos y a PAM:
#
#   · Una asignación BLANDA: cada fila trae su probabilidad posterior de
#     pertenecer a cada clase, y la partición dura es solo el máximo de esa
#     fila. Un animal ambiguo se ve ambiguo, en vez de esconderse en un grupo.
#   · Un criterio con fundamento para elegir k: la verosimilitud es comparable
#     entre modelos, y el BIC la penaliza por los parámetros que cuesta.
#
# El EM está escrito a mano, sin poLCA. La razón es la de k-medias: poLCA
# devuelve el óptimo y se traga las iteraciones, que es lo que la fase 3
# muestra. poLCA solo aparece en las pruebas, como vara para medir.
#
# Diferencia con poLCA que conviene saber: poLCA puede usar filas con
# respuestas faltantes (las salta en el producto de la verosimilitud); acá se
# descartan las filas incompletas, igual que en el resto de la familia, y se
# cuentan en `filas_descartadas`. Con faltantes los dos ajustes no coinciden.
#
# La teoría está en fichas/clases_latentes.md.

#' Ajusta un modelo de clases latentes.
#'
#' @param datos      data.frame
#' @param columnas   columnas a usar; NULL = todas las no numéricas. Una
#'                   columna de texto sin repetidos (`animal`) se aparta
#'                   siempre y nombra las filas. Una numérica pedida a mano se
#'                   trata como factor. La clase real (`tipo`) la deja fuera
#'                   quien llama.
#' @param k          número de clases
#' @param reinicios  arranques aleatorios; se queda el de mayor verosimilitud
#' @param maxit      techo de iteraciones EM por arranque
#' @param tol        corte sobre la subida de la log-verosimilitud
#' @param semilla    gobierna el arranque (C13); el reinicio i usa semilla+i-1
#' @param k_max      hasta qué k se ajusta la tabla de selección por BIC
#' @param registrar_traza FALSE ahorra memoria en barridos grandes
#' @return list con grupos, posteriores, probabilidades por clase, BIC y traza
ajustar_clases_latentes <- function(datos, columnas = NULL, k = 3L,
                                    reinicios = 10L, maxit = 1000L,
                                    tol = 1e-8, semilla = 42L, k_max = 8L,
                                    registrar_traza = TRUE) {
  marco <- .preparar_marco_latente(datos, columnas)
  diseno <- .diseno_latente(marco$x)
  n <- nrow(marco$x)
  k <- as.integer(k)
  if (k < 2L) stop("clases latentes necesita al menos dos clases")
  if (k >= n) stop("hacen falta mas filas completas que clases: n = ", n,
                   ", k = ", k)
  if (!.identificable_latente(k, diseno))
    stop("con estas variables el modelo de ", k, " clases tiene mas ",
         "parametros que celdas tiene la tabla: no es identificable")
  reinicios <- max(1L, as.integer(reinicios))

  semillas <- semilla + seq_len(reinicios) - 1L
  intentos <- lapply(semillas, function(s)
    .correr_em_latente(diseno, k, maxit, tol, s, registrar_traza))
  mejor <- which.max(vapply(intentos, `[[`, numeric(1), "log_verosimilitud"))
  ganador <- .ordenar_clases_latentes(intentos[[mejor]], k)

  n_parametros <- .parametros_latentes(k, diseno)
  ll <- ganador$log_verosimilitud
  probabilidades <- .probabilidades_latentes(ganador$theta, diseno)
  posterior <- ganador$posterior
  dimnames(posterior) <- list(rownames(marco$x), paste0("g", seq_len(k)))

  structure(list(
    grupos = ganador$grupos, k = k, n = n, p = ncol(marco$x),
    tamanos = tabulate(ganador$grupos, nbins = k),
    x = marco$x, columnas = names(marco$x),
    filas_descartadas = marco$descartadas, semilla = semilla,
    modos = .modos_latentes(probabilidades, marco$x),
    probabilidades = probabilidades,
    pesos = stats::setNames(ganador$pi, paste0("g", seq_len(k))),
    posterior = posterior,
    log_verosimilitud = ll, n_parametros = n_parametros,
    bic = -2 * ll + n_parametros * log(n),
    aic = -2 * ll + 2 * n_parametros,
    entropia_relativa = .entropia_relativa_latente(posterior),
    seleccion = .seleccion_latente(diseno, k_max, reinicios, maxit,
                                   tol, semilla, k, ll),
    reinicios = reinicios, maxit = maxit, tol = tol,
    semilla_ganadora = semillas[mejor],
    iteraciones = ganador$iteraciones, convergio = ganador$convergio,
    traza = ganador$traza,
    trazas_reinicios = stats::setNames(lapply(intentos, `[[`, "traza"),
                                       as.character(semillas)),
    asignaciones_por_iter = ganador$asignaciones),
    class = c("ajuste_clases_latentes", "ajuste_cualitativo",
              "ajuste_agrupamiento", "ajuste_sda"))
}

# ---------------------------------------------------------------------------
# Lo que entra al modelo
# ---------------------------------------------------------------------------

# Factores completos, con la etiqueta de la fila como rownames. Se preparan con
# preparar_factores_grupos() (metodos/kmodos.R), la misma puerta que k-modas:
# si cada método decidiera a su manera qué columna es un nombre (`animal`) y
# qué filas entran, comparar sus particiones sería comparar datos distintos.
# Lo único que se añade es el mínimo de variables: con una sola, una mezcla de
# clases no es identificable (hay más parámetros que categorías).
.preparar_marco_latente <- function(datos, columnas) {
  marco <- preparar_factores_grupos(as.data.frame(datos), columnas,
                                    "clases latentes")
  if (ncol(marco$x) < 2L)
    stop("clases latentes necesita al menos dos variables cualitativas")
  marco
}

# La matriz indicadora n x J y a qué variable pertenece cada columna. Con ella
# el paso E es un solo producto de matrices: log f_c(x_i) = Y · log θ.
.diseno_latente <- function(x) {
  bloques <- lapply(x, function(v) {
    y <- outer(as.integer(v), seq_len(nlevels(v)), "==") * 1
    colnames(y) <- levels(v)
    y
  })
  list(y = do.call(cbind, bloques),
       variable = rep(seq_along(bloques), vapply(bloques, ncol, integer(1))),
       categorias = lapply(x, levels), nombres = names(x))
}

# (k − 1) pesos libres + k · Σ (R_j − 1) probabilidades libres.
.parametros_latentes <- function(k, diseno) {
  libres <- sum(lengths(diseno$categorias) - 1L)
  (k - 1L) + k * libres
}

# Condición necesaria (no suficiente) de identificabilidad: no puede haber más
# parámetros que celdas libres en la tabla completa Π R_j − 1. Se compara en
# logaritmos porque con 16 variables el producto no cabe en un entero.
.identificable_latente <- function(k, diseno) {
  log_celdas <- sum(log(lengths(diseno$categorias)))
  log(.parametros_latentes(k, diseno) + 1) <= log_celdas
}

# ---------------------------------------------------------------------------
# El EM
# ---------------------------------------------------------------------------

# Arranque: probabilidades de cada clase al azar (Dirichlet(1), vía gammas) y
# pesos iguales. Arrancar desde una partición dura heredaría los defectos de
# k-modos; arrancar desde θ al azar es lo que hace poLCA.
.arranque_latente <- function(diseno, k) {
  theta <- matrix(stats::rgamma(ncol(diseno$y) * k, shape = 1),
                  ncol = k)
  theta <- .normalizar_bloques_latente(theta, diseno$variable)
  list(pi = rep(1 / k, k), theta = theta)
}

.normalizar_bloques_latente <- function(theta, variable) {
  sumas <- rowsum(theta, variable)
  theta / sumas[variable, , drop = FALSE]
}

# Paso E. El piso entra SOLO dentro del logaritmo: θ = 0 es una solución de
# frontera legítima (ningún animal con plumas en la clase de los peces) y el
# paso M la produce exacta. Sin piso, 0 · log 0 da NaN en el producto de
# matrices; con un piso de 1e-300 la celda vale −690 en log, que ya es cero en
# la posterior. No se suaviza θ (nada de Laplace): eso cambiaría el óptimo y
# dejaría de coincidir con poLCA.
.paso_e_latente <- function(diseno, parametros) {
  log_theta <- log(pmax(parametros$theta, 1e-300))
  log_f <- diseno$y %*% log_theta +
    rep(log(pmax(parametros$pi, 1e-300)), each = nrow(diseno$y))
  # log-sum-exp por fila: restar el máximo evita que exp() dé cero en todas las
  # clases cuando el producto de 16 probabilidades es diminuto.
  tope <- apply(log_f, 1L, max)
  suma <- rowSums(exp(log_f - tope))
  list(posterior = exp(log_f - tope - log(suma)),
       log_verosimilitud = sum(tope + log(suma)))
}

# Paso M: los pesos son la masa posterior media de cada clase, y θ_jrc la
# fracción de esa masa que eligió la categoría r. Como cada fila marca una sola
# categoría por variable, los bloques ya suman 1 sin normalizar. Una clase sin
# masa conserva su θ anterior en vez de dividir 0 entre 0.
.paso_m_latente <- function(diseno, posterior, anterior) {
  masa <- colSums(posterior)
  theta <- crossprod(diseno$y, posterior)
  vivas <- masa > 1e-300
  theta[, vivas] <- sweep(theta[, vivas, drop = FALSE], 2L, masa[vivas], "/")
  theta[, !vivas] <- anterior$theta[, !vivas]
  list(pi = masa / sum(masa), theta = theta)
}

.correr_em_latente <- function(diseno, k, maxit, tol, semilla,
                               registrar_traza) {
  set.seed(semilla)
  parametros <- .arranque_latente(diseno, k)
  e <- .paso_e_latente(diseno, parametros)
  ll <- e$log_verosimilitud
  traza <- if (registrar_traza)
    nueva_traza("log-verosimilitud", sentido = "asciende") else NULL
  asignaciones <- if (registrar_traza)
    matrix(max.col(e$posterior, ties.method = "first"), ncol = 1L) else NULL
  if (!is.null(traza))
    traza <- registrar_iteracion(traza, iter = 0L, objetivo = ll,
                                 delta = NA_real_, componente = 1L,
                                 parametros = .pesos_planos_latente(
                                   parametros$pi))
  convergio <- FALSE
  iteraciones <- 0L

  for (iteracion in seq_len(maxit)) {
    parametros <- .paso_m_latente(diseno, e$posterior, parametros)
    e <- .paso_e_latente(diseno, parametros)
    delta <- e$log_verosimilitud - ll
    ll <- e$log_verosimilitud
    iteraciones <- iteracion
    if (!is.null(traza)) {
      traza <- registrar_iteracion(traza, iter = iteracion, objetivo = ll,
                                   delta = delta, componente = 1L,
                                   parametros = .pesos_planos_latente(
                                     parametros$pi))
      asignaciones <- cbind(asignaciones,
                            max.col(e$posterior, ties.method = "first"))
    }
    # EM nunca baja la verosimilitud; un delta negativo solo puede ser ruido
    # de redondeo en la meseta, y también es convergencia.
    if (delta < tol) { convergio <- TRUE; break }
  }

  list(pi = parametros$pi, theta = parametros$theta, posterior = e$posterior,
       grupos = max.col(e$posterior, ties.method = "first"),
       log_verosimilitud = ll, iteraciones = iteraciones,
       convergio = convergio, traza = traza, asignaciones = asignaciones)
}

.pesos_planos_latente <- function(pesos)
  stats::setNames(as.numeric(pesos), paste0("pi_g", seq_along(pesos)))

# ---------------------------------------------------------------------------
# Las etiquetas de las clases
# ---------------------------------------------------------------------------

# Cambio de etiquetas (label switching): la verosimilitud es la misma con las
# clases permutadas, así que el número de una clase no significa nada y dos
# arranques que llegan al mismo óptimo pueden llamarlo distinto. Se fija un
# orden: por tamaño de la partición dura, descendente, y a igual tamaño por
# peso. Se permuta TODO a la vez —pesos, θ, posteriores, la traza— o la clase 1
# de una tabla sería la 3 de otra.
.ordenar_clases_latentes <- function(resultado, k) {
  tamanos <- tabulate(resultado$grupos, nbins = k)
  orden <- order(-tamanos, -resultado$pi)
  resultado$pi <- resultado$pi[orden]
  resultado$theta <- resultado$theta[, orden, drop = FALSE]
  resultado$posterior <- resultado$posterior[, orden, drop = FALSE]
  resultado$grupos <- match(resultado$grupos, orden)
  if (!is.null(resultado$asignaciones))
    resultado$asignaciones[] <- match(resultado$asignaciones, orden)
  if (!is.null(resultado$traza))
    resultado$traza$filas <- lapply(resultado$traza$filas, function(f) {
      f$parametros <- stats::setNames(f$parametros[orden], names(f$parametros))
      f
    })
  resultado
}

# ---------------------------------------------------------------------------
# Lo que se devuelve
# ---------------------------------------------------------------------------

.probabilidades_latentes <- function(theta, diseno) {
  partes <- lapply(seq_along(diseno$nombres), function(j) {
    bloque <- t(theta[diseno$variable == j, , drop = FALSE])
    dimnames(bloque) <- list(paste0("g", seq_len(nrow(bloque))),
                             diseno$categorias[[j]])
    bloque
  })
  stats::setNames(partes, diseno$nombres)
}

# La categoría más probable de cada variable en cada clase: el "retrato" de la
# clase, comparable con los modos de k-modos.
.modos_latentes <- function(probabilidades, x) {
  modos <- as.data.frame(lapply(names(probabilidades), function(nombre) {
    bloque <- probabilidades[[nombre]]
    factor(colnames(bloque)[max.col(bloque, ties.method = "first")],
           levels = levels(x[[nombre]]))
  }), stringsAsFactors = FALSE)
  names(modos) <- names(probabilidades)
  rownames(modos) <- paste0("g", seq_len(nrow(modos)))
  modos
}

# 1 − H / (n log k): 1 si cada fila cae entera en una clase, 0 si todas las
# posteriores son uniformes. Mide qué tan nítida es la partición, no qué tan
# buena; un modelo sobreajustado también es nítido.
.entropia_relativa_latente <- function(posterior) {
  terminos <- posterior * log(posterior)
  terminos[posterior <= 0] <- 0
  1 - (-sum(terminos)) / (nrow(posterior) * log(ncol(posterior)))
}

# El BIC para k = 1..k_max, con los MISMOS reinicios que el ajuste principal.
# Con arranques baratos (eran 5) un k alto podía quedar en un máximo local peor
# que el de un k menor (en Zoo, k = 8 salía con menos verosimilitud que k = 7),
# y eso es imposible para el máximo verdadero: la curva del BIC mentía. k = 1 es
# el modelo de independencia, la vara contra la que se mide si hay clases. En la
# fila del k pedido se reusa la verosimilitud del ajuste principal. Los k no
# identificables se saltan.
.seleccion_latente <- function(diseno, k_max, reinicios, maxit, tol, semilla,
                               k, ll_principal) {
  n <- nrow(diseno$y)
  ks <- seq_len(max(1L, min(as.integer(k_max), n - 1L)))
  ks <- ks[vapply(ks, .identificable_latente, logical(1), diseno = diseno)]
  filas <- lapply(ks, function(kk) {
    ll <- if (kk == k) ll_principal else
      max(vapply(semilla + seq_len(reinicios) - 1L, function(s)
        .correr_em_latente(diseno, kk, maxit, tol, s,
                           FALSE)$log_verosimilitud, numeric(1)))
    n_par <- .parametros_latentes(kk, diseno)
    data.frame(k = kk, log_verosimilitud = ll, n_parametros = n_par,
               bic = -2 * ll + n_par * log(n), aic = -2 * ll + 2 * n_par)
  })
  do.call(rbind, filas)
}
