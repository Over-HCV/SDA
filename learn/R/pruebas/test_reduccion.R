# learn/R/pruebas/test_reduccion.R
#
# Responsabilidad: probar lo que la FAMILIA de reducción contesta, sin Shiny.
#
# Uso:  Rscript learn/R/pruebas/test_reduccion.R
#
# test_acp.R prueba el motor del ACP; este prueba lo que se le pregunta después:
# contribución, calidad de representación, las tres reglas para elegir k,
# ortogonalidad y suplementarios. Va aparte porque no es de un método: el ACM
# entra por las mismas funciones y las mismas pruebas valen.
#
# La que sostiene el resto es la de suplementarios: proyectar las MISMAS filas
# del ajuste tiene que devolver las mismas puntuaciones. Si eso falla, el centro
# y la escala que se usan no son los del ajuste y el punto está dibujado en otro
# espacio.

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

# Dos bloques correlacionados y una variable sola: el plano 1-2 tiene que
# recoger casi todo, y la tercera componente ser residuo.
set.seed(23)
n <- 150
nube <- data.frame(a = stats::rnorm(n), b = NA_real_, c = NA_real_,
                   d = stats::rnorm(n) * 8 + 50)
nube$b <- nube$a * 0.95 + stats::rnorm(n, sd = 0.2)
nube$c <- nube$d * -0.9 + stats::rnorm(n, sd = 3)

ajuste <- ajustar_acp(nube, n_componentes = 4L, optimizador = "svd")
plano <- ajustar_acp(nube, n_componentes = 2L, optimizador = "svd")

# ---------------------------------------------------------------------------
cat("\n[contribucion al eje]\n")

contrib <- contribuciones(ajuste)

probar("reparte 100 en cada componente",
       all(abs(tapply(contrib$contribucion, contrib$componente, sum) - 100) < 1e-8))

probar("trae una fila por variable y componente",
       nrow(contrib) == ncol(nube) * ajuste$k)

probar("nunca es negativa: es un cuadrado",
       all(contrib$contribucion >= 0))

# Las cargas existen para las p componentes aunque se retengan dos: retener es
# una decision de lectura, no un recorte del algebra. Que contribuciones() siga
# la misma regla que cargas() es lo que se prueba, no un numero.
probar("sigue la misma regla que cargas() para las componentes disponibles",
       nrow(contribuciones(plano, componentes = 1:4)) ==
         nrow(cargas(plano, componentes = 1:4)))

# ---------------------------------------------------------------------------
cat("\n[calidad de representacion]\n")

calidad_v <- calidad_variables(ajuste)
calidad_i <- calidad_individuos(ajuste)

probar("el cos2 del plano es la suma de los dos ejes",
       all(abs(tapply(calidad_v$cos2, calidad_v$variable, sum) -
                 tapply(calidad_v$cos2_plano, calidad_v$variable, max)) < 1e-10))

probar("sobre R el cos2 de una variable no pasa de 1",
       all(calidad_v$cos2_plano <= 1 + 1e-8))

probar("el cos2 de un individuo tampoco",
       all(calidad_i$cos2_plano <= 1 + 1e-8))

probar("con todas las componentes el cos2 de un individuo suma 1", {
  completo <- calidad_individuos(ajuste, c(1L, 2L))
  todas <- rowSums(ajuste$puntuaciones^2) / ajuste$norma2_filas
  # Con k = p las cuatro componentes agotan la distancia al centroide.
  ajuste$k == 4L && all(abs(todas - 1) < 1e-10) && nrow(completo) == 2 * n
})

probar("la contribucion de los individuos tambien reparte 100",
       all(abs(tapply(calidad_i$contribucion, calidad_i$componente, sum) - 100) < 1e-8))

probar("sin norma2_filas falla diciendolo, no devuelve NA", {
  mutilado <- ajuste; mutilado$norma2_filas <- NULL
  falla(calidad_individuos(mutilado))
})

# ---------------------------------------------------------------------------
cat("\n[ortogonalidad]\n")

correlaciones <- correlacion_puntuaciones(ajuste)

probar("las componentes no se correlacionan entre si",
       max(abs(correlaciones - diag(nrow(correlaciones)))) < 1e-10)

probar("con una sola componente la matriz es 1x1 y no un error",
       identical(dim(correlacion_puntuaciones(
         ajustar_acp(nube, n_componentes = 1L, optimizador = "svd"))),
         c(1L, 1L)))

# ---------------------------------------------------------------------------
cat("\n[las tres reglas para elegir k]\n")

reglas <- reglas_k(ajuste)

probar("son tres y traen su detalle",
       nrow(reglas) == 3L && all(nzchar(reglas$detalle)))

probar("ninguna propone mas componentes de las que hay",
       all(reglas$k >= 1L & reglas$k <= ajuste$p))

probar("Kaiser y el umbral acumulado coinciden en los dos bloques",
       reglas$k[reglas$regla == "Kaiser"] == 2L && reglas$k[1] == 2L)

# Y el codo no tiene por que coincidir: marca el vertice del quiebre, que aca
# cae en la primera componente ya plana. Que las tres discrepen en uno es
# exactamente lo que la tabla existe para mostrar.
probar("el codo cae en el quiebre, entre 2 y 3",
       reglas$k[reglas$regla == "codo"] %in% c(2L, 3L))

probar("las tres no se separan mas de una componente",
       diff(range(reglas$k)) <= 1L)

probar("Kaiser sobre R cuenta los valores propios que pasan de 1",
       reglas$k[reglas$regla == "Kaiser"] == sum(ajuste$valores_propios > 1))

probar("sobre S el corte de Kaiser es la media y el detalle lo dice", {
  sobre_s <- ajustar_acp(nube, n_componentes = 2L, matriz = "covarianza",
                         optimizador = "svd")
  fila <- reglas_k(sobre_s)
  fila <- fila[fila$regla == "Kaiser", ]
  grepl("media", fila$detalle) &&
    fila$k == sum(sobre_s$valores_propios > mean(sobre_s$valores_propios))
})

probar("el umbral acumulado sigue a componentes_sugeridas",
       reglas$k[1] == componentes_sugeridas(ajuste, 0.8))

# ---------------------------------------------------------------------------
cat("\n[individuos y variables suplementarias]\n")

probar("proyectar las mismas filas devuelve las mismas puntuaciones", {
  proyectado <- proyectar_individuos(ajuste, nube)
  max(abs(proyectado$x - ajuste$puntuaciones[, 1])) < 1e-10 &&
    max(abs(proyectado$y - ajuste$puntuaciones[, 2])) < 1e-10
})

probar("y su cos2 en el plano coincide con el del ajuste",
       max(abs(proyectar_individuos(ajuste, nube)$cos2_plano -
                 unique(calidad_individuos(ajuste)$cos2_plano))) < 1e-10)

probar("una fila nueva se proyecta con el centro del AJUSTE", {
  # Si se recalculara el centro sobre el dato nuevo, una sola fila caeria en el
  # origen. Que no caiga es la prueba.
  una <- proyectar_individuos(ajuste, nube[7, , drop = FALSE])
  abs(una$x - ajuste$puntuaciones[7, 1]) < 1e-10
})

probar("las etiquetas salen de los rownames",
       identical(proyectar_individuos(ajuste, head(nube, 3))$etiqueta,
                 rownames(head(nube, 3))))

probar("un dataset al que le falta una columna del ajuste no se proyecta",
       falla(proyectar_individuos(ajuste, nube[, c("a", "b")])))

probar("sirve_como_suplementario explica el motivo en vez de decir FALSE",
       grepl("faltan columnas",
             sirve_como_suplementario(ajuste, nube[, c("a", "b")])))

probar("una variable activa proyectada da su propia correlacion", {
  esperado <- correlaciones_componentes(ajuste, c(1L, 2L))
  obtenido <- proyectar_variable(ajuste, nube$a, "a")
  abs(obtenido$x - esperado$x[esperado$variable == "a"]) < 1e-8
})

probar("una variable con otro largo que el ajuste falla diciendolo",
       falla(proyectar_variable(ajuste, nube$a[1:10], "a")))

probar("una variable constante no se correlaciona con nada y se dice",
       falla(proyectar_variable(ajuste, rep(1, n), "plana")))

probar("un ajuste sin centro no admite individuos suplementarios", {
  sin_centro <- ajuste; sin_centro$centro <- NULL
  falla(proyectar_individuos(sin_centro, nube))
})

# ---------------------------------------------------------------------------
cat("\n[las puntuaciones como dataset]\n")

tabla <- puntuaciones_como_dataframe(plano)

probar("trae una fila por observacion y una columna por componente",
       nrow(tabla) == n && ncol(tabla) == 2L)

probar("respeta los nombres del ajuste",
       identical(names(tabla), c("CP1", "CP2")))

probar("con prefijo propio los renombra",
       identical(names(puntuaciones_como_dataframe(plano, "Dim")),
                 c("Dim1", "Dim2")))

probar("y entran como dataset sin tocar el diccionario a mano", {
  ds <- nuevo_dataset("d9", "componentes", tabla, fuente = "componentes de acp")
  identical(columnas_numericas(ds), c("CP1", "CP2")) && ds$n == n
})

# ---------------------------------------------------------------------------
cat("\n[graficos]\n")

probar("contribucion al eje", dibuja(graficar_contribuciones(contrib)))
probar("calidad de representacion", dibuja(graficar_calidad(calidad_v)))
probar("calidad sobre S avisa de que el cos2 puede pasarse de 1",
       dibuja(graficar_calidad(calidad_v, sobre_correlacion = FALSE)))
probar("scree con las tres reglas marcadas",
       dibuja(graficar_scree(varianza_explicada(ajuste), k = 2L,
                             reglas = reglas)))
probar("ortogonalidad como mapa de calor",
       dibuja(graficar_heatmap_correlacion(correlaciones)))
probar("mapa 2d coloreado por una variable continua",
       dibuja(graficar_mapa_2d(coordenadas_2d(plano, c(1L, 2L), nube$d),
                               color_nombre = "d")))
probar("mapa 2d con individuos suplementarios",
       dibuja(graficar_mapa_2d(coordenadas_2d(plano, c(1L, 2L)),
                               suplementarios = proyectar_individuos(
                                 plano, head(nube, 3)))))
probar("biplot coloreado por una variable continua",
       dibuja(graficar_biplot(coordenadas_biplot(plano, c(1L, 2L), nube$d),
                              color_nombre = "d")))
probar("circulo con una flecha suplementaria",
       dibuja(graficar_circulo(correlaciones_componentes(plano),
                               suplementarias = proyectar_variable(
                                 plano, nube$a, "a"))))
probar("un color categorico sigue funcionando",
       dibuja(graficar_mapa_2d(coordenadas_2d(
         plano, c(1L, 2L), rep(c("uno", "dos"), length.out = n)))))

# ---------------------------------------------------------------------------
cat(sprintf("\n[test_reduccion] %s\n",
            if (.FALLOS) sprintf("%d FALLO(S)", .FALLOS) else "todo verde"))
if (.FALLOS) quit(status = 1L)
