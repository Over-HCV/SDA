# learn/R/pruebas/test_sesion.R
#
# Responsabilidad: probar que una sesión guardada vuelve con todo lo que se
# hizo en ① Datos —fuente, pila, diccionario, balanceo, partición, paneles
# marcados, lecturas y piezas del cuaderno— sin Shiny.
#
# Uso:  Rscript learn/R/pruebas/test_sesion.R
#
# Vivía dentro de test_informe.R. Es otro eje: aquel prueba el cuaderno, este
# el viaje de ida y vuelta de nucleo/sesion.R. El recorrido en el navegador
# (guardar desde Inicio y reabrir en una app nueva) está en test_app_sesion.R.

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

cat("\n[sesiones]\n")
ds_cli <- armar_dataset(list(fuente = "ori", filtro = "Hora=12:00"))
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
#' Una sesion tal como la escribia la version 1: `texto` en vez de `cuaderno`,
#' sin balanceo ni particion. Se escribe a JSON y se vuelve a leer para que el
#' camino probado sea el de un archivo de verdad.
sesion_version_1 <- function() {
  archivo <- tempfile(fileext = ".json")
  exportar_json(list(
    proyecto = "sda-lab", tipo = "sesion", version = 1L,
    exportado = "2026-09-12 07:25:00", modo = "servidor",
    fase1 = list(
      fuente = "ori", nombre = "ori", semilla = 42L, n_crudo = 4543L,
      transformaciones = list(list(tipo = "filtro", columnas = "Hora",
                                   params = list(valores = "12:00"))),
      seleccion = list(), texto = "breve")), archivo)
  importar_sesion_json(archivo)$fase1
}

probar("balanceo, particion, lecturas y piezas vuelven con la sesion", {
  # Lo que antes se perdia al recargar: la receta del balanceo y de la
  # particion se guardan (no las filas) y se rehacen igual con su semilla.
  ds_rec <- dataset_de_sesion(importar_sesion_json(archivo_sesion)$fase1)$dataset
  balanceado <- balancear(ds_rec$df, "Pronostico", "sobremuestreo", 4L)
  ds_rec$df <- balanceado$datos
  ds_rec$n <- nrow(balanceado$datos)
  ds_rec$balanceo <- list(metodo = "sobremuestreo", columna = "Pronostico",
                          semilla = 4L)
  ds_rec$particion <- particionar(ds_rec$df, "holdout", 0.7,
                                  estratificar = "Pronostico", semilla = 9L)
  archivo <- tempfile(fileext = ".json")
  exportar_sesion_json(
    sesion_actual(nuevo_almacen(), ds_rec, seleccion_sesion,
                  cuaderno = c("notas", "procedencia")), archivo)
  leida <- importar_sesion_json(archivo)$fase1
  vuelta <- dataset_de_sesion(leida)$dataset
  setequal(leida$cuaderno, c("procedencia", "notas")) &&
    identical(vuelta$df, ds_rec$df) &&
    identical(vuelta$balanceo$metodo, "sobremuestreo") &&
    identical(vuelta$particion$asignacion, ds_rec$particion$asignacion) &&
    is.null(importar_sesion_json(archivo)$fase1$particion$asignacion)
})
probar("una sesion vieja (sin balanceo ni particion) abre igual", {
  # Una sesion de la version 1: sin balanceo ni particion, y con el nivel de
  # texto donde hoy van las piezas del cuaderno. Se arma aca y no se lee de un
  # taller: el archivo de un taller lo borra quien limpia su carpeta.
  vieja <- sesion_version_1()
  ds <- dataset_de_sesion(vieja)$dataset
  ds$n == 118L && is.null(ds$balanceo) && is.null(ds$particion)
})
probar("la sesion de ejemplo que trae la app es la del Taller 0", {
  ejemplos <- basename(list.files(ruta_app("sesiones")))
  ejemplo <- importar_sesion_json(ruta_app("sesiones", "taller-00.json"))$fase1
  identical(ejemplos, "taller-00.json") &&
    dataset_de_sesion(ejemplo)$dataset$n == 183L &&
    length(seleccion_de_sesion(ejemplo)) == 7L
})
probar("mover una entrada la sube, la baja y no se sale de la lista", {
  ids <- function(entradas) vapply(entradas, function(e) e$id, "")
  identical(ids(mover_entrada(seleccion_sesion, "p2", -1L)), c("p2", "p1")) &&
    identical(ids(mover_entrada(seleccion_sesion, "p1", 1L)), c("p2", "p1")) &&
    identical(mover_entrada(seleccion_sesion, "p1", -1L), seleccion_sesion) &&
    identical(mover_entrada(seleccion_sesion, "p2", 1L), seleccion_sesion) &&
    identical(mover_entrada(seleccion_sesion, "p9", -1L), seleccion_sesion)
})
probar("el orden nuevo es el del cuaderno y el de la sesion guardada", {
  # Un panel olvidado que debia abrir el informe: se sube y queda primero.
  movida <- mover_entrada(seleccion_sesion, "p2", -1L)
  cuaderno <- armar_informe_exploracion(movida, ds_sesion)
  archivo <- tempfile(fileext = ".json")
  exportar_sesion_json(sesion_actual(nuevo_almacen(), ds_sesion, movida),
                       archivo)
  vuelta <- seleccion_de_sesion(importar_sesion_json(archivo)$fase1)
  which(grepl("^## Diccionario", cuaderno))[1] <
    which(grepl("^## Resumen", cuaderno))[1] &&
    identical(vapply(vuelta, function(e) e$id, ""), c("p2", "p1")) &&
    identical(vuelta[[2]]$nota, "La media queda debajo de la mediana.")
})
probar("un archivo viejo (solo el almacen) se sigue abriendo", {
  viejo <- tempfile(fileext = ".rds")
  saveRDS(nuevo_almacen(), viejo)
  leida <- importar_sesion_rds(viejo)
  !is.null(leida$almacen) && is.null(leida$fase1)
})

cat(sprintf("\n[test_sesion] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
