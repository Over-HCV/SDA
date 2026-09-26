# learn/R/pruebas/test_lab.R
#
# Responsabilidad: probar learn/R/lab.R, el laboratorio por consola.
#
# Uso:  Rscript learn/R/pruebas/test_lab.R
#
# Vive aparte de test_informe.R por C2: el cuaderno de exploración (núcleo) y
# la consola que lo arma son dos ejes, y juntos pasaban el techo de 300 LOC.
#
# lab.R no se sourcea con cargar_sda(): es un ejecutable, no una capa. Se carga
# acá a mano y se le llama a las funciones, sin pasar por commandArgs().

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)
source("learn/R/lab.R")

.FALLOS <- 0L

probar <- function(descripcion, expresion) {
  resultado <- tryCatch(isTRUE(expresion), error = function(e) {
    cat("    error:", conditionMessage(e), "\n"); FALSE })
  if (!resultado) .FALLOS <<- .FALLOS + 1L
  cat(sprintf("  %s %s\n", if (resultado) "ok  " else "FALLA", descripcion))
  invisible(resultado)
}

cat("\n[lab.R · argumentos y dataset]\n")
probar("las opciones se separan de los posicionales", {
  partido <- partir_argumentos(c("resumen", "Temperatura", "--fuente", "ori"))
  identical(partido$posicionales, c("resumen", "Temperatura")) &&
    identical(partido$opciones$fuente, "ori")
})
probar("--filtro se puede repetir y se acumula en orden", {
  partido <- partir_argumentos(c("datos", "--filtro", "Hora=12:00",
                                 "--filtro", "Region=ORI"))
  identical(partido$opciones$filtro, c("Hora=12:00", "Region=ORI"))
})
probar("un filtro mal escrito falla con la forma correcta en el mensaje", {
  error <- tryCatch(aplicar_filtro_cli(list(), "Hora"), error = function(e) e)
  grepl("Columna=valor", conditionMessage(error), fixed = TRUE)
})
probar("sin --fuente se niega a adivinar, y dice cuales hay", {
  # Un default acá salia caro: exportar el cuaderno sin fuente producia en
  # silencio un analisis del dataset equivocado.
  error <- tryCatch(armar_dataset(list()), error = function(e) e)
  grepl("falta --fuente", conditionMessage(error), fixed = TRUE) &&
    grepl("ori", conditionMessage(error), fixed = TRUE)
})

ds_cli <- armar_dataset(list(fuente = "ori", filtro = "Hora=12:00"))
probar("armar_dataset carga la fuente y aplica el filtro", {
  ds_cli$n == 118L && ds_cli$p == 18L &&
    identical(ds_cli$transformaciones[[1]]$tipo, "filtro")
})
probar("el dataset de consola es el mismo objeto que usa la app",
       all(c("df", "diccionario", "transformaciones", "n", "p") %in%
             names(ds_cli)))

cat("\n[lab.R · paneles como tablas]\n")
probar("un panel se devuelve como la tabla de lo que dibujaría", {
  capas <- tabla_de_panel(ds_cli, "f1.analisis.histograma", "Temperatura")
  # Una fila por barra, con su intervalo y su altura: es lo que uno lee del
  # histograma, sin necesidad de verlo.
  all(c("count", "xmin", "xmax", "density") %in% names(capas[[1]])) &&
    sum(capas[[1]]$count) == 118L
})
probar("la caja se devuelve con sus cinco numeros", {
  capas <- tabla_de_panel(ds_cli, "f1.analisis.boxplot", "Velocidad_del_Viento")
  caja <- capas[[1]]
  caja$middle == stats::median(ds_cli$df$Velocidad_del_Viento) &&
    all(c("ymin", "lower", "upper", "ymax") %in% names(caja))
})
probar("una clave inexistente lo dice y sugiere donde mirar", {
  error <- tryCatch(tabla_de_panel(ds_cli, "f9.no.existe", character(0)),
                    error = function(e) e)
  grepl("clave desconocida", conditionMessage(error), fixed = TRUE)
})
probar("los atipicos por consola son los mismos que los del panel", {
  marcadas <- COMANDOS$atipicos(ds_cli, c("Presion"))
  nrow(marcadas) == 1L && marcadas$valor == 1015.7
})
probar("un posicional omitido no llega como NA a la logica", {
  # `args[2]` es NA cuando falta, y `%||%` solo atrapa NULL: por eso .arg().
  identical(.arg(character(0), 2L, "iqr"), "iqr") &&
    identical(.arg(c("Presion"), 2L, "iqr"), "iqr")
})
probar("el codigo de cada panel CORRE sobre los datos, no solo parsea", {
  # La prueba de sintaxis vive en test_informe.R; esta caza lo otro: una
  # funcion mal escrita, una columna que no existe, un paquete que el cuaderno
  # declara y la maquina no tiene. Es lo que separa "se armo" de "se entrega".
  suppressPackageStartupMessages(library(ggplot2))
  plausibles <- list(variable = "Temperatura", columna = "Presion",
                     clase = "Pronostico", grupo = "Departamento",
                     escala = "razon", x = "Temperatura",
                     y = "Velocidad_del_Viento", a = "Departamento",
                     b = "Pronostico",
                     variables = c("Temperatura", "Presion", "Humedad"),
                     normal = TRUE, densidad = TRUE, marginales = TRUE,
                     suavizado = TRUE, regresion = TRUE,
                     clases = 20L, umbral = 1.5, nivel = 0.95)
  # `metodo` significa cosas distintas segun el panel (iqr/z en Calidad,
  # pearson/spearman en el mapa de calor), asi que va por clave y no en el
  # monton comun.
  metodo_de <- c("f1.calidad.atipicos" = "iqr",
                 "f1.analisis.heatmap_correlacion" = "pearson")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  rotas <- Filter(function(clave) {
    entorno <- new.env(parent = globalenv())
    assign("datos", ds_cli$df, envir = entorno)
    # Lo define el chunk de carga del cuaderno; el panel del filtro lo lee.
    assign("filas_al_cargar", ds_cli$n_crudo %||% nrow(ds_cli$df), envir = entorno)
    params <- c(plausibles, if (clave %in% names(metodo_de))
      list(metodo = metodo_de[[clave]]) else NULL)
    codigo <- codigo_artefacto(clave, params,
                               tabla_de_seleccion(clave, params, ds_cli))
    salida <- try(suppressWarnings(
      for (expresion in parse(text = paste(codigo, collapse = "\n"))) {
        valor <- eval(expresion, envir = entorno)
        if (inherits(valor, c("ggplot", "ggExtraPlot"))) print(valor)
      }), silent = TRUE)
    if (inherits(salida, "try-error"))
      cat("    ", clave, ":", conditionMessage(attr(salida, "condition")), "\n")
    inherits(salida, "try-error")
  }, CASILLAS_INFORME)
  length(rotas) == 0L
})

cat("\n[lab.R · pedidos y cuadernos]\n")
probar("un pedido lleva columnas y opciones con nombre", {
  entrada <- entrada_de_pedido(
    "f1.analisis.dispersion:Temperatura+Velocidad_del_Viento+marginales=TRUE",
    ds_cli)
  identical(entrada$params$x, "Temperatura") &&
    identical(entrada$params$y, "Velocidad_del_Viento") &&
    isTRUE(entrada$params$marginales)
})
probar("un campo plural se lleva todas las columnas", {
  entrada <- entrada_de_pedido("f1.analisis.heatmap_correlacion:a+b+c", ds_cli)
  identical(entrada$params$variables, c("a", "b", "c"))
})
probar("el titulo de la seccion distingue paneles repetidos", {
  lineas <- COMANDOS$cuaderno(
    ds_cli, "f1.analisis.densidad:Temperatura,f1.analisis.densidad:Presion")
  any(grepl("## Densidad kernel · Temperatura", lineas, fixed = TRUE)) &&
    any(grepl("## Densidad kernel · Presion", lineas, fixed = TRUE))
})
probar("el cuaderno tambien se arma desde la consola", {
  lineas <- COMANDOS$cuaderno(ds_cli, "f1.analisis.boxplot")
  any(grepl("# f1.analisis.boxplot", lineas, fixed = TRUE))
})
probar("el cuaderno del taller cita ORI.csv y no el CSV exportado", {
  lineas <- COMANDOS$cuaderno(ds_cli, "f1.analisis.boxplot:Temperatura")
  any(grepl('"ORI.csv", "data/ORI.csv"', lineas, fixed = TRUE)) &&
    !any(grepl("datos-sda-lab.csv", lineas, fixed = TRUE))
})

cat("\n[cuaderno desde una sesion]\n")
# Guardar y abrir sesiones se prueba en test_sesion.R; acá solo que el
# cuaderno se arma desde una.
ds_sesion <- ds_cli
ds_sesion$diccionario$escala[ds_sesion$diccionario$columna == "Temperatura"] <-
  "intervalo"
seleccion_sesion <- list(
  list(id = "p1", clave = "f1.analisis.resumen", titulo = "Resumen numérico",
       cuando = "12:00:00",
       params = list(variable = "Temperatura", escala = "intervalo"),
       nota = "La media queda debajo de la mediana."),
  list(id = "p2", clave = "f1.diccionario.tabla", titulo = "Diccionario",
       cuando = "12:01:00", params = list(), tabla = NULL))
archivo_sesion <- tempfile(fileext = ".json")
exportar_sesion_json(sesion_actual(nuevo_almacen(), ds_sesion, seleccion_sesion),
                     archivo_sesion)

probar("el cuaderno se arma desde la sesion, sin listar claves", {
  lineas <- COMANDOS$cuaderno(ds_sesion, character(0),
                              list(sesion = archivo_sesion))
  any(grepl("## Resumen numérico · Temperatura", lineas, fixed = TRUE)) &&
    any(grepl("La media queda debajo de la mediana.", lineas, fixed = TRUE))
})
probar("el resumen de una variable de intervalo trae summary() y la asimetria", {
  codigo <- codigo_artefacto("f1.analisis.resumen",
                             list(variable = "Temperatura", escala = "intervalo"))
  any(grepl("print(summary(x))", codigo, fixed = TRUE)) &&
    any(grepl("asimetria <- ", codigo, fixed = TRUE))
})
probar("el de una nominal no calcula una media que no existe", {
  codigo <- codigo_artefacto("f1.analisis.resumen",
                             list(variable = "Pronostico", escala = "nominal"))
  any(grepl("Moda:", codigo, fixed = TRUE)) &&
    !any(grepl("summary(x)", codigo, fixed = TRUE))
})
probar("los atipicos se piden con el criterio que pide el enunciado", {
  # `boxplot(x, plot = FALSE)$out`: bisagras de Tukey, no quantile(type = 7).
  # Sin umbral elegido va el 1.5 de Tukey, escrito para que se vea.
  codigo <- codigo_artefacto("f1.calidad.atipicos", list(columna = "Presion"))
  any(grepl("boxplot(x, range = 1.5, plot = FALSE)", codigo, fixed = TRUE))
})
probar("el diccionario declarado viaja dentro del chunk", {
  tabla <- ds_sesion$diccionario[, c("columna", "escala", "clase", "rol")]
  codigo <- codigo_artefacto("f1.diccionario.tabla", list(), tabla)
  any(grepl("diccionario <- data.frame(", codigo, fixed = TRUE)) &&
    any(grepl("intervalo", paste(codigo, collapse = " "), fixed = TRUE))
})

cat(sprintf("\n[test_lab] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
