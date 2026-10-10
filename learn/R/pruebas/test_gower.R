# learn/R/pruebas/test_gower.R
#
# Responsabilidad: probar el agrupamiento sobre la disimilitud de Gower de
# punta a punta sin Shiny — la distancia, las dos estrategias, la traza de PAM
# y el árbol, y el resultado sobre el zoológico.
#
# Uso:  Rscript learn/R/pruebas/test_gower.R
#
# Un archivo por método (C14). La prueba central es de cuentas a mano: con
# solo categorías, Gower es la proporción de variables en que dos filas
# difieren, y eso se puede contar sin daisy(). Si la distancia mintiera, todo
# lo de arriba —medoides, árbol, ARI— estaría bien calculado sobre un número
# equivocado, y ninguna otra prueba lo vería.

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", conditionMessage(e), "\n"); FALSE })
  if (!resultado) .FALLOS <<- .FALLOS + 1L
  cat(sprintf("  %s %s\n", if (resultado) "ok  " else "FALLA", descripcion))
  invisible(resultado)
}

falla <- function(expresion) {
  inherits(tryCatch(expresion, error = function(e) e), "error")
}

dibuja <- function(grafico) {
  inherits(grafico, "ggplot") &&
    !inherits(try(ggplot2::ggplot_build(grafico), silent = TRUE), "try-error")
}

# Índice de Rand ajustado (Hubert y Arabie, 1985), local a la prueba: cuántos
# pares de filas las dos particiones tratan igual (juntos en ambas o separados
# en ambas), descontado lo que daría el azar con los mismos tamaños. 1 es la
# misma partición; 0, lo esperable sin relación.
rand_ajustado <- function(a, b) {
  tabla <- table(a, b)
  pares <- function(x) sum(choose(x, 2))
  indice <- pares(tabla)
  filas <- pares(rowSums(tabla)); columnas <- pares(colSums(tabla))
  esperado <- filas * columnas / choose(sum(tabla), 2)
  (indice - esperado) / ((filas + columnas) / 2 - esperado)
}

# El zoológico de la UCI tal como queda en data/: 15 binarias si/no, `patas`
# como categoría (cinco patas no es "más" que cuatro en el sentido que importa
# acá: una estrella de mar no es un perro con una pata extra) y `tipo`, la
# clase verdadera, que se aparta para validar y nunca entra al ajuste.
zoo <- utils::read.csv(ruta_repo("data", "zoo.csv"), stringsAsFactors = TRUE)
zoo$patas <- factor(zoo$patas)
tipo <- zoo$tipo
animales <- zoo[setdiff(names(zoo), "tipo")]
variables <- setdiff(names(animales), "animal")
p <- length(variables)

# ---------------------------------------------------------------------------
cat("\n[gower · la disimilitud contada a mano]\n")

con_pam <- ajustar_gower(animales, k = 7L)
d <- as.matrix(con_pam$matriz_disimilitud)

probar("sin columnas: entran las 16 variables y el nombre queda de etiqueta",
       identical(con_pam$columnas, variables) &&
         identical(rownames(con_pam$x), as.character(zoo$animal)))

probar("solo categorias: Gower = desacuerdos / p, par por par",
       {
         m <- as.matrix(con_pam$x)
         a_mano <- outer(seq_len(nrow(m)), seq_len(nrow(m)),
                         Vectorize(function(i, j) mean(m[i, ] != m[j, ])))
         max(abs(a_mano - d)) < 1e-12
       })

probar("un par concreto: oso contra almeja",
       {
         i <- which(zoo$animal == "bear"); j <- which(zoo$animal == "clam")
         a_mano <- sum(vapply(variables, function(v)
           as.character(zoo[[v]][i]) != as.character(zoo[[v]][j]),
           logical(1))) / p
         abs(d[i, j] - a_mano) < 1e-12
       })

probar("una numerica aporta |x_i - x_j| / rango, promediada con las demas",
       {
         mezcla <- data.frame(a = factor(c("u", "v", "u", "v")),
                              b = factor(c("s", "s", "t", "t")),
                              x = c(0, 10, 4, 2))
         dm <- as.matrix(ajustar_gower(mezcla, k = 2L)$matriz_disimilitud)
         # filas 2 y 3: a difiere (1), b difiere (1), x: |10 - 4| / 10.
         abs(dm[2, 3] - (1 + 1 + 6 / 10) / 3) < 1e-12 &&
           abs(dm[1, 4] - (1 + 1 + 2 / 10) / 3) < 1e-12
       })

# ---------------------------------------------------------------------------
cat("\n[gower · binarias asimetricas]\n")

asimetrico <- ajustar_gower(animales, k = 7L, binarias_asimetricas = TRUE)
da <- as.matrix(asimetrico$matriz_disimilitud)

probar("las 15 binarias si/no se declaran asimetricas; patas no",
       length(asimetrico$asimetricas) == 15L &&
         !"patas" %in% asimetrico$asimetricas)

probar("pulga contra gusano: los 'no' compartidos salen del denominador",
       {
         i <- which(zoo$animal == "flea"); j <- which(zoo$animal == "worm")
         a <- as.character(unlist(zoo[i, variables]))
         b <- as.character(unlist(zoo[j, variables]))
         binaria <- variables != "patas"
         difieren <- sum(a != b)
         ausencias <- sum(binaria & a == "no" & b == "no")
         cat(sprintf("    simetrica %d/%d = %.3f · asimetrica %d/%d = %.3f\n",
                     difieren, p, difieren / p, difieren, p - ausencias,
                     difieren / (p - ausencias)))
         abs(d[i, j] - difieren / p) < 1e-12 &&
           abs(da[i, j] - difieren / (p - ausencias)) < 1e-12 &&
           da[i, j] > d[i, j]
       })

probar("la ausencia es el nivel 'no' aunque los niveles vengan al reves",
       {
         invertido <- animales
         for (v in setdiff(variables, "patas"))
           invertido[[v]] <- factor(invertido[[v]], levels = c("si", "no"))
         otro <- ajustar_gower(invertido, k = 7L, binarias_asimetricas = TRUE)
         max(abs(as.matrix(otro$matriz_disimilitud) - da)) < 1e-12
       })

# ---------------------------------------------------------------------------
cat("\n[gower · PAM]\n")

probar("k medoides, todos filas reales, y cada uno en su propio grupo",
       length(con_pam$medoides) == 7L &&
         all(con_pam$medoides %in% seq_len(con_pam$n)) &&
         identical(con_pam$grupos[con_pam$medoides], 1:7))

probar("los modos de PAM son las filas de los medoides",
       identical(unname(as.matrix(con_pam$modos)),
                 unname(as.matrix(con_pam$x[con_pam$medoides, ]))) &&
         identical(rownames(con_pam$modos), paste0("g", 1:7)))

probar("el objetivo es la suma de distancias al medoide, entre n",
       {
         suma <- sum(d[cbind(seq_len(con_pam$n),
                             con_pam$medoides[con_pam$grupos])])
         abs(suma / con_pam$n - con_pam$objetivo) < 1e-12
       })

probar("la particion es la de cluster::pam, salvo el nombre de los grupos",
       {
         directo <- cluster::pam(cluster::daisy(con_pam$x, metric = "gower"),
                                 k = 7L, diss = TRUE)
         rand_ajustado(directo$clustering, con_pam$grupos) == 1 &&
           setequal(directo$id.med, con_pam$medoides)
       })

probar("g1 es el grupo mas grande y los tamanos no suben",
       !is.unsorted(rev(con_pam$tamanos)) && sum(con_pam$tamanos) == 101L)

tabla_pam <- traza_a_tabla(con_pam$traza)
probar("la traza recorre BUILD (k pasos) y SWAP, y solo baja",
       nrow(tabla_pam) >= 7L && traza_monotona(con_pam$traza) &&
         con_pam$iteraciones == nrow(tabla_pam))
probar("el paso k de la traza es el costo de BUILD que reporta pam()",
       {
         directo <- cluster::pam(con_pam$matriz_disimilitud, k = 7L, diss = TRUE)
         abs(tabla_pam$objetivo[7] - directo$objective[["build"]]) < 1e-12 &&
           abs(utils::tail(tabla_pam$objetivo, 1) - con_pam$objetivo) < 1e-12
       })

probar("registrar_traza = FALSE no guarda nada y la particion no cambia",
       {
         mudo <- ajustar_gower(animales, k = 7L, registrar_traza = FALSE)
         is.null(mudo$traza) && identical(mudo$grupos, con_pam$grupos)
       })

# ---------------------------------------------------------------------------
cat("\n[gower · jerarquico]\n")

con_arbol <- ajustar_gower(animales, k = 7L, estrategia = "jerarquico")

probar("el corte da exactamente k grupos, sin medoides",
       identical(sort(unique(con_arbol$grupos)), 1:7) &&
         is.null(con_arbol$medoides) && nrow(con_arbol$modos) == 7L)

probar("la particion es la de hclust + cutree sobre la misma matriz",
       {
         directo <- stats::hclust(stats::as.dist(d), method = "average")
         rand_ajustado(stats::cutree(directo, 7L), con_arbol$grupos) == 1 &&
           isTRUE(all.equal(directo$height, con_arbol$arbol$height))
       })

probar("las hojas son los animales y la cofenetica es la de hclust",
       identical(con_arbol$arbol$labels, as.character(zoo$animal)) &&
         abs(con_arbol$correlacion_cofenetica -
               stats::cor(as.numeric(stats::as.dist(d)),
                          as.numeric(stats::cophenetic(con_arbol$arbol)))) < 1e-12)

probar("el modo de g1 es la categoria mas frecuente de su grupo",
       {
         g1 <- con_arbol$x[con_arbol$grupos == 1L, ]
         all(vapply(variables, function(v)
           as.character(con_arbol$modos[1, v]) ==
             names(which.max(table(g1[[v]]))), logical(1)))
       })

probar("la traza es una fusion por paso y sus alturas no bajan",
       nrow(traza_a_tabla(con_arbol$traza)) == 100L &&
         traza_monotona(con_arbol$traza))

probar("los cuatro enlaces corren, Ward incluido",
       all(vapply(c("average", "complete", "single", "ward.D2"), function(e)
         length(unique(ajustar_gower(animales, k = 4L, estrategia = "jerarquico",
                                     enlace = e)$grupos)) == 4L, logical(1))))

probar("el dendrograma de la familia lo dibuja sin cambios",
       {
         arbol <- arbol_jerarquico(con_arbol)
         nrow(arbol$rectangulos) == 7L && arbol$distancia == "gower" &&
           dibuja(graficar_dendrograma(arbol))
       })

# ---------------------------------------------------------------------------
cat("\n[gower · bordes]\n")

probar("una fila con algun NA se queda; una sin ningun dato se descarta",
       {
         huecos <- animales
         huecos[1, "pelo"] <- NA
         huecos[2, variables] <- NA
         a <- ajustar_gower(huecos, k = 3L)
         a$n == 100L && a$filas_descartadas == 1L &&
           "aardvark" %in% rownames(a$x) && !"antelope" %in% rownames(a$x)
       })

probar("k = 1, una estrategia o un enlace inexistente fallan",
       falla(ajustar_gower(animales, k = 1L)) &&
         falla(ajustar_gower(animales, estrategia = "kmedias")) &&
         falla(ajustar_gower(animales, estrategia = "jerarquico",
                             enlace = "ward")))

probar("declara la familia cualitativa y la de agrupamiento",
       inherits(con_pam, "ajuste_gower") &&
         inherits(con_pam, "ajuste_cualitativo") &&
         inherits(con_pam, "ajuste_agrupamiento"))

# ---------------------------------------------------------------------------
cat("\n[gower · el zoologico contra su clase verdadera, k = 7]\n")

probar("el ARI local da 1 consigo mismo y 0 contra una constante",
       rand_ajustado(tipo, tipo) == 1 &&
         abs(rand_ajustado(tipo, rep(1, length(tipo)))) < 1e-12)

for (caso in list(list("pam", FALSE), list("jerarquico", FALSE),
                  list("pam", TRUE), list("jerarquico", TRUE))) {
  ajuste <- ajustar_gower(animales, k = 7L, estrategia = caso[[1]],
                          binarias_asimetricas = caso[[2]])
  cat(sprintf("    ARI %-10s %-10s = %.3f  (tamanos %s)\n", caso[[1]],
              if (caso[[2]]) "asimetrica" else "simetrica",
              rand_ajustado(ajuste$grupos, tipo),
              paste(ajuste$tamanos, collapse = "/")))
}
probar("PAM y el arbol recuperan buena parte de los tipos (ARI > 0.5)",
       rand_ajustado(con_pam$grupos, tipo) > 0.5 &&
         rand_ajustado(con_arbol$grupos, tipo) > 0.5)

# ---------------------------------------------------------------------------
cat("\n[gower · el catalogo]\n")

if (existe_metodo("gower")) {
  probar("gower esta activo y trae su funcion de ajuste",
         {
           m <- metodo("gower")
           m$estado == "activo" && identical(m$ajustar, ajustar_gower)
         })
  probar("cada hiperparametro del registro es argumento de la funcion pura",
         all(names(metodo("gower")$hiper) %in% names(formals(ajustar_gower))))
  probar("cada artefacto que promete esta registrado",
         all(metodo("gower")$artefactos %in% claves_artefactos()))
} else {
  cat("  --   gower todavia no esta en el catalogo: se salta\n")
}

# ---------------------------------------------------------------------------
cat(sprintf("\n[test_gower] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
