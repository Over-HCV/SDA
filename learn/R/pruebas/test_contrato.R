# learn/R/pruebas/test_contrato.R
#
# Responsabilidad: probar que una corrida hecha por fuera de la app produce lo
# mismo que la app, y que nada se pierde por el camino.
#
# Uso:  Rscript learn/R/pruebas/test_contrato.R
#
# Vive aparte de test_acp.R porque lo que se prueba acá no es el ACP: es
# `run_headless.R`, el contrato S2 de libs/sdd.md y la regla de las tres partes
# (C11). El ACP es solo el método que hoy los ejercita; cuando entre k-medias,
# este archivo cambia de datos y no de aserciones.
#
# Qué garantiza C11: todo hiperparámetro existe a la vez en la función pura, en
# `correr()` y en la UI. Las dos primeras se comprueban acá. La tercera la
# comprueba test_app_metodo.R moviendo el control en el navegador, porque un
# input sin binding no lo detecta ningún harness sin GUI.

source("learn/R/cargar.R")
cargar_sda(con_ui = FALSE)
source("learn/R/run_headless.R")

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

set.seed(11)
n <- 200
nube <- data.frame(a = stats::rnorm(n), b = NA_real_,
                   c = stats::rnorm(n) * 20 + 100, d = stats::rnorm(n))
nube$b <- nube$a * 0.9 + stats::rnorm(n, sd = 0.35)

# `escribir_salida()` resuelve out_dir contra la raíz del repo, así que acá va
# una ruta RELATIVA: pasarle un tempdir absoluto escribe en
# <raiz>/var/folders/... y los archivos aparecen donde nadie los busca.
salida <- file.path("learn", "outputs", "test-contrato")
salida_abs <- ruta_repo(salida)
on.exit(unlink(salida_abs, recursive = TRUE), add = TRUE)

corrida <- correr("prueba-acp", fuente = nube, hiper = list(n_componentes = 3L),
                  out_dir = salida)
json <- file.path(salida_abs, "prueba-acp.json")
leido <- jsonlite::fromJSON(json)

# ---------------------------------------------------------------------------
cat("\n[contrato S2 · los archivos]\n")

probar("la corrida queda lista y con duracion medida",
       corrida$estado == "listo" && is.finite(corrida$duracion))

probar("el JSON, el CSV y el PNG estan escritos", {
  todos <- file.path(salida_abs, paste0("prueba-acp", c(".json", ".csv", ".png")))
  all(file.exists(todos))
})

probar("el log maestro acumula la corrida",
       file.exists(file.path(salida_abs, "run_log.csv")) &&
         nrow(utils::read.csv(file.path(salida_abs, "run_log.csv"))) >= 1L)

probar("el CSV trae la tabla que hay detras del grafico", {
  tabla <- utils::read.csv(file.path(salida_abs, "prueba-acp.csv"))
  all(c("componente", "proporcion", "acumulada") %in% names(tabla))
})

probar("el JSON identifica proyecto y escenario",
       leido$proyecto == "sda-lab" && leido$escenario == "prueba-acp")

probar("las notas dicen sobre que datos corrio y con que avisos",
       grepl("componentes principales", leido$notas))

# ---------------------------------------------------------------------------
cat("\n[C11 · la regla de las tres partes]\n")

probar("cada hiperparametro del registro es argumento de la funcion pura",
       all(names(metodo("acp")$hiper) %in%
             names(formals(metodo("acp")$ajustar))))

probar("todo hiperparametro del registro viaja al bloque params del JSON",
       all(names(metodo("acp")$hiper) %in% names(leido$params)))

probar("correr() acepta pisar cualquier hiperparametro por nombre", {
  otra <- correr("prueba-cov", fuente = nube,
                 hiper = list(matriz = "covarianza"), out_dir = salida)
  otra$params$matriz == "covarianza"
})

probar("el batch usa los mismos valores por defecto que la app", {
  por_defecto <- hiper_por_defecto("acp")
  identical(por_defecto$n_componentes, metodo("acp")$hiper$n_componentes$def) &&
    identical(por_defecto$matriz, metodo("acp")$hiper$matriz$def)
})

# ---------------------------------------------------------------------------
cat("\n[reproducibilidad (C13)]\n")

probar("la semilla viaja al JSON: sin ella no hay reproduccion",
       leido$params$semilla == 42)

probar("el control del optimizador tambien viaja",
       all(c("optimizador", "tol", "maxit") %in% names(leido$params)))

probar("queda escrito que columnas entraron",
       nzchar(leido$params$columnas))

probar("las metricas del JSON son las de la corrida",
       abs(leido$metricas$varianza_acumulada -
             corrida$metricas$varianza_acumulada) < 1e-4)

probar("dos corridas con la misma semilla dan la misma metrica", {
  repetida <- correr("prueba-repetida", fuente = nube,
                     hiper = list(n_componentes = 3L), out_dir = salida)
  abs(repetida$metricas$varianza_acumulada -
        corrida$metricas$varianza_acumulada) < 1e-12
})

# ---------------------------------------------------------------------------
cat("\n[lo que el corredor NO deja hacer]\n")

probar("un metodo pendiente no se puede correr por batch",
       falla(correr("no-va", metodo = "mds", fuente = nube, out_dir = salida)))

probar("un metodo bloqueado tampoco",
       falla(correr("no-va", metodo = "mlp", fuente = nube, out_dir = salida)))

probar("una clave inexistente falla fuerte y no en silencio",
       falla(correr("no-va", metodo = "no_existe", fuente = nube,
                    out_dir = salida)))

# ---------------------------------------------------------------------------
cat(sprintf("\n[test_contrato] %s\n",
            if (.FALLOS == 0L) "todo verde" else sprintf("%d FALLO(S)", .FALLOS)))
if (.FALLOS > 0L) quit(status = 1L)
