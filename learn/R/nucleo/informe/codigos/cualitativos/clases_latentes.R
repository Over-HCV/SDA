# learn/R/nucleo/informe/codigos/cualitativos/clases_latentes.R
#
# Responsabilidad: el código R autónomo que ajusta clases latentes por EM en
# el cuaderno, con su tabla de BIC por k.
#
# Es el EM de `metodos/clases_latentes.R` sin poLCA, por la misma razón que
# allá: el estudiante ve los dos pasos y la verosimilitud subiendo. Mismo
# arranque (Dirichlet(1) con la semilla), mismo piso de 1e-300 dentro del
# logaritmo y mismo criterio de parada, así que con los mismos reinicios la
# log-verosimilitud coincide con la del lab hasta el redondeo.

.LATENTES_DEFINICION <- r"---(
# Clases latentes por EM, escrito a mano. Cada clase es una tabla
# de probabilidades por variable y, dentro de la clase, las
# variables son independientes. La partición es la clase más
# probable de cada fila.
em_latente <- function(Y, variable, k, semilla, maxit, tol) {
  set.seed(semilla)
  # Arranque: probabilidades al azar (Dirichlet(1)) y pesos iguales.
  theta <- matrix(rgamma(ncol(Y) * k, shape = 1), ncol = k)
  theta <- theta / rowsum(theta, variable)[variable, , drop = FALSE]
  pesos <- rep(1 / k, k)
  # Paso E: la posterior de cada fila en cada clase, en logaritmos
  # (el producto de dieciséis probabilidades es diminuto).
  paso_e <- function(theta, pesos) {
    log_f <- Y %*% log(pmax(theta, 1e-300)) +
      rep(log(pmax(pesos, 1e-300)), each = nrow(Y))
    tope <- apply(log_f, 1, max)
    suma <- rowSums(exp(log_f - tope))
    list(posterior = exp(log_f - tope - log(suma)),
         ll = sum(tope + log(suma)))
  }
  e <- paso_e(theta, pesos)
  traza <- e$ll
  historia <- max.col(e$posterior, ties.method = "first")
  pesos_iter <- pesos
  for (iteracion in seq_len(maxit)) {
    # Paso M: el peso es la masa posterior media de la clase; theta,
    # la fracción de esa masa que eligió cada categoría. Una clase
    # sin masa conserva su theta.
    masa <- colSums(e$posterior)
    vivas <- masa > 1e-300
    nueva <- crossprod(Y, e$posterior)
    theta[, vivas] <- sweep(nueva[, vivas, drop = FALSE], 2,
                            masa[vivas], "/")
    pesos <- masa / sum(masa)
    e <- paso_e(theta, pesos)
    traza <- c(traza, e$ll)
    historia <- cbind(historia,
                      max.col(e$posterior, ties.method = "first"))
    pesos_iter <- rbind(pesos_iter, pesos)
    # EM nunca baja la verosimilitud: se para cuando deja de subir.
    if (diff(tail(traza, 2)) < tol) break
  }
  list(pesos = pesos, theta = theta, posterior = e$posterior,
       ll = e$ll, traza = traza, historia = historia,
       pesos_iter = pesos_iter)
}

clases_latentes <- function(x, k, reinicios = 10, semilla = 42,
                            maxit = 1000, tol = 1e-8, k_max = 8) {
  # La indicadora: una columna por categoría, un 1 por variable.
  Y <- do.call(cbind, lapply(x, function(v)
    outer(as.integer(v), seq_len(nlevels(v)), "==") * 1))
  variable <- rep(seq_along(x), sapply(x, nlevels))
  semillas <- semilla + seq_len(reinicios) - 1
  intentos <- lapply(semillas, function(s)
    em_latente(Y, variable, k, s, maxit, tol))
  mejor <- intentos[[which.max(sapply(intentos, `[[`, "ll"))]]
  # Las clases se numeran por tamaño y, a igual tamaño, por peso.
  grupos <- max.col(mejor$posterior, ties.method = "first")
  orden <- order(-tabulate(grupos, k), -mejor$pesos)
  # BIC por k, con (k - 1) pesos + k * sum(R_j - 1) parámetros.
  # k = 1 es la independencia; el k pedido usa el ajuste de arriba
  # y el resto los mismos arranques (con menos, un k alto puede
  # quedar en un máximo local peor que el de un k menor). Se saltan los k con más
  # parámetros que celdas tiene la tabla (no identificables).
  n_par <- function(k) (k - 1) + k * sum(sapply(x, nlevels) - 1)
  ks <- seq_len(min(k_max, nrow(x) - 1))
  ks <- ks[log(n_par(ks) + 1) <= sum(log(sapply(x, nlevels)))]
  ll <- sapply(ks, function(kk) if (kk == k) mejor$ll else
    max(sapply(semilla + seq_len(reinicios) - 1, function(s)
      em_latente(Y, variable, kk, s, maxit, tol)$ll)))
  seleccion <- data.frame(k = ks, log_verosimilitud = ll,
                          n_parametros = n_par(ks),
                          bic = -2 * ll + n_par(ks) * log(nrow(x)),
                          aic = -2 * ll + 2 * n_par(ks))
  probabilidades <- lapply(seq_along(x), function(j) {
    bloque <- t(mejor$theta[variable == j, orden, drop = FALSE])
    dimnames(bloque) <- list(grupo = seq_len(k),
                             categoria = levels(x[[j]]))
    bloque
  })
  names(probabilidades) <- names(x)
  list(grupos = setNames(match(grupos, orden), rownames(x)), k = k,
       x = x, pesos = mejor$pesos[orden],
       probabilidades = probabilidades,
       posterior = mejor$posterior[, orden], ll = mejor$ll,
       bic = -2 * mejor$ll + n_par(k) * log(nrow(x)),
       seleccion = seleccion, traza = mejor$traza,
       trazas = lapply(intentos, `[[`, "traza"),
       criterio = "log-verosimilitud", eje = "iteración EM",
       asignaciones = matrix(match(mejor$historia, orden), nrow(x)),
       pesos_iter = mejor$pesos_iter[, orden, drop = FALSE])
}
)---"

#' @return list(definicion, objeto, llamada)
.cq_ajuste_latente <- function(k, k_max, reinicios, semilla, maxit) {
  objeto <- sprintf("clases%d", k)
  sangria <- strrep(" ", nchar(objeto) + 20L)
  list(definicion = .cq_texto(.LATENTES_DEFINICION), objeto = objeto,
       llamada = c(
         sprintf("%s <- clases_latentes(cuali, k = %d, reinicios = %d,",
                 objeto, k, reinicios),
         sprintf("%ssemilla = %d, maxit = %d,", sangria, semilla, maxit),
         sprintf("%stol = 1e-8, k_max = %d)", sangria, k_max)))
}
