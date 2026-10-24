# learn/R/pruebas/test_transformar_cli.R
#
# Responsabilidad: probar `--transformar tipo[:Col,Col]` del lab por consola
# (lab/dataset.R): la misma pila de la subsección Transformación, apilada
# después de los filtros, y que viaje al cuaderno y a la sesión.
#
# Uso:  Rscript learn/R/pruebas/test_transformar_cli.R
#
# Vive aparte de test_lab.R por C2: con este eje el archivo pasaba el techo.
# El caso es el del Taller 02: la EIA tiene muchos ceros, y el logaritmo de la
# app los desplaza (-min + 1) en vez de devolver -Inf.

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

PAISES_ATIPICOS <- "Country!=UnitedStates,China,SaudiArabia,Russia"
COLUMNAS <- c("Crude_oil_including_lease_condensate_production_TBPD",
           "Petroleum_and_other_liquids_consumption_TBPD")
ds_sin4 <- suppressMessages(armar_dataset(list(fuente = "eia",
                                                filtro = PAISES_ATIPICOS)))

cat("\n[lab.R · --transformar: la pila de la fase 1 por consola]\n")
ds_log <- suppressMessages(armar_dataset(list(
  fuente = "eia", filtro = PAISES_ATIPICOS, transformar = "logaritmo")))
probar("--transformar se repite y se apila DESPUÉS de los filtros", {
  partido <- partir_argumentos(c("datos", "--transformar", "logaritmo:A",
                                 "--transformar", "raiz:B"))
  tipos <- vapply(ds_log$transformaciones, `[[`, "", "tipo")
  identical(partido$opciones$transformar, c("logaritmo:A", "raiz:B")) &&
    identical(tipos, c("filtro", "logaritmo")) && ds_log$n == 107L
})
probar("logaritmo sin columnas toma todas las numéricas y los ceros quedan finitos", {
  numericas <- ds_log$transformaciones[[2]]$columnas
  valores <- unlist(ds_log$df[numericas], use.names = FALSE)
  ceros <- ds_sin4$df[[COLUMNAS[1]]] == 0
  length(numericas) == 57L && any(ceros, na.rm = TRUE) &&
    all(is.finite(valores[!is.na(valores)])) &&
    all(ds_log$df[[COLUMNAS[1]]][which(ceros)] == 0)
})
probar("metodo acp con --transformar logaritmo cambia el ACP", {
  crudo <- ajustar_cli(ds_sin4, "acp", list())$ajuste
  logaritmico <- ajustar_cli(ds_log, "acp", list())$ajuste
  all(is.finite(logaritmico$valores_propios)) &&
    max(abs(crudo$valores_propios - logaritmico$valores_propios)) > 1
})
probar("logaritmo:Col toca solo esa columna; un tipo inventado falla", {
  uno <- suppressMessages(aplicar_transformacion_cli(ds_sin4,
                                                     paste0("logaritmo:", COLUMNAS[2])))
  error <- tryCatch(aplicar_transformacion_cli(ds_sin4, "log10"),
                    error = function(e) e)
  !identical(uno$df[[COLUMNAS[2]]], ds_sin4$df[[COLUMNAS[2]]]) &&
    identical(uno$df[[COLUMNAS[1]]], ds_sin4$df[[COLUMNAS[1]]]) &&
    grepl("logaritmo", conditionMessage(error), fixed = TRUE)
})
probar("el log viaja al cuaderno (con su desplazamiento) y a la sesión", {
  entrada <- entrada_de_pedido("f4.diagnostico.scree:metodo=acp", ds_log)
  lineas <- armar_informe_exploracion(list(entrada), ds_log)
  archivo <- tempfile(fileext = ".json")
  exportar_sesion_json(sesion_actual(NULL, ds_log, list(entrada)), archivo)
  rehecho <- suppressMessages(dataset_de_sesion(
    importar_sesion_json(archivo)$fase1))$dataset
  any(grepl(sprintf("datos$%s <- log(datos$%s)", COLUMNAS[1], COLUMNAS[1]), lineas,
            fixed = TRUE)) &&
    isTRUE(all.equal(rehecho$df[[COLUMNAS[1]]], ds_log$df[[COLUMNAS[1]]]))
})

cat(sprintf("\n[test_transformar_cli] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
