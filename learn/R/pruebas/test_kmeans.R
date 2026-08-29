# learn/R/pruebas/test_kmeans.R
#
# Responsabilidad: probar k-medias de punta a punta sin Shiny — motor, métricas
# de grupos, gráficos y supuestos.
#
# Uso:  Rscript learn/R/pruebas/test_kmeans.R
#
# Un archivo por método (C14). Lo común —registro, contratos, almacén— está en
# test_headless.R, y el contrato S2 en test_contrato.R.
#
# Las pruebas que este método aporta y el ACP no podía dar son dos: que la
# traza baje de verdad (la inercia es el objetivo, no un subproducto) y que la
# semilla cambie el resultado. El ACP converge siempre al mismo subespacio; acá
# un reinicio de más es la diferencia entre un resultado y una casualidad.

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

# Tres nubes separadas: la partición correcta se conoce de antemano, así que
# "los grupos recuperan las nubes" es una asercion positiva y no una opinion.
set.seed(11)
por_nube <- 60L
verdad <- rep(1:3, each = por_nube)
nubes <- data.frame(
  x = c(stats::rnorm(por_nube, -4), stats::rnorm(por_nube, 4),
        stats::rnorm(por_nube, 0)),
  y = c(stats::rnorm(por_nube, -3), stats::rnorm(por_nube, -3),
        stats::rnorm(por_nube, 5)),
  z = stats::rnorm(3 * por_nube))

# Nubes solapadas: acá sí hay optimos locales que encontrar.
set.seed(4)
revuelto <- data.frame(x = stats::rnorm(120), y = stats::rnorm(120),
                       w = stats::rnorm(120))

lloyd <- ajustar_kmeans(nubes, k = 3L, optimizador = "Lloyd", reinicios = 5L)
macqueen <- ajustar_kmeans(nubes, k = 3L, optimizador = "MacQueen",
                           reinicios = 5L)

# ---------------------------------------------------------------------------
cat("\n[kmeans · los dos optimizadores]\n")

probar("Lloyd y MacQueen llegan a la misma inercia en un problema separable",
       abs(lloyd$inercia - macqueen$inercia) < 1e-6)

probar("los dos recuperan la particion conocida",
       {
         # Las etiquetas se renumeran por la coordenada del centroide, asi que
         # lo que se comprueba es la particion, no los numeros: cada nube tiene
         # que caer entera en un grupo, y cada grupo recibir una sola nube.
         cruce <- table(verdad, lloyd$grupos)
         all(apply(cruce, 1L, max) == por_nube) &&
           all(apply(cruce, 2L, max) == por_nube)
       })

probar("los dos dejan traza y la fase 3 tiene algo que reproducir",
       !is.null(lloyd$traza) && !is.null(macqueen$traza) &&
         lloyd$iteraciones > 0L && macqueen$iteraciones > 0L)

probar("las tres inicializaciones llegan al mismo optimo con nubes separadas",
       {
         inercias <- vapply(c("k-means++", "aleatoria", "Forgy"), function(ini)
           ajustar_kmeans(nubes, k = 3L, inicializacion = ini,
                          reinicios = 5L)$inercia, numeric(1))
         max(inercias) - min(inercias) < 1e-6
       })

probar("un optimizador inexistente falla en vez de elegir uno por su cuenta",
       falla(ajustar_kmeans(nubes, k = 3L, optimizador = "Hartigan-Wong")))

# ---------------------------------------------------------------------------
cat("\n[kmeans · el resultado]\n")

probar("hay un grupo por observacion y ninguno fuera de rango",
       length(lloyd$grupos) == nrow(nubes) &&
         all(lloyd$grupos %in% seq_len(3L)))

probar("los centroides son k por p, con los nombres de las columnas",
       identical(dim(lloyd$centroides), c(3L, 3L)) &&
         identical(colnames(lloyd$centroides), c("x", "y", "z")))

probar("los tamanos suman n",
       sum(lloyd$tamanos) == lloyd$n)

probar("la inercia por grupo suma la inercia total del ajuste",
       abs(sum(lloyd$inercia_por_grupo) - lloyd$inercia) < 1e-8)

probar("la inercia explicada esta entre 0 y 1",
       lloyd$proporcion_explicada > 0 && lloyd$proporcion_explicada < 1)

probar("el orden de los grupos es estable entre corridas identicas",
       identical(ajustar_kmeans(nubes, k = 3L, reinicios = 5L)$grupos,
                 lloyd$grupos))

probar("mas grupos nunca dejan mas inercia",
       ajustar_kmeans(nubes, k = 5L, reinicios = 5L)$inercia <= lloyd$inercia)

probar("sin escalar, la columna de rango grande manda",
       {
         torcido <- nubes; torcido$z <- torcido$z * 500
         crudo <- ajustar_kmeans(torcido, k = 3L, escalar = FALSE, reinicios = 3L)
         escalado <- ajustar_kmeans(torcido, k = 3L, escalar = TRUE, reinicios = 3L)
         !identical(crudo$grupos, escalado$grupos)
       })

probar("k = 1 falla y explica",
       falla(ajustar_kmeans(nubes, k = 1L)))

probar("k mayor o igual que n falla y explica",
       falla(ajustar_kmeans(nubes[1:5, ], k = 5L)))

probar("una sola columna numerica falla",
       falla(ajustar_kmeans(nubes["x"], k = 2L)))

probar("una columna constante no se escala en silencio: falla y explica",
       {
         plana <- nubes; plana$c <- 7
         falla(ajustar_kmeans(plana, k = 3L))
       })

probar("las filas con faltantes se descartan y se cuentan",
       {
         con_hueco <- nubes; con_hueco$x[1:4] <- NA
         a <- ajustar_kmeans(con_hueco, k = 3L, reinicios = 3L)
         a$filas_descartadas == 4L && a$n == nrow(nubes) - 4L
       })

# ---------------------------------------------------------------------------
cat("\n[kmeans · la traza y la semilla]\n")

probar("la inercia nunca sube: la traza es monotona",
       traza_monotona(lloyd$traza) && traza_monotona(macqueen$traza))

probar("el objetivo de la traza se llama por lo que es",
       identical(lloyd$traza$objetivo, "inercia intra-grupo"))

probar("la traza arranca en la iteracion 0, que es el estado inicial",
       min(traza_a_tabla(lloyd$traza)$iter) == 0L)

probar("la trayectoria trae una coordenada por grupo y variable",
       {
         tabla <- parametros_a_tabla(lloyd$traza)
         length(unique(tabla$parametro)) == 3L * 3L
       })

probar("hay una columna de asignaciones por iteracion registrada",
       ncol(lloyd$asignaciones_por_iter) == lloyd$iteraciones + 1L &&
         nrow(lloyd$asignaciones_por_iter) == lloyd$n)

probar("registrar_traza = FALSE no guarda nada y el ajuste sigue valiendo",
       {
         mudo <- ajustar_kmeans(nubes, k = 3L, registrar_traza = FALSE)
         is.null(mudo$traza) && is.null(mudo$asignaciones_por_iter) &&
           abs(mudo$inercia - lloyd$inercia) < 1e-6
       })

probar("la misma semilla da exactamente la misma particion",
       identical(ajustar_kmeans(revuelto, k = 4L, reinicios = 1L,
                                semilla = 7L)$grupos,
                 ajustar_kmeans(revuelto, k = 4L, reinicios = 1L,
                                semilla = 7L)$grupos))

probar("con datos solapados y un solo arranque, la semilla cambia el resultado",
       {
         uno <- ajustar_kmeans(revuelto, k = 4L, reinicios = 1L, semilla = 1L)
         dos <- ajustar_kmeans(revuelto, k = 4L, reinicios = 1L, semilla = 99L)
         !identical(uno$grupos, dos$grupos)
       })

probar("mas reinicios nunca empeoran la inercia",
       {
         pobre <- ajustar_kmeans(revuelto, k = 5L, reinicios = 1L,
                                 inicializacion = "aleatoria", semilla = 3L)
         rico <- ajustar_kmeans(revuelto, k = 5L, reinicios = 15L,
                                inicializacion = "aleatoria", semilla = 3L)
         rico$inercia <= pobre$inercia + 1e-9
       })

probar("comparar_reinicios ve varios arranques distintos",
       {
         a <- ajustar_kmeans(revuelto, k = 5L, reinicios = 8L,
                             inicializacion = "aleatoria")
         tabla <- comparar_reinicios(a$trazas_reinicios)
         nrow(tabla) == 8L && length(unique(round(tabla$objetivo_final, 6))) > 1L
       })

probar("la semilla ganadora es una de las que se probaron",
       lloyd$semilla_ganadora %in% (lloyd$semilla + seq_len(5L) - 1L))

# ---------------------------------------------------------------------------
cat("\n[kmeans · metricas de grupos (fase 4)]\n")

probar("la silueta trae una fila por observacion, entre -1 y 1",
       {
         s <- silueta(lloyd)
         nrow(s) == lloyd$n && all(s$s >= -1 - 1e-9) && all(s$s <= 1 + 1e-9)
       })

probar("con nubes separadas la silueta media es alta",
       mean(silueta(lloyd)$s) > 0.5)

probar("con datos sin estructura la silueta media es baja",
       mean(silueta(ajustar_kmeans(revuelto, k = 4L, reinicios = 5L))$s) < 0.4)

probar("nadie es vecino de su propio grupo",
       {
         s <- silueta(lloyd)
         all(as.character(s$grupo) != as.character(s$vecino))
       })

probar("el codo devuelve una fila por k, de 2 al maximo pedido",
       {
         tabla <- inercia_por_k(lloyd, k_max = 6L)
         identical(tabla$k, 2:6) && all(diff(tabla$inercia) <= 1e-8)
       })

probar("resumen_grupos cuadra con los tamanos del ajuste",
       identical(resumen_grupos(lloyd)$n, lloyd$tamanos))

probar("centroides_tabla es el formato largo de la matriz",
       nrow(centroides_tabla(lloyd)) == 3L * 3L)

probar("las metricas de la corrida traen lo que la fase 4 pinta",
       {
         m <- metricas_de_corrida(lloyd)
         all(c("inercia", "proporcion_explicada", "silueta_media",
               "grupo_menor", "grupo_mayor") %in% names(m))
       })

probar("el ajuste declara su familia con una clase, no con un campo",
       inherits(lloyd, "ajuste_kmeans") && inherits(lloyd, "ajuste_sda"))

probar("las genericas despachan a la familia de grupos",
       {
         nombres <- names(resumen_ajuste(lloyd))
         "inercia" %in% nombres && identical(etiquetas_ejes(lloyd),
                                             c("eje 1", "eje 2"))
       })

probar("el mapa 2d se puede colorear con las asignaciones de una iteracion",
       {
         tabla <- coordenadas_2d(lloyd,
                                 grupo = lloyd$asignaciones_por_iter[, 1])
         nrow(tabla) == lloyd$n && nlevels(tabla$grupo) == 3L
       })

# ---------------------------------------------------------------------------
cat("\n[kmeans · supuestos (fase 2)]\n")

ds_nubes <- nuevo_dataset("d1", "nubes", nubes, fuente = "memoria")

probar("se evaluan los cuatro supuestos que el catalogo declara",
       length(evaluar_supuestos("kmeans", ds_nubes)) == 4L)

probar("ninguno queda ya en 'sin comprobacion automatica'",
       !any(grepl("sin comprobacion",
                  vapply(evaluar_supuestos("kmeans", ds_nubes), `[[`, "",
                         "mensaje"))))

probar("una nube alargada dispara el aviso de grupos esfericos",
       {
         cigarro <- data.frame(x = stats::rnorm(100))
         cigarro$y <- cigarro$x * 0.995 + stats::rnorm(100, sd = 0.02)
         cigarro$z <- stats::rnorm(100)
         avisos <- evaluar_supuestos("kmeans",
                                     nuevo_dataset("d2", "cigarro", cigarro))
         esfericos <- Filter(function(a) a$clave == "grupos_esfericos", avisos)
         esfericos[[1]]$severidad == "aviso"
       })

probar("con cuatro filas no hay margen ni para dos grupos",
       {
         avisos <- evaluar_supuestos("kmeans",
                                     nuevo_dataset("d3", "poco", nubes[1:3, ]))
         tamanos <- Filter(function(a) a$clave == "tamanos_similares", avisos)
         tamanos[[1]]$severidad == "error"
       })

# ---------------------------------------------------------------------------
cat("\n[kmeans · el catalogo lo declara]\n")

probar("kmeans esta activo y trae su funcion de ajuste",
       {
         m <- metodo("kmeans")
         m$estado == "activo" && is.function(m$ajustar)
       })

probar("cada hiperparametro del registro es argumento de la funcion pura",
       all(names(metodo("kmeans")$hiper) %in%
             names(formals(metodo("kmeans")$ajustar))))

probar("los optimizadores que promete son los que implementa",
       identical(metodo("kmeans")$optimizador$metodos, c("Lloyd", "MacQueen")))

probar("cada artefacto que promete esta registrado",
       all(metodo("kmeans")$artefactos %in% claves_artefactos()))

probar("hiper_por_defecto arranca donde arranca la app",
       identical(hiper_por_defecto("kmeans"), list(k = 3, escalar = TRUE)))

probar("argumentos_ajuste filtra lo que este metodo no acepta",
       {
         filtrados <- argumentos_ajuste("kmeans",
                                        list(k = 3L, matriz = "correlacion",
                                             reinicios = 2L))
         identical(names(filtrados), c("k", "reinicios"))
       })

# ---------------------------------------------------------------------------
cat("\n[kmeans · graficos]\n")

probar("codo de la inercia",
       dibuja(graficar_codo(inercia_por_k(lloyd, k_max = 6L), k = 3L)))
probar("silueta",
       dibuja(graficar_silueta(silueta(lloyd))))
probar("perfil de los centroides",
       dibuja(graficar_centroides(centroides_tabla(lloyd))))
probar("tamanos de los grupos",
       dibuja(graficar_tamanos(resumen_grupos(lloyd))))
probar("mapa 2d de la particion",
       dibuja(graficar_mapa_2d(coordenadas_2d(lloyd))))
probar("convergencia de la inercia",
       dibuja(graficar_convergencia(traza_a_tabla(lloyd$traza))))
probar("trayectoria de los centroides",
       dibuja(graficar_trayectoria(parametros_a_tabla(lloyd$traza),
                                   componente = 1L)))
probar("el grafico principal de la familia es el codo",
       dibuja(grafico_resultado(lloyd)))
probar("sin grupos, el grafico avisa en vez de romperse",
       dibuja(graficar_codo(inercia_por_k(lloyd)[0, ])))

# ---------------------------------------------------------------------------
cat(sprintf("\n[test_kmeans] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
