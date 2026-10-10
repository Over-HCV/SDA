# learn/R/pruebas/test_informe_cualitativo.R
#
# Responsabilidad: probar que el cuaderno reproduce k-modas, Gower y clases
# latentes del lab: que sus chunks CORREN solos y que la partición y el
# objetivo que calculan son los del lab, no unos parecidos.
#
# Uso:  Rscript learn/R/pruebas/test_informe_cualitativo.R
#
# El patrón es el de test_lab_cualitativo.R: los paneles se piden como por
# consola (Zoo, k = 7, --clase tipo), sus chunks se ejecutan contra
# data/zoo.csv leída como la lee el cuaderno (texto, sin factores) y lo que
# queda en el entorno se compara con el ajuste del lab por el mismo camino
# que `lab.R metodo`. Sin esto, un cuaderno que "se parece" al lab pasaría.

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)
source("learn/R/lab.R")
suppressPackageStartupMessages({
  library(ggplot2)
  library(factoextra)
  library(cluster)
})

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", conditionMessage(e), "\n"); FALSE })
  if (!resultado) .FALLOS <<- .FALLOS + 1L
  cat(sprintf("  %s %s\n", if (resultado) "ok  " else "FALLA", descripcion))
  invisible(resultado)
}

#' Corre las líneas como un chunk de knitr, en `entorno`.
correr_chunk <- function(lineas, entorno) {
  archivo <- tempfile(fileext = ".R")
  writeLines(lineas, archivo)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  utils::capture.output(source(archivo, local = entorno, print.eval = TRUE))
}

nuevo_cuaderno <- function() {
  entorno <- new.env(parent = globalenv())
  entorno$datos <- utils::read.csv(ruta_repo("data", "zoo.csv"),
                                   stringsAsFactors = FALSE)
  entorno
}

ZOO <- c("--fuente", "zoo", "--clase", "tipo", "--hiper", "k=7")

# metodo, hiper extra (tokens del panel y de --hiper), objeto del cuaderno
CASOS <- list(
  kmodos = list(metodo = "kmodos", tokens = character(0),
                objeto = "kmodas7"),
  gower_pam = list(metodo = "gower", tokens = character(0),
                   objeto = "gower_pam7"),
  gower_arbol = list(metodo = "gower",
                     tokens = c("estrategia=jerarquico", "enlace=average"),
                     objeto = "gower_average7"),
  clases_latentes = list(metodo = "clases_latentes",
                         tokens = character(0), objeto = "clases7"))

for (nombre in names(CASOS)) {
  caso <- CASOS[[nombre]]
  cat(sprintf("\n[%s · los paneles del cuaderno]\n", nombre))
  extra <- unlist(lapply(caso$tokens, function(t) c("--hiper", t)))
  opciones <- partir_argumentos(c(ZOO, extra))$opciones
  opciones$metodo <- caso$metodo
  ds <- suppressMessages(armar_dataset(opciones))
  lab <- ajustar_cli(ds, caso$metodo, opciones)$ajuste

  claves <- intersect(metodo(caso$metodo)$artefactos,
                      names(.GENERADORES_CUALITATIVOS))
  pedido <- paste(sprintf("%s:%s", claves,
                          paste(c(paste0("metodo=", caso$metodo),
                                  caso$tokens), collapse = "+")),
                  collapse = ",")
  seleccion <- suppressMessages(seleccion_de_args(ds, pedido, opciones))
  probar("las entradas llevan columnas, semilla y reinicios del lab", {
    p <- seleccion[[1]]$params
    identical(p$columnas, lab$columnas) && p$semilla == 42L &&
      p$reinicios == 25L
  })

  for (entrada in seleccion) {
    codigo <- codigo_artefacto(entrada$clave, entrada$params)
    probar(sprintf("%s corre solo", entrada$clave), {
      correr_chunk(codigo, nuevo_cuaderno())
      !any(grepl("Sin generador|no se dibuja", codigo))
    })
    largas <- codigo[nchar(codigo) > 68L]
    probar(sprintf("%s cabe en 68 columnas", entrada$clave), {
      if (length(largas)) cat("    ", largas, sep = "\n    ")
      length(largas) == 0L
    })
  }

  cuaderno <- nuevo_cuaderno()
  correr_chunk(codigo_artefacto(seleccion[[1]]$clave,
                                seleccion[[1]]$params), cuaderno)
  ajuste <- get(caso$objeto, envir = cuaderno)
  probar("la partición del cuaderno es la del lab, con la misma numeración", {
    identical(unname(as.integer(ajuste$grupos)), as.integer(lab$grupos)) &&
      identical(names(ajuste$grupos), rownames(lab$x))
  })
  probar("ARI(cuaderno, lab) = 1",
         abs(indice_rand_ajustado(ajuste$grupos, lab$grupos) - 1) < 1e-12)
  if (identical(caso$metodo, "kmodos"))
    probar("el costo es el del lab", ajuste$costo == lab$costo)
  if (identical(caso$metodo, "gower") && is.null(lab$arbol))
    probar("el objetivo de PAM y los medoides son los del lab",
           abs(ajuste$objetivo - lab$objetivo) < 1e-12 &&
             identical(ajuste$medoides, rownames(lab$x)[lab$medoides]))
  if (identical(caso$metodo, "gower") && !is.null(lab$arbol))
    probar("las alturas del árbol son las del lab",
           max(abs(ajuste$arbol$height - lab$arbol$height)) < 1e-12)
  if (identical(caso$metodo, "clases_latentes")) {
    probar("la log-verosimilitud es la del lab",
           abs(ajuste$ll - lab$log_verosimilitud) < 1e-6)
    probar("la tabla de BIC por k es la del lab", {
      max(abs(ajuste$seleccion$bic - lab$seleccion$bic)) < 1e-6 &&
        identical(ajuste$seleccion$k, lab$seleccion$k)
    })
  }
  if ("f4.diagnostico.codo" %in% claves)
    probar("el codo del cuaderno da los costos de inercia_por_k() del lab", {
      entrada <- Filter(function(e) e$clave == "f4.diagnostico.codo",
                        seleccion)[[1]]
      correr_chunk(codigo_artefacto(entrada$clave, entrada$params),
                   cuaderno)
      lab_codo <- inercia_por_k(lab, 10L)
      max(abs(get("costos", envir = cuaderno) - lab_codo$inercia)) < 1e-9
    })
  probar("el cruce imprime el ARI del lab", {
    entrada <- Filter(function(e) e$clave == "f4.desempeno.cruce_clase",
                      seleccion)[[1]]
    salida <- correr_chunk(codigo_artefacto(entrada$clave, entrada$params),
                           cuaderno)
    linea <- grep("^ARI =", salida, value = TRUE)
    ari <- as.numeric(sub("^ARI = ([0-9.-]+).*$", "\\1", linea))
    abs(ari - round(metricas_de_corrida(lab)$ari, 3)) < 1e-9
  })

  probar("el cuaderno entero corre en orden, con el método escrito una vez", {
    lineas <- armar_informe_exploracion(seleccion, ds)
    inicios <- grep("^```\\{r", lineas)
    fines <- grep("^```$", lineas)
    entorno <- nuevo_cuaderno()
    for (i in inicios[-1]) {  # el primero es la configuración
      fin <- fines[fines > i][1]
      if (i + 1L <= fin - 1L &&
          !grepl("cargar-datos", lineas[i]))
        correr_chunk(lineas[(i + 1L):(fin - 1L)], entorno)
    }
    definicion <- switch(caso$metodo, kmodos = "^kmodas <- function",
                         gower = "^agrupar_gower <- function",
                         clases_latentes = "^clases_latentes <- function")
    sum(grepl(definicion, lineas)) == 1L &&
      exists(caso$objeto, envir = entorno)
  })
}

cat("\n[cuaderno · bordes]\n")
probar("el dendrograma pedido para PAM dice que no hay árbol", {
  lineas <- codigo_artefacto("f4.diagnostico.dendrograma",
                             list(metodo = "gower",
                                  hiper = list(k = 3L, estrategia = "pam")))
  all(grepl("^#", lineas)) && any(grepl("no construye", lineas))
})
probar("un panel que el método no declara sigue diciendo que no aplica", {
  lineas <- codigo_artefacto("f4.explicabilidad.centroides",
                             list(metodo = "kmodos", hiper = list(k = 3L)))
  any(grepl("no se dibuja|Sin generador", lineas))
})
probar("el chunk de configuración carga cluster para Gower y la silueta", {
  seleccion <- list(
    list(clave = "f4.desempeno.grupos",
         params = list(metodo = "gower", hiper = list(k = 3L))),
    list(clave = "f4.diagnostico.silueta",
         params = list(metodo = "kmodos", hiper = list(k = 3L))))
  identical(.paquetes_de(seleccion), c("ggplot2", "cluster", "factoextra"))
})
probar("el ACM del cuaderno: plano y scree corren sobre Zoo", {
  p <- list(metodo = "acm", hiper = list(n_componentes = 2L),
            clase = "tipo")
  cuaderno <- nuevo_cuaderno()
  correr_chunk(codigo_artefacto("f4.explicabilidad.mapa_2d", p), cuaderno)
  correr_chunk(codigo_artefacto("f4.diagnostico.scree", p), cuaderno)
  ds <- suppressMessages(armar_dataset(list(fuente = "zoo", clase = "tipo")))
  lab <- ajustar_acm(ds$df, columnas_de_entrada(ds, "acm"), 2L)
  acm <- get("acm", envir = cuaderno)
  max(abs(abs(acm$filas[, 1:2]) - abs(lab$puntuaciones))) < 1e-10
})
probar("la sesión conserva los paneles de la fase 3",
       length(seleccion_de_sesion(list(seleccion = list(
         list(clave = "f3.analisis.convergencia",
              params = list(metodo = "kmodos")))))) == 1L)

cat(sprintf("\n[test_informe_cualitativo] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
