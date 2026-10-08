# learn/R/nucleo/informe/codigos/fase4/reduccion.R
#
# Responsabilidad: el código R autónomo de los paneles del ACP en la fase 4
# (scree, reglas de retención, cargas, contribuciones, calidad, círculo de
# correlaciones y mapa de individuos).
#
# Se dibuja con factoextra porque es lo que sugiere el enunciado del Taller
# 02 (fviz_pca_var, fviz_pca_ind) y porque deja elegir el plano con `axes`:
# el (2, 3) que pide la pregunta 5 sale cambiando un número.

#' El ajuste del ACP y el nombre del objeto, para no repetirlo en cada uno.
.f4_acp <- function(p) .f4_ajuste("acp", p$hiper, p$semilla %||% 42L)

.f4_scree <- function(p) {
  a <- .f4_acp(p)
  ncp <- max(10L, as.integer(p$hiper$n_componentes %||% 2L))
  c(a$lineas,
    sprintf("fviz_eig(%s, addlabels = TRUE, ncp = %d)", a$objeto, ncp))
}

#' Kaiser y el porcentaje acumulado, con los números a la vista: la pregunta
#' 4 pide el criterio, y un criterio sin su cifra no se puede defender.
.f4_reglas_k <- function(p) {
  a <- .f4_acp(p)
  umbral <- p$acumulado %||% 0.8
  c(a$lineas,
    sprintf("autovalores <- %s$sdev^2", a$objeto),
    "varianza <- autovalores / sum(autovalores)",
    "reglas <- data.frame(",
    "  componente = seq_along(autovalores),",
    "  autovalor = round(autovalores, 3),",
    "  porcentaje = round(100 * varianza, 2),",
    "  acumulado = round(100 * cumsum(varianza), 2))",
    "print(head(reglas, 12), row.names = FALSE)",
    "# Kaiser: autovalor por encima del promedio. Con la matriz de",
    "# correlación el promedio es 1: la componente explica más que una",
    "# variable original sola.",
    'cat("Kaiser:", sum(autovalores > mean(autovalores)),',
    '    "componentes\\n")',
    sprintf('cat("%s %% acumulado:",', format(100 * umbral)),
    sprintf("    which(cumsum(varianza) >= %s)[1], \"componentes\\n\")",
            format(umbral)))
}

#' Contribución de cada variable al PLANO (no a un eje): factoextra la pondera
#' por el autovalor de cada eje. La tabla va antes del gráfico porque es lo
#' que se compara entre el ACP normado y el crudo (pregunta 3).
.f4_contribuciones <- function(p) {
  a <- .f4_acp(p)
  ejes <- .f4_ejes(p)
  top <- as.integer(p$top %||% 30L)
  c(a$lineas,
    sprintf('aporte <- facto_summarize(%s, "var", axes = %s)',
            a$objeto, ejes),
    "aporte <- aporte[order(-aporte$contrib), c(\"name\", \"contrib\")]",
    "print(head(aporte, 10), row.names = FALSE, digits = 3)",
    sprintf('fviz_contrib(%s, choice = "var", axes = %s,', a$objeto, ejes),
    sprintf("             top = %d)", top))
}

#' Las `top` variables que más construyen el plano, con rótulos chicos y
#' separados: con 57 flechas a tamaño normal el círculo es una mancha.
.f4_circulo <- function(p) {
  a <- .f4_acp(p)
  c(a$lineas,
    sprintf("fviz_pca_var(%s, axes = %s,", a$objeto, .f4_ejes(p)),
    sprintf("             select.var = list(contrib = %d),",
            as.integer(p$top %||% 30L)),
    '             col.var = "contrib", labelsize = 2, repel = TRUE)')
}

#' Las cargas son los vectores propios (`rotation`), con signo: el signo dice
#' hacia qué lado del eje empuja cada variable. Se ordenan por su peso en el
#' primer eje del plano elegido.
.f4_cargas <- function(p) {
  a <- .f4_acp(p)
  ejes <- p$ejes %||% c(1L, 2L)
  n <- max(as.integer(p$hiper$n_componentes %||% 2L), as.integer(ejes))
  c(a$lineas,
    sprintf("cargas <- %s$rotation[, seq_len(%d), drop = FALSE]",
            a$objeto, n),
    sprintf("orden <- order(-abs(cargas[, %d]))", as.integer(ejes[1])),
    sprintf("print(round(head(cargas[orden, ], %d), 3))",
            as.integer(p$top %||% 30L)))
}

#' cos² de las variables en el plano: qué fracción de cada una es lo que se
#' está viendo en el círculo.
.f4_calidad <- function(p) {
  a <- .f4_acp(p)
  c(a$lineas,
    sprintf('fviz_cos2(%s, choice = "var", axes = %s,', a$objeto,
            .f4_ejes(p)),
    sprintf("          top = %d)", as.integer(p$top %||% 30L)))
}

#' El plano de individuos. Con ACP es fviz_pca_ind, coloreado por los
#' grupos si la entrada los trae; con k-medias o jerárquico, fviz_cluster,
#' que proyecta la matriz sobre SU propio ACP para poder dibujarla.
.f4_mapa_2d <- function(p) {
  if (!identical(p$metodo, "acp")) return(.f4_mapa_grupos(p))
  a <- .f4_acp(p)
  color <- if (!is.null(p$grupos) && !is.null(.f4_adjuntar_grupos(p$grupos)))
    .f4_ajuste(p$grupos$metodo, p$grupos$hiper)$grupos else NULL
  c(a$lineas,
    sprintf("fviz_pca_ind(%s, axes = %s, repel = TRUE,", a$objeto,
            .f4_ejes(p)),
    if (is.null(color)) "             labelsize = 3)"
    else c("             labelsize = 3,",
           sprintf("             habillage = factor(%s))", color)))
}
