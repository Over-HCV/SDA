# learn/R/lab/metodos.R
#
# Responsabilidad: las fases 2-4 desde la consola — los momentos de la nube,
# ajustar un método del catálogo y leer qué salió.
#
# El ajuste NO se arma acá: pasa por ajustar_por_registro() (nucleo/ajuste.R),
# el mismo tramo que usa `correr()` de run_headless.R. Si la consola ajustara a
# su manera, un número leído acá podría no ser el que la app muestra, y la
# consola existe justamente para no tener que abrir la app a comprobarlo.

#' Los pares `--hiper nombre=valor` que le tocan a `metodo`, ya tipados.
#'
#' `--hiper` es uno solo aunque haya dos métodos en juego (`--grupos kmeans`
#' para la columna y `--metodo acp` para el panel): cada uno se lleva los
#' nombres que su registro declara. Un nombre que no declara ninguno de los dos
#' es un error, porque correr el default en silencio es peor que no correr.
hiper_cli <- function(metodo, opciones, pares = opciones$hiper) {
  crudos <- .lab_pares(pares)
  en_juego <- unique(c(metodo, opciones$metodo, opciones$grupos))
  en_juego <- en_juego[nzchar(en_juego) & vapply(en_juego, existe_metodo, TRUE)]
  conocidos <- unique(unlist(lapply(en_juego, function(m)
    names(hiper_por_defecto(m)))))
  extranos <- setdiff(names(crudos), conocidos)
  if (length(extranos))
    stop(sprintf("ningún método en juego (%s) tiene el hiperparámetro %s",
                 paste(en_juego, collapse = ", "),
                 paste(extranos, collapse = ", ")), call. = FALSE)
  propios <- crudos[names(crudos) %in% names(hiper_por_defecto(metodo))]
  stats::setNames(lapply(names(propios), function(nombre)
    convertir_hiper(metodo, nombre, propios[[nombre]])), names(propios))
}

#' Una lista con nombre como `k=3 · escalar=TRUE`. `unlist()` la volvía
#' `escalar=1`: mezcla tipos y gana el numérico.
texto_de_pares <- function(lista, separador = ", ")
  paste(names(lista), vapply(lista, function(v) paste(format(v), collapse = ","),
                             ""), sep = "=", collapse = separador)

#' `nombre=valor` sueltos a una lista con nombre, todavía como texto.
.lab_pares <- function(pares) {
  pares <- pares %||% character(0)
  if (!length(pares)) return(list())
  malos <- pares[!grepl("=", pares, fixed = TRUE)]
  if (length(malos))
    stop("un hiperparámetro se escribe nombre=valor, no: ", malos[1],
         call. = FALSE)
  stats::setNames(as.list(sub("^[^=]*=", "", pares)), sub("=.*$", "", pares))
}

#' `--columnas a,b,c`, o NULL para que el método tome las que admite.
columnas_cli <- function(opciones) {
  valor <- opciones$columnas
  if (is.null(valor) || !nzchar(valor)) return(NULL)
  trimws(strsplit(valor, ",", fixed = TRUE)[[1]])
}

#' El método para un panel de la fase 4: el pedido o, si no se pidió, el
#' único activo que declara esa clave. Si son varios, adivinar sería elegir
#' por el usuario, así que se le pide.
metodo_para_clave <- function(clave, pedido = NULL) {
  if (!is.null(pedido) && nzchar(pedido)) return(pedido)
  candidatos <- Filter(function(k) {
    m <- metodo(k)
    m$estado == "activo" && clave %in% m$artefactos
  }, claves_metodos())
  if (length(candidatos) == 1L) return(candidatos)
  stop(sprintf("%s necesita --metodo (lo declaran: %s)", clave,
               if (length(candidatos)) paste(candidatos, collapse = ", ")
               else "ningún método activo"), call. = FALSE)
}

#' El ajuste de la línea de comandos, por el mismo camino que `correr()`.
ajustar_cli <- function(ds, metodo, opciones, hiper = hiper_cli(metodo, opciones)) {
  ajustar_por_registro(ds$df, metodo, columnas = columnas_cli(opciones),
                       hiper = hiper,
                       reinicios = as.integer(opciones$reinicios %||% 25L),
                       semilla = as.integer(opciones$semilla %||% 42L))
}

#' `momentos <col> <col> ...`: x̄ y S sobre las filas completas.
comando_momentos <- function(ds, args, opciones = list()) {
  columnas <- if (length(args)) args else NULL
  momentos <- momentos_muestrales(ds$df, columnas)
  cat(sprintf("%d variables · n = %d filas completas%s\n",
              length(momentos$medias), momentos$n,
              if (momentos$descartadas)
                sprintf(" (%d descartadas por faltantes)", momentos$descartadas)
              else ""))
  cat("\nvector de medias\n")
  indices <- sprintf("[%d]", seq_along(momentos$medias))
  print(data.frame(i = indices, variable = names(momentos$medias),
                   media = unname(momentos$medias)), row.names = FALSE)
  # Con los nombres del EIA (cincuenta caracteres cada uno) la matriz se
  # partía en cinco bloques de una columna. Va por índice, y el índice se lee
  # en la tabla de medias de arriba.
  cat("\nmatriz de varianzas-covarianzas (S, divisor n - 1)\n")
  covarianzas <- momentos$covarianzas
  dimnames(covarianzas) <- list(indices, indices)
  covarianzas
}

#' `metodo <clave>`: ajusta y cuenta qué salió — la franja de estado, las
#' métricas que van al JSON, la frase de lectura y la tabla del resultado.
comando_metodo <- function(ds, args, opciones = list()) {
  clave <- .exigir(.arg(args, 1L, opciones$metodo %||% ""),
                   "metodo <clave> [--hiper nombre=valor] [--columnas a,b]")
  resultado <- ajustar_cli(ds, clave, opciones)
  ajuste <- resultado$ajuste
  cat(sprintf("%s · %s · %.2fs\n", clave, resultado$metodo$nombre,
              resultado$duracion))
  cat("hiper:", texto_de_pares(resultado$parametros, " · "), "\n")
  resumen <- resumen_ajuste(ajuste)
  cat("resumen:", paste(names(resumen), unlist(resumen), collapse = " · "), "\n")
  metricas <- metricas_de_corrida(ajuste)
  cat("métricas:", paste(names(metricas),
                         vapply(metricas, function(v)
                           paste(format(v, digits = 6), collapse = ","), ""),
                         sep = " = ", collapse = " · "), "\n")
  cat("lectura:", lectura_resultado(ajuste), "\n\n")
  tabla_resultado(ajuste)
}
