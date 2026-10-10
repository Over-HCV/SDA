# learn/R/nucleo/informe/codigos/cualitativos/paneles.R
#
# Responsabilidad: el código R autónomo de los paneles que comparten los tres
# métodos cualitativos —reparto, cruce con la clase, silueta, modos, plano
# del ACM, BIC— y los de la fase 3 (convergencia, trayectoria, estado).
#
# Todos leen el contrato del ajuste del cuaderno (ver despacho.R): grupos,
# x, traza, trazas, criterio, eje, asignaciones. Por eso un panel se escribe
# una vez y sirve para k-modas, Gower y clases latentes.

# El ajuste del panel y un texto con `@obj@` reemplazado por su nombre.
.cq_panel <- function(p, texto, ...) {
  a <- .cq_ajuste(p)
  c(a$lineas, .cq_texto(texto, obj = a$objeto, ...))
}

#' Cuántos y QUIÉNES: el número de grupo solo no dice nada.
.cq_grupos <- function(p) .cq_panel(p, r"---(
grupos <- @obj@$grupos
print(table(grupo = grupos))
print(split(names(grupos), grupos))
barplot(table(grupos), col = "#a6192e", xlab = "grupo",
        ylab = "filas", main = "Tamaño de cada grupo")
)---")

#' La partición contra la clase real (que no entró al ajuste).
.cq_cruce_clase <- function(p) {
  a <- .cq_ajuste(p)
  c(a$lineas, sprintf("grupos <- %s$grupos", a$objeto),
    .f4_cruce_lineas("names(grupos)", p$clase))
}

#' La silueta con la disimilitud del método: Gower si la usó; si no, el
#' emparejamiento simple, que con solo factores es exactamente Gower.
.cq_silueta <- function(p) {
  distancia <- if (identical(p$metodo, "gower")) "d <- @obj@$d" else c(
    "# Con solo factores, Gower es el emparejamiento simple dividido",
    "# por p: la misma disimilitud que usa el método.",
    "d <- cluster::daisy(@obj@$x, metric = \"gower\")")
  .cq_panel(p, paste(c(distancia,
    "sil <- cluster::silhouette(@obj@$grupos, d)",
    "# Imprime la silueta media por grupo y la global.",
    "fviz_silhouette(sil)"), collapse = "\n"))
}

#' El retrato de cada grupo: la proporción de cada categoría dentro del
#' grupo (en clases latentes, la probabilidad estimada) y su moda.
.cq_modos <- function(p) {
  proporcion <- if (identical(p$metodo, "clases_latentes")) c(
    "  # En clases latentes el retrato es el modelo: theta por clase.",
    "  tabla <- as.table(@obj@$probabilidades[[v]])")
    else c("  tabla <- prop.table(table(grupo = grupos,",
           "                              categoria = x[[v]]), 1)")
  c("#| fig-height: 9",
    .cq_panel(p, paste(c(r"---(
x <- @obj@$x
grupos <- @obj@$grupos
perfil <- do.call(rbind, lapply(names(x), function(v) {)---",
    proporcion, r"---(
  data.frame(variable = v,
             as.data.frame(tabla, responseName = "proporcion"))
}))
perfil$grupo <- factor(perfil$grupo)
# La moda de cada grupo en cada variable (empate: el primer nivel).
modas <- sapply(split(perfil, perfil$variable), function(b)
  tapply(seq_len(nrow(b)), b$grupo, function(i)
    as.character(b$categoria[i][which.max(b$proporcion[i])])))
print(t(modas)[names(x), ])
ggplot(perfil, aes(grupo, categoria, fill = proporcion)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(100 * proporcion)), size = 2.2) +
  facet_grid(variable ~ ., scales = "free_y", space = "free_y",
             switch = "y") +
  scale_fill_gradient(low = "grey97", high = "#a6192e",
                      limits = c(0, 1), name = "en el grupo") +
  labs(x = "grupo", y = NULL) +
  theme_minimal(base_size = 9) +
  theme(strip.placement = "outside",
        strip.text.y.left = element_text(angle = 0, hjust = 1),
        panel.spacing.y = unit(1, "pt"))
)---"), collapse = "\n")))
}

#' La partición sobre el primer plano del ACM de los mismos factores. Es un
#' dibujo: los grupos viven en las p variables, el plano muestra la parte de
#' la asociación que cabe en dos dimensiones.
.cq_mapa_2d <- function(p) {
  color <- p$color
  pintar <- if (is.null(color)) "plano$color <- factor(@obj@$grupos)"
    else c(sprintf('plano$color <- datos[["%s"]][match(rownames(plano),',
                   color),
           "                                    filas)]")
  a <- .cq_ajuste(p)
  c(a$lineas, .acm_definicion(),
    sprintf("ejes <- %s", .vector_r(p$ejes %||% c(1L, 2L))),
    .cq_texto(paste(c(
      "acm <- acm_coordenadas(@obj@$x, max(ejes))",
      "plano <- as.data.frame(acm$filas[, ejes])",
      "names(plano) <- c(\"x\", \"y\")", pintar, r"---(
ggplot(plano, aes(x, y, color = color)) +
  geom_point(size = 2, alpha = 0.8) +
  geom_text(aes(label = rownames(plano)), size = 2.2, vjust = -0.9,
            check_overlap = TRUE, show.legend = FALSE) +
  labs(x = acm$rotulos[ejes[1]], y = acm$rotulos[ejes[2]],
       color = NULL, title = "Los grupos sobre el plano del ACM") +
  theme_minimal()
)---"), collapse = "\n"), obj = a$objeto))
}

#' BIC y AIC por k: menor es mejor; el círculo marca el mínimo de cada uno
#' y la línea punteada, el k elegido.
.cq_bic <- function(p) .cq_panel(p, r"---(
seleccion <- @obj@$seleccion
print(seleccion, row.names = FALSE, digits = 6)
matplot(seleccion$k, seleccion[c("bic", "aic")], type = "b",
        pch = 19, lty = 1, col = c("#a6192e", "grey40"),
        xlab = "número de clases (k)",
        ylab = "criterio (menor es mejor)")
points(seleccion$k[which.min(seleccion$bic)], min(seleccion$bic),
       cex = 2.5, col = "#a6192e")
points(seleccion$k[which.min(seleccion$aic)], min(seleccion$aic),
       cex = 2.5, col = "grey40")
abline(v = @obj@$k, lty = 3)
legend("topright", c("BIC", "AIC"), col = c("#a6192e", "grey40"),
       pch = 19, bty = "n")
)---")

#' Fase 3. El objetivo por iteración del reinicio ganador, sobre los demás
#' reinicios en gris: si todos caen al mismo valor, el óptimo es estable.
.cq_convergencia <- function(p) .cq_panel(p, r"---(
trazas <- @obj@$trazas
traza <- @obj@$traza
plot(NULL, xlim = c(0, max(lengths(trazas)) - 1),
     ylim = range(unlist(trazas)), xlab = @obj@$eje,
     ylab = @obj@$criterio, main = "Convergencia")
for (t in trazas) lines(seq_along(t) - 1, t, col = "grey75")
lines(seq_along(traza) - 1, traza, type = "b", pch = 19,
      lwd = 2, col = "#a6192e")
finales <- sapply(trazas, function(t) t[length(t)])
cat("Iteraciones del ganador:", length(traza) - 1,
    "· objetivo final:", round(traza[length(traza)], 4), "\n")
cat("Reinicios que llegaron a ese valor:",
    sum(abs(finales - traza[length(traza)]) < 1e-6), "de",
    length(trazas), "\n")
)---")

#' Fase 3. Lo que se mueve entre iteraciones: en k-modas, cuántas filas
#' cambian de grupo; en clases latentes, los pesos; en Gower, el tamaño
#' del grupo mayor tras cada fusión (PAM no deja estados intermedios).
.cq_trayectoria <- function(p) {
  texto <- switch(p$metodo,
    kmodos = r"---(
A <- @obj@$asignaciones
antes <- A[, -ncol(A), drop = FALSE]
despues <- A[, -1, drop = FALSE]
cambios <- colSums(despues != antes)
print(data.frame(barrido = seq_along(cambios),
                 filas_que_cambian = cambios), row.names = FALSE)
barplot(cambios, names.arg = seq_along(cambios), col = "#a6192e",
        xlab = "barrido", ylab = "filas que cambian de grupo")
)---",
    clases_latentes = r"---(
pesos <- @obj@$pesos_iter
matplot(seq_len(nrow(pesos)) - 1, pesos, type = "l", lty = 1,
        lwd = 2, xlab = "iteración EM", ylab = "peso de la clase")
legend("topright", paste("clase", seq_len(ncol(pesos))),
       col = seq_len(ncol(pesos)), lty = 1, bty = "n", cex = 0.8)
print(round(pesos[nrow(pesos), ], 3))
)---",
    gower = if (identical(p$hiper$estrategia, "jerarquico")) r"---(
fusiones <- @obj@$arbol$merge
tamano <- integer(nrow(fusiones))
for (i in seq_len(nrow(fusiones))) {
  m <- fusiones[i, ]
  tamano[i] <- sum(ifelse(m < 0, 1, tamano[pmax(m, 1)]))
}
# Un enlace que encadena: un grupo que se come a los demás.
plot(cummax(tamano), type = "s", xlab = "fusión",
     ylab = "tamaño del grupo mayor")
)---" else r"---(
# PAM no deja estados intermedios: solo los medoides finales.
print(data.frame(grupo = seq_along(@obj@$medoides),
                 medoide = @obj@$medoides))
)---")
  .cq_panel(p, texto)
}

#' Fase 3. La partición en el plano del ACM en algunas iteraciones: el
#' arranque, dos intermedias y la final.
.cq_estado <- function(p) {
  a <- .cq_ajuste(p)
  c(a$lineas, .acm_definicion(), .cq_texto(r"---(
A <- @obj@$asignaciones
pasos <- unique(round(seq(1, ncol(A),
                         length.out = min(4, ncol(A)))))
acm <- acm_coordenadas(@obj@$x, 2)
estados <- do.call(rbind, lapply(pasos, function(j)
  data.frame(acm$filas, grupo = factor(A[, j]),
             iteracion = paste("iteración", j - 1))))
estados$iteracion <- factor(estados$iteracion,
                            levels = unique(estados$iteracion))
ggplot(estados, aes(Dim1, Dim2, color = grupo)) +
  geom_point(size = 1.6) +
  facet_wrap(~ iteracion) +
  labs(x = acm$rotulos[1], y = acm$rotulos[2]) +
  theme_minimal()
)---", obj = a$objeto))
}

#' El codo de la sesión 5 con factores. k-modas mide su propio costo (los
#' desacuerdos con la moda); Gower, la d de la partición de la sesión 5
#' —la disimilitud media dentro de cada grupo, sumada— sobre su matriz. Cada
#' k es un ajuste completo con los mismos reinicios y semilla, igual que
#' `inercia_por_k()` del lab; k = 1 es la referencia de la reducción.
.cq_codo <- function(p) {
  h <- p$hiper %||% list()
  k_max <- as.integer(p$k_max %||% 10L)
  medida <- if (identical(p$metodo, "kmodos")) sprintf(r"---(
# k = 1: un solo grupo, cuya moda es la categoría más frecuente.
costo_k <- function(k) {
  if (k == 1) return(sum(sapply(x, function(v)
    length(v) - max(table(v)))))
  kmodas(x, k, reinicios = %d, semilla = %d, maxit = %d)$costo
}
criterio <- "costo (desacuerdos con la moda)"
)---", as.integer(p$reinicios %||% 25L), as.integer(p$semilla %||% 42L),
    as.integer(p$maxit %||% 500L))
  else sprintf(r"---(
# La d de una partición: por grupo, la suma de disimilitudes entre
# sus pares dividida por su tamaño; luego se suman los grupos.
d_particion <- function(d, grupos) {
  d <- as.matrix(d)
  sum(sapply(split(seq_along(grupos), grupos), function(g)
    sum(d[g, g][upper.tri(d[g, g])]) / length(g)))
}
d <- @obj@$d
costo_k <- function(k) {
  if (k == 1) return(d_particion(d, rep(1, nrow(x))))
  ajuste <- agrupar_gower(x, k, estrategia = "%s",
                          enlace = "%s", asimetricas = %s)
  d_particion(d, ajuste$grupos)
}
criterio <- "d de la partición (Gower)"
)---", h$estrategia %||% "pam", h$enlace %||% "average",
    isTRUE(h$binarias_asimetricas))
  .cq_panel(p, paste(c("x <- @obj@$x", medida, sprintf(r"---(
k_max <- min(%d, sum(!duplicated(x)), nrow(x) - 1)
costos <- sapply(seq_len(k_max), costo_k)
# La reducción respecto de k = 1, en porcentaje: el codo es donde
# deja de valer la pena otro grupo.
reduccion <- round(100 * (1 - costos / costos[1]), 1)
codo <- data.frame(k = seq_len(k_max), costo = round(costos, 2),
                   reduccion = reduccion)
print(codo, row.names = FALSE)
plot(codo$k, codo$costo, type = "b", pch = 19, xlab = "k",
     ylab = criterio)
# La línea punteada es el k elegido.
abline(v = @obj@$k, lty = 2, col = "grey50")
)---", k_max)), collapse = "\n"))
}
