# learn/R/pruebas/test_sesion.R
#
# Responsabilidad: probar que una sesión guardada vuelve con todo lo que se
# hizo en ① Datos —fuente, pila, diccionario, balanceo, partición, paneles
# marcados, lecturas y nivel de texto— sin Shiny.
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
probar("balanceo, particion, lecturas y nivel de texto vuelven con la sesion", {
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
  exportar_sesion_json(sesion_actual(nuevo_almacen(), ds_rec, seleccion_sesion,
                                     texto = "breve"), archivo)
  leida <- importar_sesion_json(archivo)$fase1
  vuelta <- dataset_de_sesion(leida)$dataset
  identical(leida$texto, "breve") &&
    identical(vuelta$df, ds_rec$df) &&
    identical(vuelta$balanceo$metodo, "sobremuestreo") &&
    identical(vuelta$particion$asignacion, ds_rec$particion$asignacion) &&
    is.null(importar_sesion_json(archivo)$fase1$particion$asignacion)
})
probar("la sesion de ejemplo del taller (sin balanceo ni particion) abre igual", {
  vieja <- dataset_de_sesion(importar_sesion_json(
    ruta_app("sesiones", "taller-01.json"))$fase1)$dataset
  vieja$n == 118L && is.null(vieja$balanceo) && is.null(vieja$particion)
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
