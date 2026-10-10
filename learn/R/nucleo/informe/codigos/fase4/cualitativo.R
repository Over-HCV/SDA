# learn/R/nucleo/informe/codigos/fase4/cualitativo.R
#
# Responsabilidad: el código R autónomo del tándem ACM + agrupamiento y del
# cruce de una partición con la clase real, para el cuaderno exportado.
#
# El tándem llega en `params$reduccion` (lo arma la consola con `--reduccion
# acm`): el chunk rehace el ACM a mano —la misma cuenta de metodos/acm.R— y
# sus coordenadas REEMPLAZAN a `num`, así que el k-medias que sigue agrupa
# sobre ellas sin que su generador sepa que hubo un ACM antes.
#
# El ARI se escribe a mano en el chunk por la misma razón que en el lab: cero
# dependencias nuevas para quien entrega el taller.

#' El ACM de las columnas de la receta, dejando sus dimensiones en `num`.
#' @param reduccion list(metodo, hiper, columnas, dimensiones), o NULL
.f4_reduccion <- function(reduccion) {
  if (is.null(reduccion) || !identical(reduccion$metodo, "acm")) return(NULL)
  d <- as.integer(reduccion$hiper$n_componentes %||%
                    length(reduccion$dimensiones %||% 1:2))
  c("# Tándem, primera mitad: el ACM de los factores, escrito a mano",
    "# (es la misma cuenta que hace el lab). Sus coordenadas reemplazan",
    "# a `num`, y el agrupamiento de abajo trabaja sobre ellas.",
    .f4_vector_plegado("columnas_acm", reduccion$columnas, 66L),
    "cuali <- datos[columnas_acm]",
    "rownames(cuali) <- filas",
    "cuali <- na.omit(cuali)",
    "# La indicadora: una columna por categoría, un 1 por variable",
    "# y fila.",
    "Z <- do.call(cbind, lapply(cuali, function(v) {",
    "  v <- as.character(v)",
    "  outer(v, sort(unique(v)), \"==\") * 1",
    "}))",
    "P <- Z / sum(Z)",
    "r <- rowSums(P)",
    "masas <- colSums(P)",
    "S <- (P - outer(r, masas)) / sqrt(outer(r, masas))",
    "descomposicion <- svd(S)",
    sprintf("d <- %d", d),
    "num <- as.data.frame(sweep(descomposicion$u[, 1:d, drop = FALSE], 2,",
    "                           descomposicion$d[1:d], `*`) / sqrt(r))",
    "names(num) <- paste0(\"Dim\", 1:d)",
    "rownames(num) <- rownames(cuali)",
    "# La inercia total del ACM es J/Q - 1: depende solo de cuántas",
    "# categorías hay, y por eso estos porcentajes salen pesimistas.",
    "inercia <- descomposicion$d^2 / (ncol(Z) / ncol(cuali) - 1)",
    "cat(\"Inercia por dimensión (%):\",",
    "    round(100 * inercia[1:d], 1), \"\\n\")")
}

#' La partición contra la clase real: la tabla y el ARI de Hubert y Arabie.
.f4_cruce_clase <- function(p) {
  a <- .f4_agrupar(p)
  c(a$lineas,
    sprintf("grupos <- %s", a$grupos),
    .f4_cruce_lineas("rownames(num)", p$clase))
}

#' El cruce de `grupos` (ya definido en el chunk) con la clase, el ARI, la
#' pureza y el mapa de calor. Lo comparten k-medias y los métodos
#' cualitativos (cualitativos/paneles.R): solo cambia de dónde salen las
#' filas que entraron al ajuste.
#' @param filas_ajuste expresión R con los nombres de esas filas
.f4_cruce_lineas <- function(filas_ajuste, clase) {
  c("# La clase real NO entró al ajuste: se alinea recién acá, por",
    "# nombre de fila.",
    sprintf("clase <- datos[[\"%s\"]][match(%s, filas)]", clase,
            filas_ajuste),
    "cruce <- table(grupo = grupos, clase = clase)",
    "print(cruce)",
    "# Índice de Rand ajustado: pares que las dos particiones dejan",
    "# juntos, corregido por el acuerdo que daría el azar con los",
    "# mismos tamaños.",
    "ari <- function(a, b) {",
    "  tabla <- table(a, b)",
    "  pares <- function(v) sum(choose(v, 2))",
    "  filas_t <- pares(rowSums(tabla))",
    "  columnas_t <- pares(colSums(tabla))",
    "  esperado <- filas_t * columnas_t / choose(sum(tabla), 2)",
    "  maximo <- (filas_t + columnas_t) / 2",
    "  (pares(tabla) - esperado) / (maximo - esperado)",
    "}",
    "pureza <- sum(apply(cruce, 1, max)) / length(grupos)",
    "cat(\"ARI =\", round(ari(grupos, clase), 3),",
    "    \"· pureza =\", round(100 * pureza), \"%\\n\")",
    "# Se busca que cada FILA (grupo) se concentre en una columna: la",
    "# numeración de los grupos es arbitraria: no hay diagonal.",
    "celdas <- as.data.frame(prop.table(cruce, 1), responseName = \"p\")",
    "celdas$n <- as.data.frame(cruce)$Freq",
    "ggplot(celdas, aes(clase, grupo, fill = p)) +",
    "  geom_tile(color = \"white\") +",
    "  geom_text(aes(label = ifelse(n > 0, n, \"\")), size = 3) +",
    "  scale_fill_gradient(low = \"grey97\", high = \"#a6192e\",",
    "                      limits = c(0, 1), name = \"en el grupo\") +",
    "  labs(x = \"clase real\", y = \"grupo\") +",
    "  theme_minimal() +",
    "  theme(axis.text.x = element_text(angle = 30, hjust = 1))")
}

# `nombre <- c("a", "b", ...)` partido en renglones de menos de 78 columnas:
# dieciséis variables en una sola línea no se leen ni se corrigen a mano.
.f4_vector_plegado <- function(nombre, valores, ancho = 78L) {
  piezas <- sprintf('"%s"', valores)
  lineas <- character(0)
  actual <- sprintf("%s <- c(", nombre)
  sangria <- strrep(" ", nchar(actual))
  for (i in seq_along(piezas)) {
    pieza <- paste0(piezas[i], if (i < length(piezas)) "," else ")")
    if (nchar(actual) + nchar(pieza) + 1L > ancho &&
        !grepl("\\($", actual)) {
      lineas <- c(lineas, actual)
      actual <- paste0(sangria, pieza)
    } else actual <- if (grepl("\\($", actual)) paste0(actual, pieza)
                     else paste(actual, pieza)
  }
  c(lineas, actual)
}
