# learn/R/nucleo/informe/codigos/cualitativos/acm.R
#
# Responsabilidad: el ACM escrito a mano en el cuaderno —como función, para
# reusarla— y sus dos paneles: la inercia por dimensión y el primer plano.
#
# Es la cuenta de `metodos/acm.R` (y del tándem en fase4/cualitativo.R): la
# SVD de los residuos estandarizados de la indicadora. La necesitan también
# los paneles de grupos de k-modas, Gower y clases latentes, que dibujan su
# partición sobre el plano del ACM de los mismos factores, igual que el lab.

.ACM_DEFINICION <- r"---(
# ACM a mano: la SVD de los residuos estandarizados de la
# indicadora (una columna por categoría). Devuelve las coordenadas
# de filas y de categorías y la inercia de cada dimensión.
acm_coordenadas <- function(x, d = 2) {
  Z <- do.call(cbind, lapply(names(x), function(v) {
    niveles <- sort(unique(as.character(x[[v]])))
    bloque <- outer(as.character(x[[v]]), niveles, "==") * 1
    colnames(bloque) <- paste0(v, "=", niveles)
    bloque
  }))
  P <- Z / sum(Z)
  r <- rowSums(P)
  masas <- colSums(P)
  S <- (P - outer(r, masas)) / sqrt(outer(r, masas))
  descomposicion <- svd(S)
  ejes <- seq_len(d)
  filas <- sweep(descomposicion$u[, ejes, drop = FALSE], 2,
                 descomposicion$d[ejes], `*`) / sqrt(r)
  categorias <- sweep(descomposicion$v[, ejes, drop = FALSE], 2,
                      descomposicion$d[ejes], `*`) / sqrt(masas)
  dimnames(filas) <- list(rownames(x), paste0("Dim", ejes))
  dimnames(categorias) <- list(colnames(Z), paste0("Dim", ejes))
  # La inercia total es J/Q - 1 (categorías / variables - 1):
  # depende solo de cuántas categorías hay, y por eso los %
  # salen pesimistas.
  util <- seq_len(ncol(Z) - ncol(x))
  inercia <- descomposicion$d[util]^2 / (ncol(Z) / ncol(x) - 1)
  list(filas = filas, categorias = categorias, inercia = inercia,
       rotulos = sprintf("Dim%d (%.1f %%)", util, 100 * inercia))
}
)---"

.acm_definicion <- function() .cq_texto(.ACM_DEFINICION)

#' La inercia de cada dimensión: el scree del ACM. Las primeras diez.
.acm_scree <- function(p) {
  c(.cq_factores(p), .acm_definicion(), .cq_texto(r"---(
acm <- acm_coordenadas(cuali, 2)
usar <- seq_len(min(10, length(acm$inercia)))
acumulada <- cumsum(acm$inercia)[usar]
print(data.frame(dimension = usar,
                 inercia = round(100 * acm$inercia[usar], 2),
                 acumulada = round(100 * acumulada, 2)),
      row.names = FALSE)
barplot(100 * acm$inercia[usar], names.arg = usar, col = "#a6192e",
        xlab = "dimensión", ylab = "% de la inercia total")
)---"))
}

#' El primer plano del ACM: las filas (pintadas por la clase real si la
#' hay, que NO entró al ACM) y las categorías que lo construyen.
.acm_mapa_2d <- function(p) {
  ejes <- as.integer(p$ejes %||% c(1L, 2L))
  color <- p$color %||% p$clase
  pintar <- if (is.null(color)) c(
    "plano$color <- \"todas\"")
    else c("# La clase real no entró al ACM: solo pinta los puntos.",
           sprintf('plano$color <- datos[["%s"]][match(rownames(plano),',
                   color),
           "                                    filas)]")
  c(.cq_factores(p), .acm_definicion(),
    sprintf("ejes <- %s", .vector_r(ejes)),
    "acm <- acm_coordenadas(cuali, max(ejes))",
    "plano <- as.data.frame(acm$filas[, ejes])",
    "names(plano) <- c(\"x\", \"y\")",
    pintar,
    .cq_texto(r"---(
ggplot(plano, aes(x, y, color = color)) +
  geom_hline(yintercept = 0, color = "grey80") +
  geom_vline(xintercept = 0, color = "grey80") +
  geom_point(size = 2, alpha = 0.8) +
  geom_text(aes(label = rownames(plano)), size = 2.2, vjust = -0.9,
            check_overlap = TRUE, show.legend = FALSE) +
  labs(x = acm$rotulos[ejes[1]], y = acm$rotulos[ejes[2]],
       color = NULL, title = "ACM: las filas en el primer plano") +
  theme_minimal()
# Las categorías: las que caen lejos del origen construyen el eje.
categorias <- as.data.frame(acm$categorias[, ejes])
names(categorias) <- c("x", "y")
ggplot(categorias, aes(x, y, label = rownames(categorias))) +
  geom_hline(yintercept = 0, color = "grey80") +
  geom_vline(xintercept = 0, color = "grey80") +
  geom_point(color = "#a6192e") +
  geom_text(size = 2.4, vjust = -0.7, check_overlap = TRUE) +
  labs(x = acm$rotulos[ejes[1]], y = acm$rotulos[ejes[2]],
       title = "ACM: las categorías en el mismo plano") +
  theme_minimal()
)---"))
}
