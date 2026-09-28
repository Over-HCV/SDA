# learn/R/pruebas/test_acm.R
#
# Responsabilidad: probar el análisis de correspondencias múltiples sin Shiny.
#
# Uso:  Rscript learn/R/pruebas/test_acm.R
#
# Lo que sostiene este archivo es la identidad de la inercia: la suma de los
# valores propios de un ACM es J/Q − 1, y no depende de los datos. Si eso falla,
# la descomposición no es la del método y todos los porcentajes que la app
# muestre serán creíbles y falsos.
#
# La otra prueba que importa es que las genéricas de la familia contestan sin una
# línea nueva: el ACM entra a la fase 4 por las mismas funciones que el ACP.

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)
# El corredor del batch, para probar el mismo camino que usa la fase 4.
source("learn/R/run_headless.R")

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

# El ejemplo de la clase: ojos y cabello asociados, empleo y vivienda casi
# independientes. El primer eje tiene que ser el bloque ojos-cabello.
set.seed(19)
n <- 300
tabla <- data.frame(
  ojos = sample(c("claros", "oscuros"), n, TRUE, c(0.4, 0.6)),
  empleo = sample(c("empleado", "desempleado"), n, TRUE, c(0.7, 0.3)),
  vivienda = sample(c("propia", "arriendo", "familiar"), n, TRUE))
tabla$cabello <- ifelse(tabla$ojos == "claros",
                        sample(c("claro", "oscuro"), n, TRUE, c(0.85, 0.15)),
                        sample(c("claro", "oscuro"), n, TRUE, c(0.15, 0.85)))

indicadora <- matriz_indicadora(tabla, names(tabla))
burt <- matriz_burt(indicadora)
ajuste <- ajustar_acm(tabla, names(tabla), n_componentes = 2L)

# ---------------------------------------------------------------------------
cat("\n[la matriz indicadora y la de Burt]\n")

probar("una columna por categoria de cada variable",
       ncol(indicadora) == sum(vapply(tabla, function(x) length(unique(x)),
                                      integer(1))))

probar("cada fila tiene exactamente un 1 por variable",
       all(rowSums(indicadora) == ncol(tabla)))

probar("la suma de una columna es la frecuencia de esa categoria",
       identical(unname(colSums(indicadora)[1:2]),
                 unname(as.numeric(table(tabla$ojos)))))

probar("dice a que variable pertenece cada columna",
       length(attr(indicadora, "variables")) == ncol(indicadora))

probar("con una sola variable no hay cruce que hacer",
       falla(matriz_indicadora(tabla, "ojos")))

probar("la de Burt es cuadrada y simetrica",
       nrow(burt) == ncol(indicadora) && isSymmetric(burt))

probar("en su diagonal estan las frecuencias",
       all(diag(burt) == colSums(indicadora)))

probar("un bloque fuera de la diagonal es una tabla de contingencia",
       burt["ojos=claros", "cabello=claro"] ==
         sum(tabla$ojos == "claros" & tabla$cabello == "claro"))

# ---------------------------------------------------------------------------
cat("\n[el ajuste]\n")

probar("las dimensiones no triviales son J - Q",
       ajuste$p == ajuste$J - ajuste$Q)

probar("la inercia total es J/Q - 1 y no depende de los datos",
       abs(ajuste$varianza_total - (ajuste$J / ajuste$Q - 1)) < 1e-12)

probar("los valores propios suman la inercia total",
       abs(sum(ajuste$valores_propios) - ajuste$varianza_total) < 1e-10)

probar("ningun valor propio pasa de 1",
       all(ajuste$valores_propios <= 1 + 1e-10))

probar("vienen ordenados de mayor a menor",
       all(diff(ajuste$valores_propios) <= 1e-10))

probar("las dimensiones de la fila no se correlacionan entre si",
       max(abs(correlacion_puntuaciones(ajuste) -
                 diag(ajuste$k))) < 1e-10)

probar("hay una coordenada por individuo y otra por categoria",
       nrow(ajuste$puntuaciones) == n &&
         nrow(ajuste$cargas) == ncol(indicadora))

probar("el primer eje separa el bloque ojos-cabello", {
  coordenada <- ajuste$cargas[, 1]
  # Claros con claros a un lado, oscuros con oscuros al otro.
  sign(coordenada["ojos=claros"]) == sign(coordenada["cabello=claro"]) &&
    sign(coordenada["ojos=oscuros"]) == sign(coordenada["cabello=oscuro"]) &&
    sign(coordenada["ojos=claros"]) != sign(coordenada["ojos=oscuros"])
})

probar("declara la clase de la familia, no solo la propia",
       inherits(ajuste, "ajuste_acm") && inherits(ajuste, "ajuste_reduccion"))

probar("no guarda centro ni escala, y por eso no admite suplementarios",
       is.null(ajuste$centro) && falla(proyectar_individuos(ajuste, tabla)))

probar("con columnas numericas no hay categorias que cruzar",
       falla(ajustar_acm(data.frame(a = 1:10, b = 11:20), c("a", "b"))))

# ---------------------------------------------------------------------------
cat("\n[las genericas de la familia contestan]\n")

probar("metricas_de_corrida trae n, p, k y la varianza acumulada", {
  m <- metricas_de_corrida(ajuste)
  m$n == n && m$k == 2L && m$p == ajuste$p && m$varianza_acumulada > 0
})

probar("tabla_resultado es la varianza explicada por dimension",
       nrow(tabla_resultado(ajuste)) == ajuste$p)

probar("etiquetas_ejes usa los nombres del ACM",
       identical(etiquetas_ejes(ajuste), c("Dim1", "Dim2")))

probar("coordenadas_2d ubica a los individuos",
       nrow(coordenadas_2d(ajuste, c(1L, 2L))) == n)

probar("resumen_ajuste y lectura_resultado dicen algo",
       length(resumen_ajuste(ajuste)) == 3L &&
         grepl("componentes", lectura_resultado(ajuste)))

probar("Kaiser en un ACM corta en 1/Q, que es la media", {
  fila <- reglas_k(ajuste)
  fila <- fila[fila$regla == "Kaiser", ]
  grepl("1/Q", fila$detalle) &&
    fila$k == sum(ajuste$valores_propios > 1 / ajuste$Q)
})

probar("contribuciones y cargas se pueden pedir igual",
       nrow(contribuciones(ajuste)) == 2L * nrow(ajuste$cargas))

# ---------------------------------------------------------------------------
cat("\n[el catalogo lo declara]\n")

dataset <- nuevo_dataset("d1", "tabla cualitativa", tabla)

probar("acm esta activo y trae su funcion de ajuste",
       ejecutable("acm") && is.function(metodo("acm")$ajustar))

probar("acs queda como pendiente, con la ruta visible",
       metodo("acs")$estado == "pendiente")

probar("todos los artefactos que declara estan registrados",
       all(metodo("acm")$artefactos %in% claves_artefactos()))

probar("cada hiperparametro del registro es argumento de la funcion pura",
       all(names(metodo("acm")$hiper) %in%
             names(formals(metodo("acm")$ajustar))))

probar("acm es componible con un dataset cualitativo", {
  modelo <- nuevo_modelo("m1", "acm", "acm", spec = names(tabla),
                         hiper = list(n_componentes = 2L))
  componible(validar_compatibilidad(dataset, modelo))
})

probar("un dataset solo numerico no le sirve", {
  numerico <- nuevo_dataset("d2", "numerico",
                            data.frame(a = stats::rnorm(20), b = stats::rnorm(20)))
  modelo <- nuevo_modelo("m2", "acm", "acm", hiper = list(n_componentes = 2L))
  !componible(validar_compatibilidad(numerico, modelo))
})

probar("el mensaje habla de variables cualitativas y no de numericas", {
  numerico <- nuevo_dataset("d3", "numerico",
                            data.frame(a = stats::rnorm(20), b = stats::rnorm(20)))
  modelo <- nuevo_modelo("m3", "acm", "acm", hiper = list(n_componentes = 2L))
  avisos <- validar_compatibilidad(numerico, modelo)
  any(grepl("cualitativas", vapply(avisos, `[[`, "", "mensaje")))
})

probar("las columnas admisibles de un ACM son las cualitativas",
       identical(columnas_admisibles(dataset, "matriz_cualitativa"),
                 names(tabla)))

# ---------------------------------------------------------------------------
cat("\n[el corredor lo ajusta igual que la app]\n")

# El mismo camino que usa la fase 4: `argumentos_ajuste()` filtra los mandos que
# esta familia no tiene (no hay optimizador ni tolerancia que pasarle) y la
# corrida sale con las metricas de la familia. Es la tercera pata de C11.
salida <- file.path("learn", "outputs", "test-acm")
on.exit(unlink(ruta_repo(salida), recursive = TRUE), add = TRUE)

probar("el batch corre un ACM sin mandos de optimizador", {
  corrida <- correr("prueba-acm", metodo = "acm", fuente = tabla,
                    columnas = names(tabla), hiper = list(n_componentes = 2L),
                    out_dir = salida)
  corrida$metodo == "acm" && corrida$metricas$k == 2L &&
    corrida$estado == "listo"
})

probar("y el JSON de esa corrida se puede releer", {
  leido <- jsonlite::fromJSON(file.path(ruta_repo(salida), "prueba-acm.json"))
  leido$metricas$p == ajuste$p && leido$params$n_componentes == 2L
})

# ---------------------------------------------------------------------------
cat("\n[supuestos]\n")

probar("con categorias pobladas el supuesto pasa", {
  avisos <- evaluar_supuestos("acm", dataset)
  vapply(avisos, `[[`, "", "severidad")[1] == "ok"
})

probar("una categoria con tres casos es un aviso, no un error", {
  rara <- tabla
  rara$vivienda[1:297] <- "propia"
  avisos <- evaluar_supuestos("acm", nuevo_dataset("d4", "rara", rara))
  vapply(avisos, `[[`, "", "severidad")[1] == "aviso"
})

probar("el ACP avisa de las cualitativas que quedan fuera y nombra el ACM", {
  mezclado <- tabla
  mezclado$peso <- stats::rnorm(n)
  mezclado$altura <- stats::rnorm(n)
  avisos <- evaluar_supuestos("acp", nuevo_dataset("d5", "mezclado", mezclado))
  mensajes <- paste(vapply(avisos, `[[`, "", "mensaje"),
                    vapply(avisos, `[[`, "", "sugerencia"), collapse = " ")
  grepl("ACM", mensajes) && grepl("cualitativa", mensajes)
})

probar("y es un error si una cualitativa esta marcada en la especificacion", {
  mezclado <- tabla
  mezclado$peso <- stats::rnorm(n)
  avisos <- evaluar_supuestos("acp", nuevo_dataset("d6", "mezclado", mezclado),
                              columnas = c("peso", "ojos"))
  "error" %in% vapply(avisos, `[[`, "", "severidad")
})

# ---------------------------------------------------------------------------
cat("\n[graficos y matriz de diseno]\n")

probar("scree con las reglas",
       dibuja(graficar_scree(varianza_explicada(ajuste), k = ajuste$k,
                             reglas = reglas_k(ajuste))))
probar("coordenadas de las categorias como cargas",
       dibuja(graficar_cargas(cargas(ajuste))))
probar("mapa 2d de los individuos",
       dibuja(graficar_mapa_2d(coordenadas_2d(ajuste, c(1L, 2L)))))
probar("ortogonalidad",
       dibuja(graficar_heatmap_correlacion(correlacion_puntuaciones(ajuste))))

probar("la matriz de diseno cualitativa reporta Q, J e inercia", {
  resumen <- resumen_matriz_diseno(tabla, names(tabla))
  campos <- resumen$campo
  all(c("variables (Q)", "categorias (J)", "inercia total") %in% campos) &&
    resumen$valor[campos == "inercia total"] ==
      sprintf("%.3f", ajuste$J / ajuste$Q - 1)
})

probar("y no habla de rango, que en cualitativas no significa nada",
       !"rango" %in% resumen_matriz_diseno(tabla, names(tabla))$campo)

# ---------------------------------------------------------------------------
cat(sprintf("\n[test_acm] %s\n",
            if (.FALLOS) sprintf("%d FALLO(S)", .FALLOS) else "todo verde"))
if (.FALLOS) quit(status = 1L)
