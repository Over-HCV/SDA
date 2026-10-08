# learn/R/pruebas/test_informe_f4.R
#
# Responsabilidad: probar que el código R que el cuaderno emite para los
# paneles de la fase 4 (ACP, k-medias, jerárquico) CORRE, no solo que se
# arma.
#
# Uso:  Rscript learn/R/pruebas/test_informe_f4.R
#
# Vive aparte de test_informe.R por C2. Y prueba distinto: aquel parsea, este
# ejecuta cada chunk contra la base del Taller 02 (data/EIA.csv) leída como la
# lee el cuaderno, con el filtro de exclusión ya aplicado. Un fviz_* con un
# argumento mal escrito parsea perfecto y revienta recién al knitear.

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)
# Lo que carga el chunk de configuración del cuaderno.
library(ggplot2)
library(factoextra)
library(cluster)

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", conditionMessage(e), "\n"); FALSE })
  if (!resultado) .FALLOS <<- .FALLOS + 1L
  cat(sprintf("  %s %s\n", if (resultado) "ok  " else "FALLA", descripcion))
  invisible(resultado)
}

ATIPICOS <- c("UnitedStates", "China", "SaudiArabia", "Russia")

#' Los datos como quedan en el cuaderno tras "Los datos" y "Preparación".
datos_cuaderno <- function(excluir = ATIPICOS) {
  datos <- read.csv(ruta_repo("data", "EIA.csv"), sep = ";",
                    stringsAsFactors = FALSE)
  datos[!datos$Country %in% excluir, ]
}

#' Corre las líneas como un chunk: en `entorno` (el cuaderno), imprimiendo
#' cada valor visible como hace knitr, que es donde un ggplot se evalúa.
correr_chunk <- function(lineas, entorno) {
  archivo <- tempfile(fileext = ".R")
  writeLines(lineas, archivo)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  salida <- utils::capture.output(
    source(archivo, local = entorno, print.eval = TRUE))
  invisible(salida)
}

nuevo_cuaderno <- function(excluir = ATIPICOS) {
  entorno <- new.env(parent = globalenv())
  assign("datos", datos_cuaderno(excluir), envir = entorno)
  entorno
}

ACP_NORMADO <- list(metodo = "acp",
                    hiper = list(n_componentes = 3L, matriz = "correlacion"),
                    ejes = c(1L, 2L), top = 30L)
ACP_CRUDO <- modifyList(ACP_NORMADO, list(hiper = list(matriz = "covarianza")))
KMEANS <- list(metodo = "kmeans",
               hiper = list(k = 3L, escalar = TRUE, reinicios = 25L))
JERARQUICO <- list(metodo = "jerarquico",
                   hiper = list(enlace = "average", distancia = "euclidean",
                                k_corte = 3L))

CASOS <- list(
  "f4.diagnostico.scree" = ACP_NORMADO,
  "f4.diagnostico.reglas_k" = ACP_NORMADO,
  "f4.explicabilidad.contribuciones" = ACP_CRUDO,
  "f4.explicabilidad.circulo_correlaciones" =
    modifyList(ACP_NORMADO, list(ejes = c(2L, 3L))),
  "f4.explicabilidad.mapa_2d" = modifyList(ACP_NORMADO,
                                           list(grupos = KMEANS)),
  "f4.explicabilidad.cargas" = ACP_NORMADO,
  "f4.explicabilidad.calidad" = ACP_NORMADO,
  "f4.diagnostico.codo" = KMEANS,
  "f4.diagnostico.silueta" = JERARQUICO,
  "f4.explicabilidad.centroides" = KMEANS,
  "f4.desempeno.grupos" = modifyList(KMEANS, list(grupos = JERARQUICO)),
  "f4.diagnostico.dendrograma" = JERARQUICO)

cat("\n[cuaderno · fase 4, cada chunk solo]\n")
for (clave in names(CASOS)) {
  codigo <- codigo_artefacto(clave, CASOS[[clave]])
  probar(sprintf("%s corre solo sobre EIA", clave), {
    correr_chunk(codigo, nuevo_cuaderno())
    identical(codigo[1], paste("#", clave)) &&
      !any(grepl("Sin generador", codigo, fixed = TRUE))
  })
  largas <- codigo[nchar(codigo) > 68L]
  probar(sprintf("%s cabe en 68 columnas", clave), {
    if (length(largas)) cat("    ", largas, sep = "\n    ")
    length(largas) == 0L
  })
}

cat("\n[cuaderno · fase 4, la misma sesión]\n")
probar("los mapas de k-medias y del jerárquico también corren", {
  cuaderno <- nuevo_cuaderno()
  correr_chunk(codigo_artefacto("f4.explicabilidad.mapa_2d", KMEANS), cuaderno)
  correr_chunk(codigo_artefacto("f4.explicabilidad.mapa_2d", JERARQUICO),
               cuaderno)
  exists("km3", envir = cuaderno) && exists("hc_average", envir = cuaderno)
})
probar("el codo del jerárquico corre y la varianza explicada arranca en 0", {
  cuaderno <- nuevo_cuaderno()
  correr_chunk(codigo_artefacto("f4.diagnostico.codo", JERARQUICO), cuaderno)
  codo <- get("codo", envir = cuaderno)
  codo$explicada[1] == 0 && codo$explicada[10] > 50
})
probar("normado y crudo son dos objetos, no uno pisado", {
  cuaderno <- nuevo_cuaderno()
  correr_chunk(codigo_artefacto("f4.diagnostico.scree", ACP_NORMADO), cuaderno)
  correr_chunk(codigo_artefacto("f4.diagnostico.scree", ACP_CRUDO), cuaderno)
  isTRUE(get("acp_normado", envir = cuaderno)$scale[1] != FALSE) &&
    isFALSE(get("acp_crudo", envir = cuaderno)$scale)
})
probar("el ajuste se reutiliza entre chunks y se rehace si cambian las filas", {
  cuaderno <- nuevo_cuaderno(excluir = character(0))
  correr_chunk(codigo_artefacto("f4.diagnostico.scree", ACP_NORMADO), cuaderno)
  completo <- nrow(get("acp_normado", envir = cuaderno)$x)
  # La pregunta 7: el mismo cuaderno, ahora sin los cuatro atípicos.
  evalq(datos <- datos[!datos$Country %in% c("UnitedStates", "China",
                                              "SaudiArabia", "Russia"), ],
        cuaderno)
  correr_chunk(codigo_artefacto("f4.explicabilidad.cargas", ACP_NORMADO),
               cuaderno)
  completo == 111L && nrow(get("acp_normado", envir = cuaderno)$x) == 107L
})
probar("los grupos quedan en datos y las cajas por grupo los usan", {
  cuaderno <- nuevo_cuaderno()
  correr_chunk(codigo_artefacto("f4.desempeno.grupos",
                                modifyList(KMEANS, list(grupos = KMEANS))),
               cuaderno)
  correr_chunk(codigo_artefacto("f1.analisis.boxplot_grupos",
                                list(variable = "Jet_fuel_consumption_TBPD",
                                     grupo = "grupo")), cuaderno)
  grupo <- get("datos", envir = cuaderno)$grupo
  is.factor(grupo) && nlevels(grupo) == 3L && !anyNA(grupo)
})
probar("con grupos del mismo método, el ajuste no se repite en el chunk", {
  codigo <- codigo_artefacto("f4.desempeno.grupos",
                             modifyList(KMEANS, list(grupos = KMEANS)))
  sum(grepl("km3 <- kmeans(", codigo, fixed = TRUE)) == 1L &&
    sum(grepl("datos$grupo <-", codigo, fixed = TRUE)) == 1L
})
probar("los países rotulan las filas, no números", {
  cuaderno <- nuevo_cuaderno()
  correr_chunk(codigo_artefacto("f4.diagnostico.reglas_k", ACP_NORMADO),
               cuaderno)
  "Colombia" %in% rownames(get("acp_normado", envir = cuaderno)$x)
})

cat("\n[cuaderno · fase 4, bordes]\n")
probar("un panel de grupos pedido para el ACP dice que no aplica", {
  lineas <- codigo_artefacto("f4.diagnostico.silueta", ACP_NORMADO)
  all(grepl("^#", lineas)) && any(grepl("no se dibuja", lineas))
})
probar("sin metodo, el panel dice que falta", {
  lineas <- codigo_artefacto("f4.diagnostico.scree", list())
  any(grepl("Falta indicar: metodo", lineas, fixed = TRUE))
})
probar("una f4 sin generador sigue cayendo en el generico",
       any(grepl("Sin generador", codigo_artefacto(
         "f4.desempeno.roc", list(metodo = "logistica")), fixed = TRUE)))
probar("el chunk de configuracion carga factoextra y cluster", {
  seleccion <- lapply(c("f4.diagnostico.silueta", "f4.diagnostico.scree"),
                      function(clave) list(clave = clave,
                                           params = CASOS[[clave]]))
  paquetes <- .paquetes_de(seleccion)
  identical(paquetes, c("ggplot2", "factoextra", "cluster"))
})
probar("sin paneles de factoextra, no se carga factoextra",
       identical(.paquetes_de(list(list(clave = "f4.diagnostico.codo",
                                        params = KMEANS))), "ggplot2"))

cat(sprintf("\n[test_informe_f4] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
