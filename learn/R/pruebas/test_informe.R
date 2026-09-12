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
       any(grepl('c("ORI.csv", "data/ORI.csv",', cuaderno, fixed = TRUE)) &&
         !any(grepl("datos-sda-lab.csv", cuaderno, fixed = TRUE)))
probar("la codificacion se detecta en vez de suponerse", {
  # Hardcodear latin1 rompia las tildes de los municipios sobre la copia UTF-8
  # del repo, y el cuaderno salia con ACACÃAS donde el panel decia ACACÍAS.
  any(grepl("validUTF8", cuaderno, fixed = TRUE)) &&
    !any(grepl('fileEncoding = "latin1"', cuaderno, fixed = TRUE))
})
probar("el cuaderno dice cuantas filas traia el archivo, no solo las filtradas", {
  # Pregunta 1 del taller: filas y columnas de la TABLA, con el filtro de
  # mediodia ya puesto. Sin esto el cuaderno solo sabia decir 118.
  any(grepl('cat("Al cargar:", nrow(datos)', cuaderno, fixed = TRUE))
})
probar("los paneles no cuelgan de la seccion Preparacion", {
  # Todos los paneles son `##`: sin un `#` propio, el indice los colgaba de
  # Preparacion, que es la ultima seccion de primer nivel antes de ellos.
  primer_panel <- which(grepl("^## ", cuaderno))[1]
  ultimo_titulo <- max(which(grepl("^# ", cuaderno[seq_len(primer_panel)])))
  identical(cuaderno[ultimo_titulo], "# Análisis")
})
probar("el filtro viaja como codigo R ejecutable", {
  linea <- 'datos <- datos[datos$Hora %in% c("12:00"), ]'
  any(grepl(linea, cuaderno, fixed = TRUE))
})
probar("las transformaciones de la pila tambien viajan",
       any(grepl("datos$Temperatura <- datos$Temperatura - mean(", cuaderno,
                 fixed = TRUE)))
probar("el texto de un panel repetido no se copia dos veces", {
  dos_densidades <- list(
    list(clave = "f1.analisis.densidad", titulo = "Densidad kernel",
         cuando = "12:00:00", params = list(variable = "Temperatura")),
    list(clave = "f1.analisis.densidad", titulo = "Densidad kernel",
         cuando = "12:01:00", params = list(variable = "Presion")))
  lineas <- armar_informe_exploracion(dos_densidades, ds_cuaderno)
  sum(grepl("^### Qué muestra", lineas)) == 1L &&
    any(grepl("está en la primera sección", lineas, fixed = TRUE))
})
probar("el texto se puede pedir breve o no pedirlo", {
  breve <- armar_informe_exploracion(seleccion_cuaderno, ds_cuaderno,
                                     texto = "breve")
  pelado <- armar_informe_exploracion(seleccion_cuaderno, ds_cuaderno,
                                      texto = "ninguno")
  !any(grepl("^### Para qué sirve", breve)) &&
    any(grepl("^### Cuándo engaña", breve)) &&
    length(pelado) < length(breve)
})
probar("la lectura escrita en la app reemplaza al recordatorio", {
  con_nota <- seleccion_cuaderno
  con_nota[[1]]$nota <- "La caja es asimétrica a la izquierda."
  lineas <- armar_informe_exploracion(con_nota, ds_cuaderno)
  any(grepl("La caja es asimétrica", lineas, fixed = TRUE)) &&
    sum(grepl("^> Interpretá acá", lineas)) == 1L
})
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
probar("el codigo de cada panel CORRE sobre los datos, no solo parsea", {
  # La prueba de arriba caza sintaxis; esta caza lo otro: una funcion mal
  # escrita, una columna que no existe, un paquete que el cuaderno declara y
  # la maquina no tiene. Es lo que separa "se armo" de "se puede entregar".
  suppressPackageStartupMessages(library(ggplot2))
  plausibles <- list(variable = "Temperatura", columna = "Presion",
                     clase = "Pronostico", grupo = "Departamento",
                     escala = "razon", x = "Temperatura",
                     y = "Velocidad_del_Viento", a = "Departamento",
                     b = "Pronostico",
                     variables = c("Temperatura", "Presion", "Humedad"),
                     normal = TRUE, densidad = TRUE, marginales = TRUE,
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

# ---------------------------------------------------------------------------
cat("\n[sesiones]\n")
# Una sesión es fuente + pila + diccionario + paneles marcados: lo que uno
# arma cada vez que abre la app y hasta ahora perdía al cerrar la pestaña.
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

probar("la sesion guarda la fuente, la pila y los paneles marcados", {
  leida <- importar_sesion_json(archivo_sesion)
  identical(leida$fase1$fuente, "ori") &&
    identical(leida$fase1$transformaciones[[1]]$tipo, "filtro") &&
    length(leida$fase1$seleccion) == 2L &&
    identical(leida$fase1$seleccion[[1]]$nota,
              "La media queda debajo de la mediana.")
})
probar("al abrirla, el dataset se reconstruye con el filtro puesto", {
  reconstruido <- dataset_de_sesion(importar_sesion_json(archivo_sesion)$fase1)
  reconstruido$dataset$n == 118L && reconstruido$dataset$n_crudo == 4543L
})
probar("lo declarado en el diccionario sobrevive al viaje", {
  # Es la mitad del valor de guardar una sesion: Temperatura es de intervalo
  # porque alguien lo decidio, y R no lo puede volver a deducir.
  dicc <- dataset_de_sesion(
    importar_sesion_json(archivo_sesion)$fase1)$dataset$diccionario
  identical(dicc$escala[dicc$columna == "Temperatura"], "intervalo")
})
probar("un archivo viejo (solo el almacen) se sigue abriendo", {
  viejo <- tempfile(fileext = ".rds")
  saveRDS(nuevo_almacen(), viejo)
  leida <- importar_sesion_rds(viejo)
  !is.null(leida$almacen) && is.null(leida$fase1)
})
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
  codigo <- codigo_artefacto("f1.calidad.atipicos", list(columna = "Presion"))
  any(grepl("boxplot(x, plot = FALSE)", codigo, fixed = TRUE))
})
probar("el diccionario declarado viaja dentro del chunk", {
  tabla <- ds_sesion$diccionario[, c("columna", "escala", "clase", "rol")]
  codigo <- codigo_artefacto("f1.diccionario.tabla", list(), tabla)
  any(grepl("diccionario <- data.frame(", codigo, fixed = TRUE)) &&
    any(grepl("intervalo", paste(codigo, collapse = " "), fixed = TRUE))
})

cat(sprintf("\n[test_informe] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
