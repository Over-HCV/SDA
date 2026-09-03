# learn/R/pruebas/test_informe.R
#
# Responsabilidad: probar el cuaderno exportable de la fase 1.
#
# Uso:  Rscript learn/R/pruebas/test_informe.R
#
# Vive aparte de test_headless.R por C2: aquel prueba el núcleo (registro,
# objetos, contratos, exportadores) y este prueba una pieza sola —la selección
# de paneles convertida en .Rmd— que tiene su propia lógica de armado y su
# propio catálogo de generadores de código R.
#
# Es headless a propósito: `CASILLAS_INFORME` y `codigo_artefacto()` viven en
# nucleo/ justamente para que el contrato de qué se puede exportar se pueda
# comprobar sin levantar Shiny.

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

cat("\n[cuaderno de exploración]\n")
# El dataset y la selección tal como los arma la pestaña Informe: dos paneles
# marcados sobre unos datos ya filtrados a mediodía.
ds_cuaderno <- list(
  nombre = "ori", fuente = "ori", n = 118L, p = 18L,
  transformaciones = list(
    list(tipo = "filtro", columnas = "Hora", params = list(valores = "12:00")),
    list(tipo = "estandarizar", columnas = "Temperatura", params = list())))
seleccion_cuaderno <- list(
  list(clave = "f1.analisis.boxplot", titulo = "Caja y bigotes",
       cuando = "12:00:00", params = list(variable = "Temperatura"),
       tabla = NULL),
  list(clave = "f1.analisis.dispersion", titulo = "Dispersion",
       cuando = "12:01:00",
       params = list(x = "Temperatura", y = "Velocidad_del_Viento",
                     marginales = TRUE),
       tabla = NULL))
cuaderno <- armar_informe_exploracion(seleccion_cuaderno, ds_cuaderno)

probar("el cuaderno abre con el YAML de R Markdown",
       cuaderno[1] == "---" && any(grepl("output:", cuaderno, fixed = TRUE)))
probar("la fuente ori se recarga desde el CSV original, no desde el exportado",
       any(grepl('read.csv("ORI.csv"', cuaderno, fixed = TRUE)) &&
         any(grepl('fileEncoding = "latin1"', cuaderno, fixed = TRUE)))
probar("el filtro viaja como codigo R ejecutable", {
  linea <- 'datos <- datos[datos$Hora %in% c("12:00"), ]'
  any(grepl(linea, cuaderno, fixed = TRUE))
})
probar("las transformaciones de la pila tambien viajan",
       any(grepl("datos$Temperatura <- datos$Temperatura - mean(", cuaderno,
                 fixed = TRUE)))
probar("hay una seccion por panel marcado, con su clave",
       sum(grepl("^## ", cuaderno)) == 2L &&
         any(grepl("# f1.analisis.dispersion", cuaderno, fixed = TRUE)))
probar("el pie dice cuantos paneles y en que modo se genero",
       any(grepl("2 paneles", cuaderno, fixed = TRUE)))
probar("un cuaderno sin dataset no falla, lo dice", {
  vacio <- armar_informe_exploracion(list(), NULL)
  any(grepl("sin dataset cargado", vacio, fixed = TRUE))
})
probar("toda clave con casilla tiene generador de codigo R", {
  sin_generador <- Filter(function(clave) {
    lineas <- codigo_artefacto(clave, list(variable = "x", x = "x", y = "y",
                                           columna = "x", clase = "g",
                                           variables = c("x", "y"),
                                           a = "g", b = "h"))
    length(lineas) < 2L || any(grepl("Sin generador autonomo", lineas))
  }, CASILLAS_INFORME)
  length(sin_generador) == 0L
})
probar("el codigo de cada panel es R VALIDO, no solo texto", {
  # La prueba que faltaba. `geom_density +` (sin parentesis) se armaba sin
  # quejarse y solo reventaba al knitear el cuaderno, en la maquina de quien
  # respondia el taller. parse() lo caza acá.
  plausibles <- list(variable = "x", columna = "x", clase = "g", grupo = "g",
                     x = "x", y = "y", a = "g", b = "h",
                     variables = c("x", "y"), normal = TRUE, densidad = TRUE,
                     marginales = TRUE, clases = 20L, ancho = 0.5,
                     metodo = "iqr", umbral = 1.5, nivel = 0.95)
  rotas <- Filter(function(clave) {
    codigo <- paste(codigo_artefacto(clave, plausibles), collapse = "\n")
    inherits(try(parse(text = codigo), silent = TRUE), "try-error")
  }, CASILLAS_INFORME)
  length(rotas) == 0L
})
probar("sin ancho de banda la densidad igual lleva parentesis",
       any(grepl("geom_density() +", codigo_artefacto(
         "f1.analisis.densidad", list(variable = "x")), fixed = TRUE)))
probar("un panel sin sus parametros dice que falta, y no emite R roto", {
  lineas <- codigo_artefacto("f1.analisis.boxplot", list())
  # Antes desaparecia la linea del ggplot() y quedaba un `+` huerfano.
  all(grepl("^#", lineas)) &&
    any(grepl("Falta indicar: variable", lineas, fixed = TRUE))
})
probar("params_completos distingue lo que cada generador necesita",
       params_completos("f1.analisis.dispersion", list(x = "a", y = "b")) &&
         !params_completos("f1.analisis.dispersion", list(x = "a")) &&
         params_completos("f1.fuente.vista_previa", list()))

probar("una clave desconocida cae en el generico y no en un error", {
  lineas <- codigo_artefacto("f9.inventada.nada", list(k = 1))
  any(grepl("Sin generador", lineas))
})

# ---------------------------------------------------------------------------
cat("\n[lab.R · el laboratorio por consola]\n")
# lab.R no se sourcea con cargar_sda(): es un ejecutable, no una capa. Se carga
# acá a mano y se le llama a las funciones, sin pasar por commandArgs().
source("learn/R/lab.R")

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
  lineas <- COMANDOS$cuaderno(ds_cli, "f1.analisis.boxplot")
  any(grepl('read.csv("ORI.csv"', lineas, fixed = TRUE)) &&
    !any(grepl("datos-sda-lab.csv", lineas, fixed = TRUE))
})

cat(sprintf("\n[test_informe] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
