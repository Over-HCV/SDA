# learn/R/nucleo/informe/codigos/cualitativos/gower.R
#
# Responsabilidad: el código R autónomo que agrupa con la disimilitud de
# Gower en el cuaderno (PAM o árbol jerárquico) y su dendrograma.
#
# Acá no hay nada que escribir a mano: el lab delega en cluster::daisy(),
# cluster::pam() y hclust(), y el cuaderno hace lo mismo. Lo que se repite es
# la regla de numeración (g1 = el grupo más grande) y, si se pidió, la
# codificación de las binarias asimétricas, que daisy() decide por el código
# del valor y no por su nombre.

.GOWER_DEFINICION <- r"---(
# Gower (1971): con solo factores es la fracción de variables en que
# difieren dos filas. PAM elige como centro de cada grupo una fila
# real (el medoide); el árbol fusiona de a dos, sin centro.
agrupar_gower <- function(x, k, estrategia = "pam",
                          enlace = "average", asimetricas = FALSE) {
@asimetricas@
  if (estrategia == "pam") {
    pam <- cluster::pam(d, k = k, diss = TRUE)
    grupos <- pam$clustering
    arbol <- NULL
    medoides <- pam$id.med
    # PAM solo devuelve el costo al cerrar BUILD y al cerrar SWAP.
    traza <- unname(pam$objective)
    eje <- "fase de PAM (0 = BUILD, 1 = SWAP)"
    criterio <- "disimilitud media al medoide"
  } else {
    arbol <- hclust(as.dist(d), method = enlace)
    grupos <- cutree(arbol, k = k)
    medoides <- NULL
    traza <- arbol$height  # la altura de cada fusión
    eje <- "fusión"
    criterio <- "altura de fusión"
  }
  # g1 es el grupo más grande; a igual tamaño, el número original.
  orden <- order(-tabulate(grupos, k), seq_len(k))
  list(grupos = setNames(match(grupos, orden), rownames(x)), k = k,
       x = x, d = d, arbol = arbol,
       medoides = if (is.null(medoides)) NULL else
         rownames(x)[medoides[orden]],
       objetivo = if (is.null(arbol)) tail(traza, 1) else NA,
       traza = traza, trazas = list(traza), criterio = criterio,
       eje = eje, asignaciones = NULL)
}
)---"

# Sin binarias asimétricas es una línea; con ellas, la regla del lab:
# la ausencia es el nivel que se llama así (no, 0, false, ausente) o, si
# ninguno, el primero. daisy() la quiere como 0.
.GOWER_SIMETRICA <- r"---(
  d <- cluster::daisy(x, metric = "gower")
)---"

.GOWER_ASIMETRICA <- r"---(
  # Binarias asimétricas: que dos filas NO tengan algo no las acerca
  # (Jaccard en esas columnas). daisy() quiere la ausencia como 0.
  binarias <- names(x)[sapply(x, function(v)
    is.factor(v) && nlevels(v) == 2)]
  if (!asimetricas) binarias <- character(0)
  for (v in binarias) {
    ausencia <- grep("^(no|0|false|ausente|n)$", levels(x[[v]]),
                     ignore.case = TRUE, value = TRUE)[1]
    if (is.na(ausencia)) ausencia <- levels(x[[v]])[1]
    x[[v]] <- as.integer(x[[v]] != ausencia)
  }
  d <- if (length(binarias))
    cluster::daisy(x, metric = "gower", type = list(asymm = binarias))
  else cluster::daisy(x, metric = "gower")
)---"

#' @return list(definicion, objeto, llamada)
.cq_ajuste_gower <- function(k, h) {
  estrategia <- h$estrategia %||% "pam"
  enlace <- h$enlace %||% "average"
  asimetricas <- isTRUE(h$binarias_asimetricas)
  objeto <- sprintf("gower_%s%d%s",
                    if (estrategia == "pam") "pam"
                    else gsub("[^a-z0-9]+", "_", tolower(enlace)),
                    k, if (asimetricas) "_asim" else "")
  cuerpo <- .cq_texto(if (asimetricas) .GOWER_ASIMETRICA
                      else .GOWER_SIMETRICA)
  list(definicion = .cq_texto(.GOWER_DEFINICION,
                              asimetricas = paste(cuerpo, collapse = "\n")),
       objeto = objeto,
       llamada = c(
         sprintf('%s <- agrupar_gower(cuali, k = %d,', objeto, k),
         sprintf('  estrategia = "%s", enlace = "%s",', estrategia,
                 enlace),
         sprintf('  asimetricas = %s)', asimetricas)))
}

#' El árbol con el corte en k. Con PAM no hay árbol que dibujar, y el chunk
#' lo dice en vez de dibujar otra cosa.
.cq_dendrograma <- function(p) {
  h <- p$hiper %||% list()
  if (!identical(h$estrategia, "jerarquico"))
    return(c("# PAM no construye un árbol: el dendrograma existe con",
             "# estrategia = jerarquico. Volvé al lab y pedilo así."))
  a <- .cq_ajuste(p)
  k <- as.integer(h$k %||% 3L)
  .cq_texto(r"---(
@ajuste@
arbol <- @obj@$arbol
plot(arbol, hang = -1, cex = 0.45, xlab = "", sub = "",
     main = "Gower, enlace @enlace@", ylab = "altura de fusión")
rect.hclust(arbol, k = @k@, border = seq_len(@k@) + 1)
# Correlación cofenética: cuánto respeta el árbol las disimilitudes
# originales (1 = las reproduce tal cual).
cofenetica <- cor(as.numeric(@obj@$d),
                  as.numeric(cophenetic(arbol)))
cat("Correlación cofenética:", round(cofenetica, 3), "\n")
)---", ajuste = paste(a$lineas, collapse = "\n"), obj = a$objeto,
    enlace = h$enlace %||% "average", k = k)
}
