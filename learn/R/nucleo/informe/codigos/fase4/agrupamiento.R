# learn/R/nucleo/informe/codigos/fase4/agrupamiento.R
#
# Responsabilidad: el código R autónomo de los paneles de agrupamiento en la
# fase 4 (codo, silueta, centroides, reparto, dendrograma y mapa de grupos),
# para k-medias y para el jerárquico.
#
# Ojo con k-medias: el lab tiene su propia implementación (k-means++ con
# reinicios) y el cuaderno usa stats::kmeans(), que es lo que el estudiante
# conoce. Con la misma k y la misma semilla los grupos casi siempre
# coinciden, pero la NUMERACIÓN de los grupos es arbitraria en los dos.

#' El ajuste del método de grupos de la entrada.
.f4_agrupar <- function(p) .f4_ajuste(p$metodo, p$hiper, p$semilla %||% 42L)

#' La inercia intra-grupo para k = 1..k_max y cuánto de la total explica
#' cada partición. "Reducción de varianza explicada" (pregunta 9) es esa
#' columna: 1 - W(k) / W(1), y W(1) es la inercia total.
.f4_codo <- function(p) {
  a <- .f4_agrupar(p)
  h <- p$hiper %||% list()
  k_max <- as.integer(p$k_max %||% 10L)
  k <- as.integer(h$k %||% h$k_corte %||% 3L)
  calculo <- if (identical(p$metodo, "kmeans")) c(
    sprintf("set.seed(%d)", as.integer(p$semilla %||% 42L)),
    sprintf("inercia <- sapply(seq_len(%d), function(k)", k_max),
    sprintf("  kmeans(z, centers = k, nstart = %d)$tot.withinss)",
            as.integer(h$reinicios %||% 100L)))
  else c(
    a$lineas,
    "# La inercia de cada corte del MISMO árbol: el jerárquico no se",
    "# reajusta por k, se corta más arriba o más abajo.",
    sprintf("inercia <- sapply(seq_len(%d), function(k) {", k_max),
    sprintf("  g <- cutree(%s, k = k)", a$objeto),
    "  sum(sapply(split(as.data.frame(z), g),",
    "             function(b) sum(scale(b, scale = FALSE)^2)))",
    "})")
  c(sprintf("z <- %s", a$z), calculo,
    sprintf("codo <- data.frame(k = seq_len(%d),", k_max),
    "  inercia = round(inercia, 1),",
    "  explicada = round(100 * (1 - inercia / inercia[1]), 1))",
    "print(codo, row.names = FALSE)",
    'plot(codo$k, codo$inercia, type = "b", pch = 19, xlab = "k",',
    '     ylab = "Inercia intra-grupo")',
    sprintf('abline(v = %d, lty = 2, col = "grey50")  # el k elegido', k))
}

#' Silueta de cada observación con la misma distancia del ajuste: con otra,
#' la silueta mediría una partición que el método nunca vio.
.f4_silueta <- function(p) {
  a <- .f4_agrupar(p)
  distancia <- p$hiper$distancia %||% "euclidean"
  c(a$lineas,
    sprintf("grupos <- %s", a$grupos),
    sprintf('distancias <- dist(%s, method = "%s")', a$z, distancia),
    "sil <- cluster::silhouette(grupos, distancias)",
    "# Imprime la silueta media por grupo y la global.",
    "fviz_silhouette(sil)")
}

#' Los centroides en unidades ORIGINALES: "este grupo produce tanto" se lee;
#' "este grupo está a 1.2 desvíos" hay que traducirlo. Una columna por grupo
#' porque con 57 variables una fila por grupo no entra en la página.
.f4_centroides <- function(p) {
  a <- .f4_agrupar(p)
  c(a$lineas,
    sprintf("grupos <- %s", a$grupos),
    "centroides <- aggregate(num, by = list(grupo = grupos), FUN = mean)",
    "perfil <- t(centroides[-1])",
    'colnames(perfil) <- paste("grupo", centroides$grupo)',
    "print(round(perfil, 2))")
}

#' Cuántos y QUIÉNES: un número de grupo solo no dice nada. Si la entrada
#' trae la partición de otro método, se cruzan las dos (pregunta 10).
.f4_grupos <- function(p) {
  a <- .f4_agrupar(p)
  otra <- p$grupos
  cruce <- if (!is.null(otra) && !identical(otra$metodo, p$metodo) &&
               (otra$metodo %||% "") %in% c("kmeans", "jerarquico")) c(
    "# Las dos particiones cruzadas: los números de grupo son",
    "# arbitrarios, lo que importa es si las filas se concentran.",
    sprintf("otra <- %s", .f4_ajuste(otra$metodo, otra$hiper)$grupos),
    sprintf("print(table(%s = grupos, %s = otra))", p$metodo, otra$metodo))
  c(a$lineas,
    sprintf("grupos <- %s", a$grupos),
    "print(table(grupos))",
    "print(split(rownames(num), grupos))",
    cruce)
}

.f4_dendrograma <- function(p) {
  a <- .f4_agrupar(p)
  k <- as.integer(p$hiper$k_corte %||% 3L)
  c(a$lineas,
    sprintf("plot(%s, hang = -1, cex = 0.5, xlab = \"\", sub = \"\",",
            a$objeto),
    sprintf('     main = "Enlace %s")', p$hiper$enlace %||% "ward.D2"),
    sprintf("rect.hclust(%s, k = %d, border = seq_len(%d) + 1)",
            a$objeto, k, k))
}

#' fviz_cluster proyecta la matriz sobre su propio ACP para dibujarla: con
#' la matriz escalada, es el mismo plano que el del ACP normado.
.f4_mapa_grupos <- function(p) {
  a <- .f4_agrupar(p)
  c(a$lineas,
    sprintf("grupos <- %s", a$grupos),
    sprintf("fviz_cluster(list(data = %s, cluster = grupos),", a$z),
    sprintf("             axes = %s, repel = TRUE, labelsize = 8,",
            .f4_ejes(p)),
    '             ellipse.type = "convex")')
}
