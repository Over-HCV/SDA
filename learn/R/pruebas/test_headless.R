# learn/R/pruebas/test_headless.R
#
# Responsabilidad: probar el núcleo COMPLETO sin Shiny.
#
# Uso:  Rscript learn/R/pruebas/test_headless.R
#
# Que esto pase sin cargar bslib ni DT es la prueba de que la separación C3
# se sostiene, y es lo que hará posible una CLI encima del mismo núcleo.
#
# No usa testthat a propósito: un harness de 5 líneas basta y no obliga a
# montar un paquete. La regla es que cada bloque termine en `probar()`.

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

# ---------------------------------------------------------------------------
cat("\n[registro]\n")
probar("hay métodos registrados", length(claves_metodos()) > 30)
probar("metodo() falla con clave inexistente", falla(metodo("no_existe")))
probar("no hay duplicados", !anyDuplicated(claves_metodos()))
probar("filtrar por objetivo devuelve solo ese objetivo", {
  claves <- filtrar_metodos(objetivo = "agrupar")
  length(claves) > 0 &&
    all(vapply(claves, function(k) metodo(k)$objetivo == "agrupar", logical(1)))
})
probar("la búsqueda no distingue mayúsculas",
       identical(filtrar_metodos(busqueda = "K-MEDIAS"),
                 filtrar_metodos(busqueda = "k-medias")))
probar("un método activo exige función de ajuste",
       falla(registrar_metodo("prueba_sin_ajuste", "X", "reducir",
                              estado = "activo")))
probar("un método bloqueado exige motivo",
       falla(registrar_metodo("prueba_sin_motivo", "X", "reducir",
                              estado = "bloqueado")))
probar("todos los bloqueados tienen puente", {
  claves <- filtrar_metodos(estado = "bloqueado")
  length(claves) > 0 &&
    all(vapply(claves, function(k) !is.na(metodo(k)$puente), logical(1)))
})

# ---------------------------------------------------------------------------
cat("\n[artefactos y trazabilidad]\n")
probar("ningún método promete un artefacto inexistente",
       length(artefactos_huerfanos()) == 0)
probar("toda clave sigue el patrón fase.subseccion.artefacto",
       all(grepl("^f[0-9]\\.[a-z0-9_]+\\.[a-z0-9_]+$", claves_artefactos())))
probar("rutas_de devuelve gráfico, lógica y texto", {
  r <- rutas_de("f4.desempeno.roc")
  all(c("grafico", "logica", "texto") %in% names(r)) && !is.na(r$grafico)
})
probar("clave de artefacto inválida es rechazada",
       falla(registrar_artefacto("roc", "Curva ROC")))

# ---------------------------------------------------------------------------
cat("\n[objetos y almacén]\n")
datos_prueba <- data.frame(x = rnorm(50), y = rnorm(50),
                           g = rep(c("a", "b"), 25), stringsAsFactors = FALSE)

probar("el diccionario clasifica numéricas y categóricas", {
  d <- diccionario_inicial(datos_prueba)
  nrow(d) == 3 && d$clase[d$columna == "x"] == "continua" &&
    d$escala[d$columna == "g"] == "nominal"
})

almacen <- nuevo_almacen()
almacen <- almacen_agregar(almacen, nuevo_dataset(NULL, "prueba", datos_prueba))
id_dataset <- attr(almacen, "id_nuevo")
almacen <- almacen_agregar(almacen, nuevo_modelo(NULL, "ACP de prueba", "acp"))
id_modelo <- attr(almacen, "id_nuevo")
almacen <- almacen_agregar(almacen, nueva_receta(NULL, "estricta"))
id_receta <- attr(almacen, "id_nuevo")

probar("los ids se asignan con su prefijo",
       id_dataset == "d1" && id_modelo == "m1" && id_receta == "r1")
probar("el almacén cuenta lo que guardó",
       almacen_contar(almacen, "dataset") == 1)
probar("agregar devuelve un almacén nuevo, no muta el viejo",
       almacen_contar(nuevo_almacen(), "dataset") == 0)
probar("actualizar algo inexistente falla",
       falla(almacen_actualizar(almacen, nueva_receta("r99", "fantasma"))))
probar("clonar crea un id nuevo", {
  clonado <- almacen_clonar(almacen, "modelo", id_modelo)
  almacen_contar(clonado, "modelo") == 2 && attr(clonado, "id_nuevo") == "m2"
})

almacen <- almacen_agregar(almacen, nueva_corrida(
  NULL, id_dataset, id_modelo, id_receta, "acp",
  metricas = list(varianza_explicada = 0.71), estado = "listo"))
id_corrida <- attr(almacen, "id_nuevo")

probar("eliminar un dataset arrastra sus corridas", {
  sin_dataset <- almacen_eliminar(almacen, "dataset", id_dataset)
  almacen_contar(sin_dataset, "corrida") == 0
})
probar("objetos_df devuelve una fila por objeto",
       nrow(objetos_df(almacen, "modelo")) == 1)

# ---------------------------------------------------------------------------
cat("\n[contratos]\n")
dataset <- almacen_obtener(almacen, "dataset", id_dataset)
modelo <- almacen_obtener(almacen, "modelo", id_modelo)

probar("sin dataset y sin modelo se reportan los dos faltantes",
       length(validar_compatibilidad()) >= 2)
probar("ACP sobre un dataset pendiente no es componible", {
  avisos <- validar_compatibilidad(dataset, modelo)
  !componible(avisos)   # acp está "pendiente" en el Hito 1
})
probar("un dataset con pocas numéricas dispara el aviso de min_p", {
  flaco <- nuevo_dataset("dx", "flaco", data.frame(a = 1:20))
  avisos <- validar_compatibilidad(flaco, modelo)
  any(vapply(avisos, function(a) a$clave == "min_p", logical(1)))
})
probar("los faltantes se detectan", {
  con_na <- datos_prueba; con_na$x[1] <- NA
  ds <- nuevo_dataset("dn", "con NA", con_na)
  avisos <- validar_compatibilidad(ds, modelo)
  any(vapply(avisos, function(a) a$clave == "faltantes", logical(1)))
})
probar("severidad_maxima ordena bien",
       severidad_maxima(list(list(severidad = "aviso"),
                             list(severidad = "error"))) == "error")

# ---------------------------------------------------------------------------
cat("\n[textos]\n")
probar("un texto escrito se renderiza a HTML",
       grepl("<h2", texto("f1.analisis.histograma"), fixed = TRUE))
probar("un texto inexistente avisa y no falla",
       grepl("Sin texto todav", texto("f4.desempeno.roc")))
probar("una ficha escrita se renderiza a HTML",
       grepl("<h2", ficha("acp"), fixed = TRUE))
probar("una ficha inexistente avisa y no falla",
       grepl("Ficha pendiente", ficha("hotelling"), fixed = TRUE))
probar("cobertura_textos cuenta los esperados",
       cobertura_textos()$textos_esperados == length(claves_artefactos()))

# ---------------------------------------------------------------------------
cat("\n[exportadores]\n")
directorio <- file.path(tempdir(), "sda-pruebas")
dir.create(directorio, showWarnings = FALSE, recursive = TRUE)
corrida <- almacen_obtener(almacen, "corrida", id_corrida)

probar("exportar_json escribe un JSON legible", {
  ruta <- exportar_json(corrida, file.path(directorio, "corrida.json"),
                        dataset = dataset)
  leido <- jsonlite::fromJSON(ruta)
  leido$escenario == id_corrida && leido$metodo == "acp"
})
probar("el JSON conserva la composición", {
  leido <- jsonlite::fromJSON(file.path(directorio, "corrida.json"))
  leido$composicion$dataset == id_dataset
})
probar("exportar_csv y releer da las mismas dimensiones", {
  ruta <- exportar_csv(datos_prueba, file.path(directorio, "datos.csv"))
  identical(dim(utils::read.csv(ruta)), dim(datos_prueba))
})
probar("exportar_rds hace ida y vuelta sin pérdida", {
  ruta <- exportar_rds(almacen, file.path(directorio, "sesion.rds"))
  identical(almacen_contar(importar_sesion_rds(ruta), "modelo"),
            almacen_contar(almacen, "modelo"))
})
probar("la sesión en JSON no arrastra objetos de ajuste", {
  ruta <- exportar_sesion_json(almacen, file.path(directorio, "sesion.json"))
  leido <- importar_sesion_json(ruta)
  is.null(leido$corridas[[1]]$ajuste)
})
probar("exportar_rmd produce un cuaderno con encabezado YAML", {
  ruta <- exportar_rmd(corrida, file.path(directorio, "informe.Rmd"),
                       dataset = dataset, modelo = modelo)
  lineas <- readLines(ruta, warn = FALSE)
  lineas[1] == "---" && any(grepl("^title:", lineas))
})
probar("el informe incluye el comando para reproducir", {
  lineas <- readLines(file.path(directorio, "informe.Rmd"), warn = FALSE)
  any(grepl("run_headless.R", lineas, fixed = TRUE))
})

# ---------------------------------------------------------------------------
cat("\n[bloque de contexto]\n")
bloque <- contexto_de("f4.desempeno.roc", corrida = corrida,
                      metricas = list(auc = 0.81))
probar("el bloque nombra la clave", grepl("f4.desempeno.roc", bloque, fixed = TRUE))
probar("el bloque apunta al archivo de lógica",
       grepl("learn/R/logica/metricas_clasificacion.R", bloque, fixed = TRUE))
probar("el bloque nombra la composición completa",
       grepl(sprintf("dataset %s x modelo %s", id_dataset, id_modelo), bloque,
             fixed = TRUE))
probar("el bloque trae las métricas", grepl("0.81", bloque, fixed = TRUE))
probar("el bloque dice en qué modo se generó",
       grepl(modo_ejecucion(), bloque, fixed = TRUE))
probar("exportar_contexto escribe el mismo bloque", {
  ruta <- exportar_contexto("f4.desempeno.roc",
                            file.path(directorio, "contexto.md"),
                            corrida = corrida)
  any(grepl("Contexto SDA Lab", readLines(ruta, warn = FALSE), fixed = TRUE))
})

# ---------------------------------------------------------------------------
cat("\n[modo de ejecución]\n")
probar("por defecto es servidor", modo_ejecucion() == "servidor")
probar("SDA_MODO fuerza el modo", {
  Sys.setenv(SDA_MODO = "wasm"); resultado <- es_wasm()
  Sys.unsetenv("SDA_MODO"); resultado
})
probar("un SDA_MODO inválido falla fuerte", {
  Sys.setenv(SDA_MODO = "nube"); resultado <- falla(modo_ejecucion())
  Sys.unsetenv("SDA_MODO"); resultado
})

unlink(directorio, recursive = TRUE)

cat(sprintf("\n[test_headless] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
