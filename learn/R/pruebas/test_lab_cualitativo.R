# learn/R/pruebas/test_lab_cualitativo.R
#
# Responsabilidad: probar por consola el flujo del proyecto final sobre Zoo:
# la clase de referencia (`--clase`) y el tándem ACM + k-medias
# (`--reduccion acm` + `--grupos`/`--metodo kmeans`), hasta el cuaderno.
#
# Uso:  Rscript learn/R/pruebas/test_lab_cualitativo.R
#
# Vive aparte de test_lab.R por C2. Igual que test_informe_f4.R, el cuaderno
# no solo se arma: sus chunks se EJECUTAN contra data/zoo.csv leída como la lee
# el cuaderno (texto, sin factores), y el ACM escrito a mano tiene que dar las
# mismas coordenadas que el del lab.

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)
source("learn/R/lab.R")
library(factoextra)

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", conditionMessage(e), "\n"); FALSE })
  if (!resultado) .FALLOS <<- .FALLOS + 1L
  cat(sprintf("  %s %s\n", if (resultado) "ok  " else "FALLA", descripcion))
  invisible(resultado)
}

TANDEM <- c("--fuente", "zoo", "--clase", "tipo", "--reduccion", "acm",
            "--hiper", "n_componentes=5", "--hiper", "k=7",
            "--hiper", "escalar=FALSE")
opciones <- partir_argumentos(TANDEM)$opciones
opciones$metodo <- "kmeans"

cat("\n[--clase · la referencia no entra al ajuste]\n")
ds_clase <- armar_dataset(list(fuente = "zoo", clase = "tipo"))
probar("--clase declara el rol 'respuesta' en el diccionario",
       identical(columna_referencia(ds_clase), "tipo"))
probar("las columnas de entrada dejan afuera la clase y el identificador", {
  columnas <- columnas_de_entrada(ds_clase, "acm")
  length(columnas) == 16L && !any(c("tipo", "animal") %in% columnas)
})
probar("una columna de --clase inexistente falla diciendo cuál", {
  error <- tryCatch(armar_dataset(list(fuente = "zoo", clase = "tipa")),
                    error = conditionMessage)
  grepl("tipa", error)
})

cat("\n[--reduccion acm · las dimensiones como columnas]\n")
ds <- suppressMessages(armar_dataset(opciones))
probar("agrega Dim1..Dim5 numéricas y guarda la receta", {
  dims <- paste0("Dim", 1:5)
  all(dims %in% names(ds$df)) && all(vapply(ds$df[dims], is.numeric, TRUE)) &&
    identical(ds$reduccion$dimensiones, dims) &&
    !"tipo" %in% ds$reduccion$columnas
})
probar("son las puntuaciones del ACM de los 16 atributos", {
  acm <- ajustar_acm(ds$df, ds$reduccion$columnas, n_componentes = 5L)
  max(abs(as.matrix(ds$df[paste0("Dim", 1:5)]) - acm$puntuaciones)) < 1e-12
})

cat("\n[tándem · k-medias sobre las dimensiones]\n")
ajustado <- ajustar_cli(ds, "kmeans", opciones)
probar("sin --columnas, k-medias toma las dimensiones del ACM",
       identical(ajustado$ajuste$columnas, paste0("Dim", 1:5)) &&
         isFALSE(ajustado$parametros$escalar) && ajustado$ajuste$k == 7L)
probar("la clase viaja en el ajuste y el ARI entra a las métricas", {
  m <- metricas_de_corrida(ajustado$ajuste)
  length(ajustado$ajuste$referencia) == 101L && m$ari > 0.5
})
probar("`metodo kmeans` (posicional) también reconoce los hiper del tándem", {
  salida <- utils::capture.output(suppressMessages(
    correr_lab(c("metodo", "kmeans", TANDEM))))
  any(grepl("ari = 0\\.", salida))
})
probar("el panel del cruce sale como tabla, con el ARI en el subtítulo", {
  salida <- utils::capture.output(capas <- suppressMessages(
    tabla_de_panel(ds, "f4.desempeno.cruce_clase", character(0), opciones)))
  any(grepl("subtítulo: ARI = ", salida)) &&
    sum(as.numeric(capas[[2]]$label)) == 101L
})
probar("el mapa 2D del tándem se pinta por tipo con --color", {
  con_color <- c(opciones, list(color = "tipo"))
  capas <- suppressMessages(utils::capture.output(
    mapa <- tabla_de_panel(ds, "f4.explicabilidad.mapa_2d", character(0),
                           con_color)))
  nrow(mapa[[3]]) == 101L && "tipo" %in% names(mapa[[3]])
})

cat("\n[cuaderno · el tándem se reproduce fuera del lab]\n")
pedido <- paste0("f4.explicabilidad.mapa_2d:metodo=kmeans,",
                 "f4.desempeno.cruce_clase:metodo=kmeans")
seleccion <- suppressMessages(seleccion_de_args(ds, pedido, opciones))
probar("las entradas f4 llevan la receta del ACM y la clase",
       identical(seleccion[[2]]$params$reduccion$metodo, "acm") &&
         identical(seleccion[[2]]$params$clase, "tipo"))
lineas <- armar_informe_exploracion(seleccion, ds)
probar("el cuaderno trae el ACM a mano, el k-medias y el ARI", {
  texto <- paste(lineas, collapse = "\n")
  grepl("descomposicion <- svd(S)", texto, fixed = TRUE) &&
    grepl("kmeans(as.matrix(num), centers = 7", texto, fixed = TRUE) &&
    grepl("ari(grupos, clase)", texto, fixed = TRUE)
})

#' Corre las líneas como un chunk de knitr, en `entorno`.
correr_chunk <- function(lineas, entorno) {
  archivo <- tempfile(fileext = ".R")
  writeLines(lineas, archivo)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  utils::capture.output(source(archivo, local = entorno, print.eval = TRUE))
}
cuaderno <- new.env()
# Así llegan los datos al cuaderno: el CSV leído como texto, sin factores.
cuaderno$datos <- utils::read.csv(ruta_repo("data", "zoo.csv"),
                                  stringsAsFactors = FALSE)
salidas <- lapply(seleccion, function(entrada)
  tryCatch(correr_chunk(codigo_artefacto(entrada$clave, entrada$params),
                        cuaderno), error = function(e) e))
probar("los dos chunks corren sin error",
       !any(vapply(salidas, inherits, TRUE, "error")))
probar("el ACM del cuaderno da las mismas coordenadas que el del lab", {
  lab <- as.matrix(ds$df[paste0("Dim", 1:5)])
  max(abs(as.matrix(cuaderno$num) - lab)) < 1e-10
})
probar("el ARI del cuaderno se imprime y se parece al del lab", {
  linea <- grep("^ARI =", salidas[[2]], value = TRUE)
  ari <- as.numeric(sub("^ARI = ([0-9.-]+).*$", "\\1", linea))
  length(ari) == 1L &&
    abs(ari - metricas_de_corrida(ajustado$ajuste)$ari) < 0.15
})

cat(sprintf("\n[test_lab_cualitativo] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
