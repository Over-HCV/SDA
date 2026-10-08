# learn/R/pruebas/test_jerarquico.R
#
# Responsabilidad: probar el agrupamiento jerárquico de punta a punta sin Shiny
# — motor, árbol, cofenética, métricas de grupos, gráficos y corredor batch.
#
# Uso:  Rscript learn/R/pruebas/test_jerarquico.R
#
# Un archivo por método (C14). Lo que este aporta y k-medias no podía dar: el
# método delega en stats::hclust(), así que la prueba central es que la
# partición sea EXACTAMENTE la de hclust + cutree, y que la traza reconstruida
# del historial cuadre con la inercia que se mide al final. Si el árbol o la
# traza mintieran, una de esas dos igualdades fallaría.

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

# Las mismas tres nubes que test_kmeans.R, con nombre por fila: la partición
# correcta se conoce, y las etiquetas tienen que llegar a las hojas.
set.seed(11)
por_nube <- 30L
verdad <- rep(1:3, each = por_nube)
nubes <- data.frame(
  id = sprintf("obs%02d", seq_len(3 * por_nube)),
  x = c(stats::rnorm(por_nube, -4), stats::rnorm(por_nube, 4),
        stats::rnorm(por_nube, 0)),
  y = c(stats::rnorm(por_nube, -3), stats::rnorm(por_nube, -3),
        stats::rnorm(por_nube, 5)),
  z = stats::rnorm(3 * por_nube))

promedio <- ajustar_jerarquico(nubes, enlace = "average", k_corte = 3L)
directo <- stats::hclust(stats::dist(scale(nubes[c("x", "y", "z")])),
                         method = "average")

# ---------------------------------------------------------------------------
cat("\n[jerarquico · coincide con hclust]\n")

probar("enlace promedio: la particion es la de cutree, numero a numero",
       identical(promedio$grupos,
                 as.integer(stats::cutree(directo, k = 3L))))

probar("las alturas de fusion son las de hclust",
       isTRUE(all.equal(promedio$arbol$height, directo$height)))

probar("recupera las tres nubes",
       {
         cruce <- table(verdad, promedio$grupos)
         all(apply(cruce, 1L, max) == por_nube)
       })

probar("los cinco enlaces corren y dan k_corte grupos",
       all(vapply(c("ward.D2", "complete", "average", "single", "centroid"),
                  function(e) length(unique(ajustar_jerarquico(
                    nubes, enlace = e, k_corte = 4L)$grupos)) == 4L,
                  logical(1))))

probar("Manhattan es la distancia de hclust con method = 'manhattan'",
       {
         a <- ajustar_jerarquico(nubes, enlace = "complete",
                                 distancia = "manhattan", k_corte = 3L)
         b <- stats::hclust(stats::dist(scale(nubes[c("x", "y", "z")]),
                                        method = "manhattan"), "complete")
         identical(a$grupos, as.integer(stats::cutree(b, k = 3L)))
       })

probar("el centroide mide sobre d al cuadrado y devuelve alturas en d",
       {
         a <- ajustar_jerarquico(nubes, enlace = "centroid", k_corte = 3L)
         b <- stats::hclust(stats::dist(scale(nubes[c("x", "y", "z")]))^2,
                            "centroid")
         isTRUE(all.equal(a$arbol$height, sqrt(b$height)))
       })

probar("un enlace inexistente falla en vez de elegir otro",
       falla(ajustar_jerarquico(nubes, enlace = "ward")))

# ---------------------------------------------------------------------------
cat("\n[jerarquico · el resultado]\n")

probar("k_corte grupos, uno por observacion",
       length(promedio$grupos) == nrow(nubes) &&
         identical(sort(unique(promedio$grupos)), 1:3))

probar("cambiar k_corte no cambia el arbol, solo dónde se lee",
       {
         cinco <- ajustar_jerarquico(nubes, enlace = "average", k_corte = 5L)
         identical(cinco$arbol$merge, promedio$arbol$merge) &&
           length(unique(cinco$grupos)) == 5L
       })

probar("los centroides son k por p y la inercia suma por grupos",
       identical(dim(promedio$centroides), c(3L, 3L)) &&
         abs(sum(promedio$inercia_por_grupo) - promedio$inercia) < 1e-8 &&
         sum(promedio$tamanos) == promedio$n)

probar("las hojas llevan el nombre de cada fila",
       identical(promedio$arbol$labels, nubes$id))

probar("la correlacion cofenetica es la de cor(cophenetic, dist)",
       abs(promedio$correlacion_cofenetica -
             stats::cor(stats::cophenetic(directo),
                        stats::dist(scale(nubes[c("x", "y", "z")])))) < 1e-12)

probar("sin semilla que importe: dos semillas, el mismo arbol",
       identical(ajustar_jerarquico(nubes, semilla = 1L)$grupos,
                 ajustar_jerarquico(nubes, semilla = 99L)$grupos))

probar("k = 1 y k >= n fallan y explican",
       falla(ajustar_jerarquico(nubes, k_corte = 1L)) &&
         falla(ajustar_jerarquico(nubes[1:4, ], k_corte = 4L)))

probar("una columna constante no se escala en silencio",
       {
         plana <- nubes; plana$c <- 7
         falla(ajustar_jerarquico(plana))
       })

probar("las filas con faltantes se descartan, y sus etiquetas tambien",
       {
         con_hueco <- nubes; con_hueco$x[1:4] <- NA
         a <- ajustar_jerarquico(con_hueco)
         a$filas_descartadas == 4L && a$n == nrow(nubes) - 4L &&
           identical(a$arbol$labels, nubes$id[-(1:4)])
       })

# ---------------------------------------------------------------------------
cat("\n[jerarquico · la traza es el historial de fusiones]\n")

tabla_traza <- traza_a_tabla(promedio$traza)

probar("una iteracion por fusion: n - 1",
       nrow(tabla_traza) == promedio$n - 1L &&
         promedio$iteraciones == promedio$n - 1L)

probar("el objetivo son las alturas, y con enlace promedio nunca bajan",
       isTRUE(all.equal(tabla_traza$objetivo, promedio$arbol$height)) &&
         traza_monotona(promedio$traza))

probar("la inercia acumulada en la traza cuadra con la del corte",
       {
         parametros <- parametros_a_tabla(promedio$traza)
         fila <- parametros[parametros$iter == promedio$n - 3L, ]
         abs(fila$valor - promedio$inercia) < 1e-8
       })

probar("tras la ultima fusion la inercia es la total",
       {
         parametros <- parametros_a_tabla(promedio$traza)
         abs(utils::tail(parametros$valor, 1) - promedio$inercia_total) < 1e-8
       })

probar("registrar_traza = FALSE no guarda nada y la particion no cambia",
       {
         mudo <- ajustar_jerarquico(nubes, enlace = "average",
                                    registrar_traza = FALSE)
         is.null(mudo$traza) && identical(mudo$grupos, promedio$grupos)
       })

# ---------------------------------------------------------------------------
cat("\n[jerarquico · metricas de grupos (fase 4)]\n")

probar("la silueta corre y con nubes separadas es alta",
       {
         s <- silueta(promedio)
         nrow(s) == promedio$n && mean(s$s) > 0.5
       })

probar("la silueta mide con la distancia del arbol",
       {
         a <- ajustar_jerarquico(nubes, distancia = "manhattan")
         s <- silueta(a)
         d <- as.matrix(stats::dist(a$z, method = "manhattan"))
         propio <- a$grupos == a$grupos[1]
         a1 <- sum(d[1, propio]) / (sum(propio) - 1)
         otros <- vapply(setdiff(unique(a$grupos), a$grupos[1]), function(g)
           mean(d[1, a$grupos == g]), numeric(1))
         abs(s$s[1] - (min(otros) - a1) / max(a1, min(otros))) < 1e-12
       })

probar("resumen y centroides reusan la familia sin cambios",
       identical(resumen_grupos(promedio)$n, promedio$tamanos) &&
         nrow(centroides_tabla(promedio)) == 3L * 3L)

probar("las metricas traen las de la familia mas la cofenetica",
       {
         m <- metricas_de_corrida(promedio)
         all(c("inercia", "silueta_media", "grupo_menor",
               "correlacion_cofenetica") %in% names(m))
       })

probar("declara su familia y las genericas despachan",
       inherits(promedio, "ajuste_jerarquico") &&
         inherits(promedio, "ajuste_agrupamiento") &&
         identical(etiquetas_ejes(promedio), c("eje 1", "eje 2")) &&
         "enlace" %in% names(resumen_ajuste(promedio)) &&
         grepl("cofenética", lectura_resultado(promedio)))

probar("el arbol dibujable trae tres segmentos por fusion y k rectangulos",
       {
         arbol <- arbol_jerarquico(promedio)
         nrow(arbol$segmentos) == 3L * (promedio$n - 1L) &&
           nrow(arbol$rectangulos) == 3L && nrow(arbol$hojas) == promedio$n
       })

probar("el corte cae entre la fusion n - k y la siguiente",
       {
         arbol <- arbol_jerarquico(promedio)
         h <- promedio$arbol$height
         arbol$corte > h[promedio$n - 3L] && arbol$corte < h[promedio$n - 2L]
       })

probar("cofenetico da un par por fila y la correlacion del ajuste",
       {
         tabla <- cofenetico(promedio)
         nrow(tabla) == choose(promedio$n, 2) &&
           abs(attr(tabla, "correlacion") - promedio$correlacion_cofenetica) < 1e-12
       })

# ---------------------------------------------------------------------------
cat("\n[jerarquico · el catalogo lo declara]\n")

probar("jerarquico esta activo y trae su funcion de ajuste",
       {
         m <- metodo("jerarquico")
         m$estado == "activo" && identical(m$ajustar, ajustar_jerarquico)
       })

probar("cada hiperparametro del registro es argumento de la funcion pura",
       all(names(metodo("jerarquico")$hiper) %in%
             names(formals(ajustar_jerarquico))))

probar("cada artefacto que promete esta registrado",
       all(metodo("jerarquico")$artefactos %in% claves_artefactos()))

probar("argumentos_ajuste deja afuera los mandos de k-medias",
       identical(names(argumentos_ajuste("jerarquico",
                                         list(k_corte = 3L, reinicios = 5L,
                                              tol = 1e-8, semilla = 1L))),
                 c("k_corte", "semilla")))

probar("el presupuesto de la fase 2 encuentra su k",
       identical(k_del_modelo(hiper_por_defecto("jerarquico")), 3))

probar("los dos supuestos tienen comprobacion",
       {
         avisos <- evaluar_supuestos("jerarquico",
                                     nuevo_dataset("d1", "nubes", nubes))
         length(avisos) == 2L &&
           !any(grepl("sin comprobacion", vapply(avisos, `[[`, "", "mensaje")))
       })

# ---------------------------------------------------------------------------
cat("\n[jerarquico · graficos]\n")

probar("dendrograma con etiquetas",
       dibuja(graficar_dendrograma(arbol_jerarquico(promedio))))
probar("dendrograma sin etiquetas",
       dibuja(graficar_dendrograma(arbol_jerarquico(promedio),
                                   etiquetas = FALSE)))
probar("correlacion cofenetica", dibuja(graficar_cofenetico(cofenetico(promedio))))
probar("silueta", dibuja(graficar_silueta(silueta(promedio))))
probar("mapa 2d", dibuja(graficar_mapa_2d(coordenadas_2d(promedio))))
probar("convergencia de las alturas",
       dibuja(graficar_convergencia(traza_a_tabla(promedio$traza))))
probar("el grafico principal es el dendrograma",
       dibuja(grafico_resultado(promedio)))

# ---------------------------------------------------------------------------
cat("\n[jerarquico · el corredor batch]\n")

source("learn/R/run_headless.R")
# on.exit() no corre al nivel de un script de Rscript: se borra a mano al final.
salida <- file.path("learn", "outputs", "test-jerarquico")

probar("correr() lo ajusta con los hiper del registro y escribe el JSON",
       {
         corrida <- correr("jer-nubes", metodo = "jerarquico", fuente = nubes,
                           hiper = list(enlace = "average", k_corte = 3L),
                           out_dir = salida)
         leido <- jsonlite::fromJSON(file.path(ruta_repo(salida),
                                               "jer-nubes.json"))
         all(names(metodo("jerarquico")$hiper) %in% names(leido$params)) &&
           leido$params$enlace == "average" &&
           abs(leido$metricas$correlacion_cofenetica -
                 promedio$correlacion_cofenetica) < 1e-4
       })

unlink(ruta_repo(salida), recursive = TRUE)

# ---------------------------------------------------------------------------
cat(sprintf("\n[test_jerarquico] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
