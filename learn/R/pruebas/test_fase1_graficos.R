# learn/R/pruebas/test_fase1_graficos.R
#
# Responsabilidad: probar los gráficos de la fase 1, sin Shiny.
#
# Uso:  Rscript learn/R/pruebas/test_fase1_graficos.R
#
# Vive aparte de test_fase1.R por C2: la lógica y los gráficos son dos ejes,
# y juntos pasaban el techo de 300 LOC.
#
# Los gráficos son funciones puras que devuelven un ggplot: se construyen sin
# Shiny. ggplot_build() es lo que de verdad los evalúa; sin eso, un error de
# aes() no aparece hasta que el navegador pide la imagen.

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

dibuja <- function(grafico) {
  inherits(grafico, "ggplot") &&
    !inherits(try(ggplot2::ggplot_build(grafico), silent = TRUE), "try-error")
}

sintetico <- gen_sintetico(n = 300, k_grupos = 3, efecto = 4, semilla = 7,
                           tipo = "anova")
con_huecos <- data.frame(x = rnorm(50), y = rnorm(50),
                         g = rep(c("a", "b"), 25), stringsAsFactors = FALSE)
con_huecos$x[c(2, 5)] <- NA
muestra <- muestrear_para_grafico(sintetico, umbral = 200L, semilla = 8L)$datos

cat("\n[fase 1 · graficos univariados]\n")
probar("histograma con densidad superpuesta",
       dibuja(graficar_histograma(muestra, "valor", 24L, densidad = TRUE)))
probar("densidad kernel", dibuja(graficar_densidad(muestra, "valor")))
probar("la normal de la densidad se ajusta a los datos, no a la malla", {
  grafico <- graficar_densidad(muestra, "valor", normal = TRUE)
  normal <- ggplot2::layer_data(grafico, 3L)
  valores <- muestra$valor[!is.na(muestra$valor)]
  pico <- stats::dnorm(0, 0, stats::sd(valores))
  abs(max(normal$y) - pico) / pico < 0.01
})
probar("caja y bigotes", dibuja(graficar_boxplot(muestra, "valor")))
probar("cajas por grupo con violin",
       dibuja(graficar_boxplot_grupos(muestra, "valor", "grupo", violin = TRUE)))
probar("Q-Q normal", dibuja(graficar_qq(muestra, "valor")))
probar("histograma con la normal ajustada superpuesta",
       dibuja(graficar_histograma(muestra, "valor", normal = TRUE)))
probar("densidad kernel contra la normal ajustada",
       dibuja(graficar_densidad(muestra, "valor", normal = TRUE)))

cat("\n[fase 1 · graficos bivariados]\n")
probar("dispersion con conteo por celda",
       dibuja(graficar_dispersion(muestra, "valor", "observacion",
                                  celdas = TRUE)))
probar("la recta de regresion coincide con lm()", {
  recta <- ajustar_recta(sintetico$valor, sintetico$observacion)
  modelo <- stats::lm(observacion ~ valor, data = sintetico)
  isTRUE(all.equal(c(recta$corte, recta$pendiente), unname(stats::coef(modelo)))) &&
    isTRUE(all.equal(recta$r2, summary(modelo)$r.squared))
})
probar("sin variacion en x la recta no se inventa",
       is.na(ajustar_recta(rep(1, 10), 1:10)$pendiente))
probar("dispersion con recta de regresion y su ecuacion", {
  grafico <- graficar_dispersion(muestra, "valor", "observacion",
                                 suavizado = TRUE, regresion = TRUE)
  dibuja(grafico) && grepl("R²", grafico$labels$subtitle, fixed = TRUE)
})
probar("densidad conjunta",
       dibuja(graficar_densidad_conjunta(muestra, "valor", "observacion")))
probar("dispersion con histogramas marginales", {
  compuesto <- graficar_dispersion_marginal(muestra, "valor", "observacion")
  # No es un ggplot: es el gtable de los tres paneles ya alineados. La prueba
  # de que sirve es que se DIBUJA, no que se construye.
  inherits(compuesto, "gtable") &&
    !inherits(try({
      grDevices::pdf(NULL); on.exit(grDevices::dev.off())
      grid::grid.draw(compuesto)
    }, silent = TRUE), "try-error")
})
probar("mosaico de dos cualitativas", {
  cruzado <- sintetico
  cruzado$categoria <- rep(c("alta", "baja"), length.out = nrow(cruzado))
  dibuja(graficar_mosaico(tabla_contingencia(cruzado$grupo, cruzado$categoria)))
})

cat("\n[fase 1 · graficos multivariados y de preparacion]\n")
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
probar("un grafico sin datos suficientes no falla, avisa",
       dibuja(graficar_elipsoide(sintetico[1, ], "valor", "observacion")))
probar("matriz de nulidad", dibuja(graficar_nulidad(patron_faltantes(con_huecos))))
probar("el subtitulo de atipicos dice el criterio y su umbral", {
  tabla <- detectar_atipicos(sintetico, "valor", "z", 2.5)
  grafico <- graficar_atipicos(tabla, "valor")
  grepl("z > 2.5", grafico$labels$subtitle, fixed = TRUE)
})
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
probar("las clases del balance van rotadas para no pisarse", {
  grafico <- graficar_balance(resumir_balance(sintetico, "grupo"))
  dibuja(grafico) && identical(grafico$theme$axis.text.x$angle, 20)
})

cat(sprintf("\n[test_fase1_graficos] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
