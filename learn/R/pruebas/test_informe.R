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

probar("el cuaderno abre con el YAML de la plantilla del taller",
       cuaderno[1] == "---" &&
         any(grepl("taller-qmd-template.tex", cuaderno, fixed = TRUE)))
probar("la fuente ori se recarga desde el CSV original, no desde el exportado",
       any(grepl('c("ORI.csv", "data/ORI.csv",', cuaderno, fixed = TRUE)) &&
         !any(grepl("datos-sda-lab.csv", cuaderno, fixed = TRUE)))
probar("la fuente ori se baja de Kaggle y cae a la copia local sin red",
       any(grepl("datasets/download/", cuaderno, fixed = TRUE)) &&
         any(grepl('"overhcv/ori-dataset"', cuaderno, fixed = TRUE)) &&
         any(grepl("tryCatch", cuaderno, fixed = TRUE)))
probar("la recta de regresion viaja al codigo del cuaderno", {
  codigo <- codigo_artefacto("f1.analisis.dispersion",
                             list(x = "Temperatura", y = "Velocidad_del_Viento",
                                  regresion = TRUE))
  any(grepl('method = "lm"', codigo, fixed = TRUE)) &&
    any(grepl("lm(Velocidad_del_Viento ~ Temperatura", codigo, fixed = TRUE))
})
probar("el panel del filtro rehace la tabla al cargar / ahora / fuera", {
  entorno <- new.env(parent = globalenv())
  crudos <- data.frame(Hora = rep(c("00:00", "12:00"), c(4425L, 118L)))
  assign("filas_al_cargar", nrow(crudos), envir = entorno)
  assign("datos", crudos[crudos$Hora == "12:00", , drop = FALSE], envir = entorno)
  codigo <- codigo_artefacto("f1.filtro.filas",
                             list(filtros = "Hora en [12:00]"))
  tabla <- eval(parse(text = paste(codigo, collapse = "\n")), envir = entorno)
  identical(as.numeric(tabla$cantidad), c(4543, 118, 4425)) &&
    any(grepl("Hora en [12:00]", codigo, fixed = TRUE))
})
probar("el cuaderno anota las filas al cargar antes de preparar",
       any(grepl("filas_al_cargar <- nrow(datos)", cuaderno, fixed = TRUE)))
probar("el umbral de IQR elegido viaja al cuaderno, no un 1.5 fijo", {
  codigo <- codigo_artefacto("f1.calidad.atipicos",
                             list(columna = "Temperatura", metodo = "iqr",
                                  umbral = 3))
  any(grepl("range = 3", codigo, fixed = TRUE)) &&
    !any(grepl("1.5 * ric", codigo, fixed = TRUE))
})
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
  lineas <- armar_informe_exploracion(dos_densidades, ds_cuaderno,
                                      texto = "completo")
  sum(grepl("^### Qué muestra", lineas)) == 1L &&
    any(grepl("está en la primera sección", lineas, fixed = TRUE))
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
probar("el pie dice cuantos paneles y en que modo se genero", {
  con_marco <- armar_informe_exploracion(
    seleccion_cuaderno, ds_cuaderno,
    opciones = c(opciones_cuaderno(), "marco"))
  any(grepl("2 paneles", con_marco, fixed = TRUE))
})
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

cat(sprintf("\n[test_informe] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
