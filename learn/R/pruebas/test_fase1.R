# learn/R/pruebas/test_fase1.R
#
# Responsabilidad: probar la lógica y los gráficos de la fase 1, sin Shiny.
#
# Uso:  Rscript learn/R/pruebas/test_fase1.R
#
# Vive aparte de test_headless.R por C2: aquel prueba el núcleo (registro,
# objetos, contratos, exportadores) y este prueba la fase. Los dos son
# headless y los dos se corren siempre.
#
# La regla de C3 se comprueba sola: si algo de logica/ o graficos/ tocara
# `input` o `reactive`, este archivo no correría con Rscript.

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

datos_prueba <- data.frame(x = rnorm(50), y = rnorm(50),
                           g = rep(c("a", "b"), 25), stringsAsFactors = FALSE)
# ---------------------------------------------------------------------------
cat("\n[fase 1 · resumen y escala]\n")
sintetico <- gen_sintetico(n = 300, k_grupos = 3, efecto = 4, semilla = 7,
                           tipo = "anova")

probar("resumir_variable trae media y desviacion en escala de razon", {
  tabla <- resumir_variable(sintetico$valor, "razon")
  all(c("media", "desviacion", "asimetria") %in% tabla$estadistico)
})
probar("en escala nominal NO se calcula la media", {
  tabla <- resumir_variable(sintetico$valor, "nominal")
  !("media" %in% tabla$estadistico) && "moda" %in% tabla$estadistico
})
probar("la escala ordinal deja mediana pero no media",
       permite_operacion("ordinal", "mediana") &&
         !permite_operacion("ordinal", "media"))
probar("un control bloqueado trae su razon escrita",
       grepl("no tienen orden", razon_de_bloqueo("nominal", "media")))
probar("resumir_por_grupo devuelve una fila por grupo",
       nrow(resumir_por_grupo(sintetico, "valor", "grupo")) == 3L)
probar("el diccionario avisa si hay dos respuestas", {
  diccionario <- diccionario_inicial(datos_prueba)
  diccionario$rol[1:2] <- "respuesta"
  avisos <- avisos_diccionario(diccionario)
  any(grepl("como respuesta", vapply(avisos, `[[`, "", "mensaje")))
})
probar("una escala invalida es un error, no un aviso", {
  diccionario <- diccionario_inicial(datos_prueba)
  diccionario$escala[1] <- "logaritmica"
  severidad_maxima(avisos_diccionario(diccionario)) == "error"
})

# ---------------------------------------------------------------------------
cat("\n[fase 1 · muestreo (C8)]\n")
probar("por debajo del umbral no se muestrea", {
  muestra <- muestrear_para_grafico(sintetico, umbral = 5000L)
  !muestra$muestreado && muestra$n_muestra == nrow(sintetico)
})
probar("por encima del umbral se recorta y se dice", {
  muestra <- muestrear_para_grafico(sintetico, umbral = 100L, semilla = 42L)
  muestra$muestreado && nrow(muestra$datos) == 100L &&
    muestra$n_total == 300L
})
probar("la misma semilla da la misma muestra", {
  a <- muestrear_para_grafico(sintetico, umbral = 50L, semilla = 42L)
  b <- muestrear_para_grafico(sintetico, umbral = 50L, semilla = 42L)
  identical(a$datos, b$datos)
})
probar("otra semilla da otra muestra", {
  a <- muestrear_para_grafico(sintetico, umbral = 50L, semilla = 1L)
  b <- muestrear_para_grafico(sintetico, umbral = 50L, semilla = 2L)
  !identical(a$datos, b$datos)
})
probar("las metricas del total no cambian al muestrear el dibujo", {
  muestra <- muestrear_para_grafico(sintetico, umbral = 50L, semilla = 3L)
  total <- resumir_variable(sintetico$valor, "razon")
  total$valor[total$estadistico == "n"] == 300 && nrow(muestra$datos) == 50L
})
probar("usar_todo desactiva el muestreo",
       !muestrear_para_grafico(sintetico, umbral = 10L,
                              usar_todo = TRUE)$muestreado)
probar("sin muestreo no hay linea de contexto",
       is.null(descripcion_muestreo(
         muestrear_para_grafico(sintetico, umbral = 5000L))))

# ---------------------------------------------------------------------------
cat("\n[fase 1 · calidad y preparacion]\n")
con_huecos <- datos_prueba
con_huecos$x[c(2, 5)] <- NA

probar("patron_faltantes cuenta por columna y por fila", {
  patron <- patron_faltantes(con_huecos)
  patron$por_columna$faltantes[patron$por_columna$columna == "x"] == 2L &&
    patron$completas == nrow(con_huecos) - 2L
})
probar("imputar por mediana rellena y reporta cuantos", {
  resultado <- imputar(con_huecos, "x", "mediana")
  resultado$imputados == 2L && !any(is.na(resultado$datos$x))
})
probar("un metodo de imputacion inexistente falla fuerte",
       falla(imputar(con_huecos, "x", "adivinanza")))
probar("detectar_atipicos por IQR marca los extremos", {
  con_extremo <- datos_prueba
  con_extremo$x[1] <- 1000
  tabla <- detectar_atipicos(con_extremo, "x", "iqr")
  isTRUE(tabla$atipico[1]) && attr(tabla, "n_atipicos") >= 1L
})
probar("Mahalanobis devuelve NA si la covarianza es singular", {
  colineal <- data.frame(a = 1:20, b = 2 * (1:20))
  all(is.na(mahalanobis_cuadrado(colineal)))
})
probar("marcar_duplicados encuentra la fila repetida", {
  repetido <- rbind(datos_prueba, datos_prueba[1, ])
  sum(marcar_duplicados(repetido)$duplicada) == 1L
})
probar("la pila de transformaciones se aplica en orden y se deshace", {
  pila <- agregar_transformacion(list(), "logaritmo", "valor")
  pila <- agregar_transformacion(pila, "centrar", "valor")
  transformado <- aplicar_transformaciones(sintetico, pila)$datos
  deshecho <- aplicar_transformaciones(sintetico,
                                       quitar_transformacion(pila))$datos
  abs(mean(transformado$valor)) < 1e-8 &&
    all.equal(deshecho$valor, log(sintetico$valor)) == TRUE
})
probar("log de valores no positivos avisa en vez de fabricar NaN", {
  negativos <- data.frame(valor = c(-5, 1, 10))
  resultado <- aplicar_transformacion(negativos, "logaritmo", "valor")
  !any(is.nan(resultado$datos$valor)) && length(resultado$avisos) == 1L
})
probar("Box-Cox con lambda 0 es exactamente el logaritmo",
       isTRUE(all.equal(transformar_boxcox(c(1, 2, 10), 0), log(c(1, 2, 10)))))
probar("el perfil de lambda encuentra el optimo de una lognormal", {
  set.seed(11)
  perfil <- perfil_boxcox(exp(stats::rnorm(300)))
  abs(perfil$optimo) < 0.25 && perfil$redondeado == 0
})
probar("las dummies dejan k-1 columnas y quitan la original", {
  resultado <- aplicar_transformacion(sintetico, "dummies", "grupo",
                                      list(referencia = "A"))
  !("grupo" %in% names(resultado$datos)) &&
    sum(grepl("^grupo_", names(resultado$datos))) == 2L
})
probar("la particion estratificada conserva la proporcion", {
  particion <- particionar(sintetico, "holdout", 0.7, estratificar = "grupo",
                           semilla = 5L)
  balance <- balance_por_particion(sintetico, particion, "grupo")
  max(abs(balance$proporcion - 1 / 3)) < 0.05
})
probar("k-fold reparte en k pliegues",
       nrow(resumir_particion(particionar(sintetico, "kfold", k = 4L,
                                          semilla = 1L))) == 4L)
probar("la particion es reproducible con la misma semilla",
       identical(particionar(sintetico, semilla = 9L)$asignacion,
                 particionar(sintetico, semilla = 9L)$asignacion))
probar("el sobremuestreo iguala las clases y marca las copias", {
  desbalanceado <- rbind(sintetico[sintetico$grupo == "A", ],
                         sintetico[sintetico$grupo == "B", ][1:10, ])
  resultado <- balancear(desbalanceado, "grupo", "sobremuestreo", semilla = 4L)
  length(unique(resultado$despues$n)) == 1L &&
    sum(resultado$origen == "remuestreada") > 0L
})
probar("los pesos de clase suman n / clases",
       abs(sum(pesos_clase(sintetico, "grupo") *
                 resumir_balance(sintetico, "grupo")$n) - 300) < 1e-8)

# ---------------------------------------------------------------------------
cat("\n[fase 1 · graficos]\n")
# Los graficos son funciones puras que devuelven un ggplot: se construyen sin
# Shiny. ggplot_build() es lo que de verdad los evalua; sin eso, un error de
# aes() no aparece hasta que el navegador pide la imagen.
dibuja <- function(grafico) {
  inherits(grafico, "ggplot") &&
    !inherits(try(ggplot2::ggplot_build(grafico), silent = TRUE), "try-error")
}
muestra <- muestrear_para_grafico(sintetico, umbral = 200L, semilla = 8L)$datos

probar("histograma con densidad superpuesta",
       dibuja(graficar_histograma(muestra, "valor", 24L, densidad = TRUE)))
probar("densidad kernel", dibuja(graficar_densidad(muestra, "valor")))
probar("caja y bigotes", dibuja(graficar_boxplot(muestra, "valor")))
probar("cajas por grupo con violin",
       dibuja(graficar_boxplot_grupos(muestra, "valor", "grupo", violin = TRUE)))
probar("Q-Q normal", dibuja(graficar_qq(muestra, "valor")))
probar("dispersion con conteo por celda",
       dibuja(graficar_dispersion(muestra, "valor", "observacion",
                                  celdas = TRUE)))
probar("densidad conjunta",
       dibuja(graficar_densidad_conjunta(muestra, "valor", "observacion")))
probar("mosaico de dos cualitativas", {
  cruzado <- sintetico
  cruzado$categoria <- rep(c("alta", "baja"), length.out = nrow(cruzado))
  dibuja(graficar_mosaico(tabla_contingencia(cruzado$grupo, cruzado$categoria)))
})
probar("matriz de dispersion",
       dibuja(graficar_pares(muestra, c("valor", "observacion"))))
probar("mapa de calor de correlaciones",
       dibuja(graficar_heatmap_correlacion(
         matriz_correlacion(sintetico, c("valor", "observacion")))))
probar("coordenadas paralelas",
       dibuja(graficar_coordenadas_paralelas(muestra,
                                             c("valor", "observacion"))))
probar("elipsoide de concentracion",
       dibuja(graficar_elipsoide(muestra, "valor", "observacion")))
probar("Q-Q de Mahalanobis",
       dibuja(graficar_qq_mahalanobis(
         mahalanobis_cuadrado(sintetico[, c("valor", "observacion")]), 2L)))
probar("matriz de nulidad", dibuja(graficar_nulidad(patron_faltantes(con_huecos))))
probar("atipicos marcados",
       dibuja(graficar_atipicos(detectar_atipicos(sintetico, "valor", "z"),
                                "valor")))
probar("antes y despues de transformar", {
  pila <- agregar_transformacion(list(), "logaritmo", "valor")
  dibuja(graficar_antes_despues(sintetico,
                                aplicar_transformaciones(sintetico, pila)$datos,
                                "valor"))
})
probar("perfil de Box-Cox", dibuja(graficar_perfil_boxcox(
  perfil_boxcox(sintetico$valor))))
probar("tamanos de la particion", dibuja(graficar_particion(
  resumir_particion(particionar(sintetico, semilla = 2L)))))
probar("nube con las filas remuestreadas", {
  resultado <- balancear(sintetico, "grupo", "bootstrap", semilla = 6L)
  dibuja(graficar_nube_sinteticos(resultado$datos, "valor", "observacion",
                                  resultado$origen))
})
probar("un grafico sin datos suficientes no falla, avisa",
       dibuja(graficar_elipsoide(sintetico[1, ], "valor", "observacion")))

cat(sprintf("\n[test_fase1] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
