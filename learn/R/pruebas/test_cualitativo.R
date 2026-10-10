# learn/R/pruebas/test_cualitativo.R
#
# Responsabilidad: probar la familia cualitativa de la fase 4
# (logica/metricas_cualitativo.R) sin depender de que los métodos existan.
#
# Uso:  Rscript learn/R/pruebas/test_cualitativo.R
#
# Los ajustes de acá son FALSOS a propósito: se arman a mano con Zoo y una
# partición conocida, siguiendo el contrato de `ajuste_cualitativo`. Así lo que
# se prueba es la lectura (perfiles, silueta, plano, cruce, ARI, gráficos) y
# no el algoritmo, que tiene su propio test_<clave>.R.

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

zoo <- cargar_zoo()
COLUMNAS <- setdiff(names(zoo), c("animal", "tipo"))

#' Un ajuste cualitativo de mentira con la partición `grupos`.
ajuste_falso <- function(grupos, clave = "kmodos", extra = list()) {
  x <- zoo[COLUMNAS]
  rownames(x) <- zoo$animal
  k <- max(grupos)
  modos <- as.data.frame(lapply(x, function(v) vapply(seq_len(k), function(j)
    names(which.max(table(v[grupos == j]))), "")))
  rownames(modos) <- paste0("g", seq_len(k))
  structure(c(list(grupos = as.integer(grupos), k = k, n = nrow(x),
                   p = ncol(x), tamanos = tabulate(grupos, k),
                   columnas = COLUMNAS, filas_descartadas = 0L, semilla = 42L,
                   x = x, modos = modos), extra),
            class = c(paste0("ajuste_", clave), "ajuste_cualitativo",
                      "ajuste_agrupamiento", "ajuste_sda"))
}

por_tipo <- ajuste_falso(as.integer(zoo$tipo),
                         extra = list(costo = 87, disimilitud =
                                        "emparejamiento_simple"))
set.seed(1)
al_azar <- ajuste_falso(sample(rep(1:4, length.out = nrow(zoo))))

cat("\n[ARI · casos a mano]\n")
probar("dos particiones idénticas dan 1",
       indice_rand_ajustado(c(1, 1, 2, 2, 3), c(1, 1, 2, 2, 3)) == 1)
probar("la numeración no importa: renombrar los grupos sigue dando 1",
       indice_rand_ajustado(c(1, 1, 2, 2, 3), c("b", "b", "c", "c", "a")) == 1)
probar("cruzadas por completo dan -0.5 (E = 2/3, máximo 2, acuerdo 0)",
       abs(indice_rand_ajustado(c(1, 1, 2, 2), c(1, 2, 1, 2)) + 0.5) < 1e-12)
probar("3+3 contra 2+2+2 da 8/33 (acuerdo 2, E = 1.2, máximo 4.5)",
       abs(indice_rand_ajustado(c(1, 1, 1, 2, 2, 2), c(1, 1, 2, 2, 3, 3)) -
             8 / 33) < 1e-12)
probar("las dos triviales iguales (todo en un grupo) dan 1, no NaN",
       indice_rand_ajustado(rep(1, 5), rep(7, 5)) == 1)
probar("es simétrico", {
  a <- c(1, 1, 2, 3, 3, 3, 2); b <- c(2, 2, 2, 1, 1, 3, 3)
  identical(indice_rand_ajustado(a, b), indice_rand_ajustado(b, a))
})
probar("los NA se ignoran en vez de propagarse",
       indice_rand_ajustado(c(1, 1, 2, NA), c(5, 5, 6, 6)) == 1)
probar("una partición al azar contra tipo queda cerca de 0",
       abs(indice_rand_ajustado(al_azar$grupos, zoo$tipo)) < 0.1)

cat("\n[perfiles de los grupos]\n")
perfiles <- perfiles_grupos(por_tipo)
probar("las proporciones suman 1 en cada grupo x variable", {
  sumas <- tapply(perfiles$proporcion, paste(perfiles$grupo, perfiles$variable),
                  sum)
  all(abs(sumas - 1) < 1e-12)
})
probar("hay exactamente un modo por grupo x variable", all(tapply(
  perfiles$modal, paste(perfiles$grupo, perfiles$variable), sum) == 1))
probar("el modo marcado es el de la tabla de modos (pelo del grupo 1 = si)",
       perfiles$categoria[perfiles$modal & perfiles$grupo == 1 &
                            perfiles$variable == "pelo"] == "si")
probar("la columna global es la proporción en toda la muestra", {
  fila <- perfiles[perfiles$grupo == 1 & perfiles$variable == "leche" &
                     perfiles$categoria == "si", ]
  abs(fila$global - mean(zoo$leche == "si")) < 1e-12 && fila$proporcion == 1
})
probar("con `probabilidades` (clases latentes) se usan las estimadas", {
  estimadas <- lapply(COLUMNAS, function(v) {
    niveles <- levels(droplevels(zoo[[v]]))
    m <- matrix(1 / length(niveles), 7, length(niveles),
                dimnames = list(NULL, niveles))
    m
  })
  names(estimadas) <- COLUMNAS
  latente <- ajuste_falso(as.integer(zoo$tipo), "clases_latentes",
                          list(probabilidades = estimadas))
  tabla <- perfiles_grupos(latente)
  all(abs(tabla$proporcion[tabla$variable == "patas"] - 1 / 6) < 1e-12)
})

cat("\n[silueta con disimilitud categórica]\n")
probar("emparejamiento simple: 0 consigo misma y la fracción de desacuerdos", {
  d <- disimilitud_simple(por_tipo$x[1:3, ])
  all(diag(d) == 0) &&
    abs(d[1, 3] - mean(unlist(lapply(COLUMNAS, function(v)
      as.character(zoo[[v]][1]) != as.character(zoo[[v]][3]))))) < 1e-12
})
silueta_tipo <- silueta(por_tipo)
probar("la silueta coincide con cluster::silhouette sobre la misma distancia", {
  referencia <- cluster::silhouette(por_tipo$grupos,
                                    stats::as.dist(disimilitud_simple(por_tipo$x)))
  max(abs(referencia[, "sil_width"] - silueta_tipo$s)) < 1e-10
})
probar("la partición por tipo tiene silueta media mayor que una al azar",
       mean(silueta_tipo$s) > mean(silueta(al_azar)$s) + 0.3)
probar("con `matriz_disimilitud` (Gower) se usa la guardada", {
  constante <- stats::as.dist(matrix(1, 101, 101))
  gower <- ajuste_falso(as.integer(zoo$tipo), "gower",
                        list(matriz_disimilitud = constante))
  all(silueta(gower)$s == 0)
})

cat("\n[genéricas de la fase 4]\n")
probar("coordenadas_2d devuelve n x 2 en el plano del ACM", {
  plano <- coordenadas_2d(por_tipo)
  acm <- ajustar_acm(por_tipo$x, COLUMNAS, n_componentes = 2L)
  nrow(plano) == 101L && all(c("x", "y", "grupo") %in% names(plano)) &&
    max(abs(plano$x - acm$puntuaciones[, 1])) < 1e-12
})
probar("otros ejes y un color que no es la partición (la clase real)", {
  plano <- coordenadas_2d(por_tipo, ejes = c(2, 3), grupo = zoo$tipo)
  identical(levels(plano$grupo), levels(zoo$tipo)) && nrow(plano) == 101L
})
probar("los ejes llevan la inercia del ACM",
       all(grepl("^Dim[1-5] \\([0-9.]+ %\\)$", etiquetas_ejes(por_tipo))))
probar("metricas_de_corrida trae silueta y costo, y sin clase no trae ARI", {
  m <- metricas_de_corrida(por_tipo)
  m$costo == 87 && is.numeric(m$silueta_media) && is.null(m$ari) &&
    !"inercia" %in% names(m)
})
probar("tabla_resultado describe cada grupo por sus rasgos", {
  tabla <- tabla_resultado(por_tipo)
  nrow(tabla) == 7L && grepl("leche=si", tabla$rasgos[1])
})
probar("resumen_ajuste y lectura_resultado responden en español", {
  r <- resumen_ajuste(por_tipo)
  identical(r$disimilitud, "emparejamiento_simple") && !is.null(r$costo) &&
    grepl("categoría más frecuente", lectura_resultado(por_tipo))
})
probar("el reparto de tamaños sirve aunque no haya inercia", {
  tabla <- resumen_grupos(por_tipo)
  all(is.na(tabla$inercia)) && sum(tabla$n) == 101L
})

cat("\n[clase de referencia y cruce]\n")
ds <- nuevo_dataset(NULL, "zoo", zoo, fuente = "zoo")
ds$diccionario <- actualizar_diccionario(ds$diccionario, "tipo", "rol",
                                         "respuesta")
con_clase <- adjuntar_referencia(por_tipo, ds)
probar("la clase se lee del rol 'respuesta' del diccionario",
       identical(columna_referencia(ds), "tipo") &&
         length(con_clase$referencia) == 101L)
probar("con clase adjunta, el ARI entra a las métricas y a la lectura", {
  m <- metricas_de_corrida(con_clase)
  m$ari == 1 && grepl("ARI es 1.000", lectura_resultado(con_clase))
})
probar("cruce_con_clase: tabla, ARI y pureza", {
  cruce <- cruce_con_clase(con_clase)
  sum(cruce$tabla) == 101L && cruce$ari == 1 && cruce$pureza == 1 &&
    identical(colnames(cruce$tabla)[1], "mamifero")
})
probar("sin clase, el cruce falla diciendo cómo declararla", {
  error <- tryCatch(cruce_con_clase(por_tipo), error = conditionMessage)
  grepl("respuesta", error) && grepl("--clase", error)
})
probar("si la clase entró al ajuste, adjuntarla avisa", {
  tramposo <- por_tipo
  tramposo$columnas <- c(tramposo$columnas, "tipo")
  aviso <- tryCatch(adjuntar_referencia(tramposo, ds),
                    warning = conditionMessage)
  is.character(aviso) && grepl("contaminada", aviso)
})
probar("k-medias también acepta la referencia (el tándem se mide igual)", {
  numerico <- ds
  numerico$df$a <- rnorm(101); numerico$df$b <- rnorm(101)
  km <- ajustar_kmeans(numerico$df, columnas = c("a", "b"), k = 3L)
  is.numeric(metricas_de_corrida(adjuntar_referencia(km, numerico))$ari)
})

cat("\n[artefactos: registro, texto y PNG]\n")
seleccion <- data.frame(k = 2:6, log_verosimilitud = -c(900, 780, 720, 700, 695),
                        n_parametros = 34 * (2:6) - 1)
seleccion$bic <- -2 * seleccion$log_verosimilitud +
  seleccion$n_parametros * log(101)
seleccion$aic <- -2 * seleccion$log_verosimilitud + 2 * seleccion$n_parametros
latente <- ajuste_falso(as.integer(zoo$tipo), "clases_latentes",
                        list(seleccion = seleccion, bic = 1800))
latente$referencia <- zoo$tipo

#' Logica registrada sobre el ajuste y grafico registrado sobre el resultado,
#' como hace el lab con un artefacto sin receta.
dibujar <- function(clave, ajuste) {
  registro <- artefacto(clave)
  logica <- get(sub("^.*::", "", registro$logica))
  grafico <- get(sub("^.*::", "", registro$grafico))
  archivo <- tempfile(fileext = ".png")
  exportar_png(grafico(logica(ajuste)), archivo)
  file.exists(archivo) && file.size(archivo) > 1000
}
for (clave in c("f4.explicabilidad.modos", "f4.desempeno.cruce_clase",
                "f4.diagnostico.bic", "f4.diagnostico.silueta"))
  probar(sprintf("%s se dibuja a PNG desde el registro", clave),
         dibujar(clave, latente))
probar("el mapa 2D se dibuja con las etiquetas del ACM", {
  archivo <- tempfile(fileext = ".png")
  exportar_png(graficar_mapa_2d(coordenadas_2d(latente),
                                etiquetas_ejes(latente)[1:2]), archivo)
  file.size(archivo) > 1000
})
probar("bic_mezclas marca el k elegido y falla sin tabla de selección", {
  tabla <- bic_mezclas(latente)
  error <- tryCatch(bic_mezclas(por_tipo), error = conditionMessage)
  attr(tabla, "k_elegido") == 7L && grepl("seleccion", error)
})
probar("cada artefacto nuevo tiene su texto en textos/", all(vapply(
  c("f4.explicabilidad.modos", "f4.desempeno.cruce_clase",
    "f4.diagnostico.bic"), function(clave)
      file.exists(ruta_app(ruta_texto_de(clave))), logical(1))))

cat(sprintf("\n[test_cualitativo] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
