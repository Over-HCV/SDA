# libs/_comun/R/pruebas.R
#
# Mini framework de pruebas compartido por los test_headless.R de cada
# proyecto. Sin dependencia de testthat: es un contador de asserts y un
# validador del contrato S2.
#
# Uso tipico:
#   source(".../pruebas.R")
#   pruebas_reset()
#   chk(nrow(d) > 0, "hay filas")
#   validar_s2("mi-escenario", OUT_DIR, metricas_esperadas = c("r2"))
#   pruebas_salir()          # imprime resumen y quit(status = 0/1)

.PRUEBAS <- new.env(parent = emptyenv())
.PRUEBAS$total <- 0L
.PRUEBAS$fallos <- 0L

pruebas_reset <- function() {
  .PRUEBAS$total <- 0L
  .PRUEBAS$fallos <- 0L
  invisible(NULL)
}

# ---------------------------------------------------------------------------
# Assert basico. Devuelve TRUE/FALSE ademas de imprimir, para poder cortar.
# ---------------------------------------------------------------------------
chk <- function(condicion, mensaje) {
  ok <- isTRUE(condicion)
  .PRUEBAS$total <- .PRUEBAS$total + 1L
  if (ok) {
    cat("  ok    ", mensaje, "\n", sep = "")
  } else {
    .PRUEBAS$fallos <- .PRUEBAS$fallos + 1L
    cat("  FALLA ", mensaje, "\n", sep = "")
  }
  invisible(ok)
}

# ---------------------------------------------------------------------------
# Validador del contrato S2 (ver escribir_salida() en metricas.R).
#
#   escenario          : nombre del escenario, sin extension
#   out_dir            : directorio absoluto donde quedaron los artefactos
#   metricas_esperadas : nombres que TIENEN que estar en $metricas y ser
#                        numericos finitos
#   espera_csv         : FALSE para artefactos que solo tienen plot
# ---------------------------------------------------------------------------
validar_s2 <- function(escenario, out_dir,
                       metricas_esperadas = character(),
                       espera_csv = TRUE) {
  cat("[S2] ", escenario, "\n", sep = "")
  json_path <- file.path(out_dir, paste0(escenario, ".json"))

  if (!chk(file.exists(json_path), "existe el .json")) return(invisible(FALSE))

  j <- tryCatch(jsonlite::read_json(json_path, simplifyVector = TRUE),
                error = function(e) NULL)
  if (!chk(!is.null(j), "el .json parsea")) return(invisible(FALSE))

  claves <- c("timestamp", "proyecto", "escenario", "params",
              "metricas", "archivos", "notas")
  faltan <- setdiff(claves, names(j))
  chk(length(faltan) == 0,
      sprintf("estan las 7 claves S2%s",
              if (length(faltan))
                paste0(" (faltan: ", paste(faltan, collapse = ", "), ")") else ""))

  chk(identical(j$escenario, escenario), "el campo escenario coincide")
  chk(is.character(j$timestamp) && nzchar(j$timestamp), "timestamp no vacio")

  for (m in metricas_esperadas) {
    v <- j$metricas[[m]]
    chk(!is.null(v) && is.numeric(v) && length(v) == 1 && is.finite(v),
        sprintf("metrica '%s' presente y finita", m))
  }

  # Los archivos declarados tienen que existir de verdad y no estar vacios.
  png <- j$archivos$plot
  if (!is.null(png)) {
    chk(file.exists(png), "el .png declarado existe en disco")
    if (file.exists(png))
      chk(isTRUE(file.info(png)$size > 1000), "el .png no esta vacio")
  }

  if (espera_csv) {
    csv <- j$archivos$datos
    if (chk(!is.null(csv) && file.exists(csv), "el .csv declarado existe")) {
      d <- utils::read.csv(csv)
      chk(nrow(d) > 0, "el .csv tiene filas")
    }
  }

  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Valida el schema de 6 columnas del log maestro y que los escenarios esten.
# ---------------------------------------------------------------------------
validar_run_log <- function(out_dir, escenarios = character()) {
  cat("[log] run_log.csv\n")
  log_path <- file.path(out_dir, "run_log.csv")
  if (!chk(file.exists(log_path), "existe run_log.csv")) return(invisible(FALSE))

  lg <- utils::read.csv(log_path, stringsAsFactors = FALSE)
  chk(all(c("timestamp", "proyecto", "escenario", "params_json",
            "metrica_principal", "plot") %in% names(lg)),
      "tiene el schema de 6 columnas")

  faltan <- setdiff(escenarios, lg$escenario)
  chk(length(faltan) == 0,
      sprintf("todos los escenarios quedaron registrados%s",
              if (length(faltan))
                paste0(" (faltan: ", paste(faltan, collapse = ", "), ")") else ""))
  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Resumen + codigo de salida. Es lo que convierte al archivo en un check
# usable desde shell / CI.
# ---------------------------------------------------------------------------
pruebas_salir <- function(etiqueta = "") {
  cat("\n========================================\n")
  cat(sprintf("  %s%d pruebas, %d fallas\n",
              if (nzchar(etiqueta)) paste0(etiqueta, ": ") else "",
              .PRUEBAS$total, .PRUEBAS$fallos))
  cat("========================================\n")
  if (.PRUEBAS$fallos > 0) {
    cat("RESULTADO: FALLA\n")
    quit(status = 1)
  }
  cat("RESULTADO: OK\n")
  quit(status = 0)
}
