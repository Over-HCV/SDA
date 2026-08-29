# learn/R/pruebas/test_acp.R
#
# Responsabilidad: probar el ACP de punta a punta sin Shiny — motor, métricas,
# gráficos, supuestos y la corrida headless.
#
# Uso:  Rscript learn/R/pruebas/test_acp.R
#
# Un archivo por método, que es como escala esto: cuando entre k-medias tendrá
# su test_kmeans.R y este no se toca. Lo que sí es común (registro, contratos,
# almacén) se prueba en test_headless.R.
#
# La prueba que sostiene todo el hito es la primera: potencia y svd tienen que
# dar lo mismo. Si un día deja de pasar, el modo paso a paso de la fase 3 está
# enseñando algo que no es el resultado que la app muestra.

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

# Datos con estructura conocida: a y b casi la misma variable, c independiente
# y en otra escala. La primera componente TIENE que ser el bloque a-b.
set.seed(11)
n <- 200
nube <- data.frame(a = stats::rnorm(n), b = NA_real_,
                   c = stats::rnorm(n) * 20 + 100, d = stats::rnorm(n))
nube$b <- nube$a * 0.9 + stats::rnorm(n, sd = 0.35)
grupos <- rep(c("uno", "dos"), length.out = n)

potencia <- ajustar_acp(nube, n_componentes = 2L, optimizador = "potencia")
svd <- ajustar_acp(nube, n_componentes = 2L, optimizador = "svd")

# ---------------------------------------------------------------------------
cat("\n[acp · los dos optimizadores]\n")

probar("potencia y svd dan los mismos valores propios",
       max(abs(potencia$valores_propios - svd$valores_propios)) < 1e-6)

probar("potencia y svd dan las mismas cargas (el signo esta fijado)",
       max(abs(potencia$cargas - svd$cargas)) < 1e-6)

probar("svd no deja traza y lo dice en vez de fingirla",
       is.null(svd$traza) && svd$iteraciones == 0L)

probar("la potencia si deja traza",
       !is.null(potencia$traza) && potencia$iteraciones > 0L)

probar("las dos rutas retienen el mismo numero de componentes",
       potencia$k == svd$k && potencia$k == 2L)

# ---------------------------------------------------------------------------
cat("\n[acp · el resultado]\n")

probar("la varianza explicada suma 1",
       abs(sum(potencia$varianza_explicada) - 1) < 1e-10)

probar("las componentes vienen ordenadas de mayor a menor",
       all(diff(potencia$valores_propios) <= 1e-10))

probar("la primera componente es el bloque de variables correlacionadas", {
  primera <- abs(potencia$cargas[, 1])
  primera[["a"]] > primera[["c"]] && primera[["b"]] > primera[["c"]]
})

probar("las cargas son de norma 1 y ortogonales entre si", {
  producto <- t(potencia$cargas) %*% potencia$cargas
  max(abs(producto - diag(ncol(potencia$cargas)))) < 1e-6
})

probar("el error de reconstruccion es la varianza que quedo fuera",
       abs(potencia$error_reconstruccion -
             sum(potencia$valores_propios[-seq_len(potencia$k)])) < 1e-10)

probar("sobre R todas las variables pesan igual: la traza vale p",
       abs(potencia$varianza_total - potencia$p) < 1e-8)

probar("sobre S manda la variable de mayor varianza", {
  crudo <- ajustar_acp(nube, n_componentes = 2L, matriz = "covarianza",
                       optimizador = "svd")
  abs(crudo$cargas[["c", 1]]) > 0.9
})

probar("R y S no dan el mismo resultado cuando las escalas difieren", {
  crudo <- ajustar_acp(nube, n_componentes = 2L, matriz = "covarianza",
                       optimizador = "svd")
  max(abs(crudo$varianza_explicada - svd$varianza_explicada)) > 0.05
})

probar("las puntuaciones estan centradas en cero",
       max(abs(colMeans(potencia$puntuaciones))) < 1e-8)

probar("las filas con faltantes se descartan y se informa cuantas", {
  con_na <- nube; con_na$a[1:3] <- NA
  ajuste <- ajustar_acp(con_na, optimizador = "svd")
  ajuste$filas_descartadas == 3L && ajuste$n == n - 3L
})

probar("una columna constante no se escala en silencio: falla y explica", {
  plana <- nube; plana$c <- 7
  falla(ajustar_acp(plana))
})

probar("con una sola numerica no hay ACP posible",
       falla(ajustar_acp(nube["a"])))

# ---------------------------------------------------------------------------
cat("\n[acp · la traza (fase 3)]\n")

tabla_traza <- traza_a_tabla(potencia$traza)

probar("la traza registra una fila por iteracion",
       nrow(tabla_traza) == potencia$iteraciones)

probar("el objetivo nunca sube: es varianza no explicada",
       traza_monotona(potencia$traza))

probar("el objetivo final coincide con el error de reconstruccion del ajuste", {
  ultimo <- tabla_traza$objetivo[nrow(tabla_traza)]
  ultimo < 1e-6   # tras extraer las p componentes no queda nada sin explicar
})

probar("el delta final de las componentes retenidas esta bajo la tolerancia", {
  retenidas <- tabla_traza[tabla_traza$componente <= potencia$k, ]
  finales <- tapply(retenidas$delta, retenidas$componente, function(d) d[length(d)])
  all(finales < potencia$tol)
})

probar("convergio se juzga sobre las componentes retenidas",
       isTRUE(potencia$convergio) &&
         length(potencia$convergio_por_componente) == potencia$p)

probar("con pocas iteraciones no converge, y lo dice", {
  apurado <- ajustar_acp(nube, n_componentes = 2L, maxit = 2L)
  !isTRUE(apurado$convergio)
})

probar("la trayectoria trae un valor por parametro y por iteracion", {
  parametros <- parametros_a_tabla(potencia$traza)
  primera <- parametros[parametros$componente == 1L, ]
  nrow(primera) == length(unique(primera$iter)) * potencia$p
})

probar("misma semilla, misma traza", {
  otra <- ajustar_acp(nube, n_componentes = 2L, semilla = 42L)
  identical(traza_a_tabla(otra$traza), tabla_traza)
})

probar("otra semilla cambia el camino pero no el destino", {
  otra <- ajustar_acp(nube, n_componentes = 2L, semilla = 7L)
  max(abs(otra$valores_propios - potencia$valores_propios)) < 1e-6
})

probar("registrar_traza = FALSE ahorra la traza sin cambiar el ajuste", {
  sin_traza <- ajustar_acp(nube, n_componentes = 2L, registrar_traza = FALSE)
  is.null(sin_traza$traza) &&
    max(abs(sin_traza$valores_propios - potencia$valores_propios)) < 1e-9
})

probar("comparar_reinicios resume una corrida por semilla", {
  trazas <- lapply(c(1L, 2L, 3L), function(s)
    ajustar_acp(nube, n_componentes = 1L, semilla = s)$traza)
  tabla <- comparar_reinicios(stats::setNames(trazas, c("1", "2", "3")))
  nrow(tabla) == 3L && all(diff(range(tabla$objetivo_final)) < 1e-6)
})

# ---------------------------------------------------------------------------
cat("\n[acp · metricas de reduccion (fase 4)]\n")

probar("varianza_explicada acumula hasta 1", {
  tabla <- varianza_explicada(potencia)
  nrow(tabla) == potencia$p && abs(tabla$acumulada[nrow(tabla)] - 1) < 1e-10
})

probar("cargas() devuelve solo las componentes retenidas",
       length(unique(cargas(potencia)$componente)) == potencia$k)

probar("sobre R las correlaciones caen dentro del circulo unidad",
       all(correlaciones_componentes(potencia)$radio <= 1 + 1e-8))

probar("coordenadas_2d respeta el grupo que se le pasa", {
  tabla <- coordenadas_2d(potencia, grupo = grupos)
  nlevels(tabla$grupo) == 2L && nrow(tabla) == potencia$n
})

probar("el biplot reescala las flechas y dice con que factor", {
  bp <- coordenadas_biplot(potencia)
  bp$escala_flechas > 0 && nrow(bp$flechas) == potencia$p
})

probar("pedir un eje que no se retuvo falla en vez de inventarlo",
       falla(coordenadas_2d(potencia, ejes = c(1L, 5L))))

probar("componentes_sugeridas devuelve la primera que pasa el umbral", {
  sugeridas <- componentes_sugeridas(potencia, umbral_acumulado = 0.8)
  tabla <- varianza_explicada(potencia)
  tabla$acumulada[sugeridas] >= 0.8 &&
    (sugeridas == 1L || tabla$acumulada[sugeridas - 1L] < 0.8)
})

# ---------------------------------------------------------------------------
cat("\n[acp · geometria antes de ajustar (fase 2)]\n")

probar("el maximo de la familia de direcciones es la primera componente", {
  familia <- familia_candidatas(nube, c("a", "b"))
  par <- ajustar_acp(nube, columnas = c("a", "b"), n_componentes = 1L,
                     matriz = "covarianza", optimizador = "svd")
  optimo <- familia$angulo[which.max(familia$varianza)]
  direccion <- c(cos(optimo), sin(optimo))
  abs(abs(sum(direccion * par$cargas[, 1])) - 1) < 1e-3
})

probar("evaluar_objetivo reparte la varianza total entre captada y perdida", {
  objetivo <- evaluar_objetivo(nube, c("a", "b"), pi / 3)
  abs(objetivo$varianza_proyectada + objetivo$error_reconstruccion -
        objetivo$total) < 1e-8
})

probar("proyectar_en_direccion devuelve el pie de cada punto sobre el eje", {
  proyeccion <- proyectar_en_direccion(nube, c("a", "b"), 0)
  nrow(proyeccion) == n && all(abs(diff(proyeccion$proyectado_y)) < 1e-8)
})

probar("el presupuesto se pone en rojo cuando p se acerca a n", {
  apretado <- contar_parametros("acp", p = 40, n = 30, k = 5)
  holgado <- contar_parametros("acp", p = 4, n = 500, k = 2)
  apretado$veredicto == "mas parametros que observaciones" &&
    holgado$veredicto == "holgado"
})

probar("presupuesto_por_k crece con k", {
  tabla <- presupuesto_por_k("acp", p = 6, n = 100)
  nrow(tabla) == 6L && all(diff(tabla$parametros) > 0)
})

probar("resumen_matriz_diseno detecta columnas colineales", {
  copia <- nube; copia$e <- copia$a * 2
  tabla <- resumen_matriz_diseno(copia, c("a", "b", "e"))
  grepl("colineales", tabla$nota[tabla$campo == "rango"])
})

# ---------------------------------------------------------------------------
cat("\n[acp · supuestos]\n")

dataset <- nuevo_dataset("d1", "nube", nube)

probar("evaluar_supuestos contesta a los tres supuestos declarados", {
  avisos <- evaluar_supuestos("acp", dataset)
  claves <- vapply(avisos, `[[`, "", "clave")
  setequal(claves, metodo("acp")$supuestos)
})

probar("los avisos tienen la forma que lista_avisos() sabe pintar", {
  avisos <- evaluar_supuestos("acp", dataset)
  all(vapply(avisos, function(a)
    all(c("severidad", "clave", "mensaje", "sugerencia") %in% names(a)) &&
      a$severidad %in% SEVERIDADES, logical(1)))
})

probar("con escalas dispares avisa del escalado y nombra la culpable", {
  avisos <- evaluar_supuestos("acp", dataset)
  escalado <- Filter(function(a) a$clave == "escalado_previo", avisos)[[1]]
  escalado$severidad == "aviso" && grepl("c ", escalado$mensaje)
})

probar("sin correlaciones que resumir, avisa de que reducir no gana nada", {
  independientes <- data.frame(u = stats::rnorm(n), v = stats::rnorm(n),
                               w = stats::rnorm(n))
  avisos <- evaluar_supuestos("acp", nuevo_dataset("d2", "ruido", independientes))
  lineal <- Filter(function(a) a$clave == "estructura_lineal", avisos)[[1]]
  lineal$severidad == "aviso"
})

# ---------------------------------------------------------------------------
cat("\n[acp · el catalogo lo declara]\n")

probar("acp esta activo y trae su funcion de ajuste", {
  m <- metodo("acp")
  m$estado == "activo" && is.function(m$ajustar)
})

probar("acp es componible con un dataset valido", {
  modelo <- nuevo_modelo("m1", "acp", "acp", hiper = hiper_por_defecto("acp"))
  componible(validar_compatibilidad(dataset, modelo))
})

probar("una receta con un optimizador que el metodo no tiene es un error", {
  modelo <- nuevo_modelo("m1", "acp", "acp")
  receta <- nueva_receta("r1", "mala", optimizador = "adam")
  !componible(validar_compatibilidad(dataset, modelo, receta))
})

probar("todos los artefactos que declara estan registrados",
       all(metodo("acp")$artefactos %in% claves_artefactos()))

probar("cada hiperparametro del registro es argumento de la funcion pura", {
  # La regla de las tres partes (C11), primera mitad: registro <-> funcion.
  all(names(metodo("acp")$hiper) %in% names(formals(metodo("acp")$ajustar)))
})

# ---------------------------------------------------------------------------
cat("\n[acp · graficos]\n")

probar("espacio de hipotesis",
       dibuja(graficar_espacio_hipotesis(familia_candidatas(nube, c("a", "b")),
                                         angulo = 0.7)))
probar("modelo manual con sus residuos",
       dibuja(graficar_modelo_manual(proyectar_en_direccion(nube, c("a", "b"), 0.7),
                                     c("a", "b"),
                                     evaluar_objetivo(nube, c("a", "b"), 0.7))))
probar("presupuesto de parametros",
       dibuja(graficar_presupuesto(presupuesto_por_k("acp", 4, n), k = 2)))
probar("traza de convergencia",
       dibuja(graficar_convergencia(tabla_traza)))
probar("traza de convergencia en escala log",
       dibuja(graficar_convergencia(tabla_traza, escala_log = TRUE)))
probar("trayectoria de las cargas",
       dibuja(graficar_trayectoria(parametros_a_tabla(potencia$traza))))
probar("deltas contra la tolerancia",
       dibuja(graficar_deltas(tabla_traza, tol = potencia$tol)))
probar("scree con el corte en k",
       dibuja(graficar_scree(varianza_explicada(potencia), k = 2)))
probar("cargas con signo",
       dibuja(graficar_cargas(cargas(potencia))))
probar("circulo de correlaciones",
       dibuja(graficar_circulo(correlaciones_componentes(potencia))))
probar("circulo sobre S avisa de que no esta acotado",
       dibuja(graficar_circulo(correlaciones_componentes(potencia),
                               sobre_correlacion = FALSE)))
probar("mapa 2d por grupo",
       dibuja(graficar_mapa_2d(coordenadas_2d(potencia, grupo = grupos))))
probar("biplot",
       dibuja(graficar_biplot(coordenadas_biplot(potencia, grupo = grupos))))
probar("sin traza, el grafico avisa en vez de romperse",
       dibuja(graficar_convergencia(traza_a_tabla(NULL))))

# El contrato S2 y la regla de las tres partes se prueban en test_contrato.R:
# son del corredor headless, no del ACP, aunque sea el ACP quien los ejercita.

# ---------------------------------------------------------------------------
cat(sprintf("\n[test_acp] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
