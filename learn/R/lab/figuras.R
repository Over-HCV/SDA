# learn/R/lab/figuras.R
#
# Responsabilidad: que un panel de la consola salga también como IMAGEN —el
# mismo ggplot que pinta la app, guardado en PNG o PDF— y las piezas que eso
# necesitó: las recetas de las fases 1 y 3, y la comparación de dos métodos.
#
# Las figuras de una presentación tienen que salir de la herramienta, no de un
# script paralelo que dibuja "algo parecido": si la figura del informe y la de
# la app se separan, una de las dos miente. Por eso no hay acá ningún ggplot
# nuevo: `figura_de_panel()` toma el objeto que arma grafico_de_panel()
# (lab/paneles.R) —el mismo que `panel` lee como tabla— y lo guarda.
#
#   Rscript learn/R/lab.R panel f4.diagnostico.codo --metodo kmodos \
#     --hiper k=7 --fuente zoo --clase tipo --salida codo.png \
#     --ancho 7 --alto 4.5 --dpi 200
#
# El tema es el de la app (tema_ggplot(): theme_minimal, fondo blanco), que ya
# es claro y sobrio; el fondo se fija en blanco para que un PNG no salga
# transparente sobre una diapositiva de color.

FORMATOS_FIGURA <- c("png", "pdf")

#' TRUE si `--salida` pide una imagen y no una tabla.
es_salida_figura <- function(salida) {
  !is.null(salida) && nzchar(salida) &&
    tolower(tools::file_ext(salida)) %in% FORMATOS_FIGURA
}

#' Guarda un panel como imagen y cuenta qué guardó.
#'
#' @param opciones las del CLI: `salida`, `ancho` y `alto` (pulgadas), `dpi`
figura_de_panel <- function(ds, clave, columnas, opciones = list()) {
  panel <- grafico_de_panel(ds, clave, columnas, opciones)
  ruta <- opciones$salida
  guardar_figura(panel$grafico, ruta,
                 ancho = as.numeric(opciones$ancho %||% 7),
                 alto = as.numeric(opciones$alto %||% 4.5),
                 dpi = as.numeric(opciones$dpi %||% 200))
  cat(panel$encabezado, "\n")
  subtitulo <- if (inherits(panel$grafico, "ggplot"))
    panel$grafico$labels$subtitle
  if (length(subtitulo)) cat("subtítulo:", subtitulo, "\n")
  cat(sprintf("figura escrita en %s (%s x %s in, %s dpi)\n", ruta,
              opciones$ancho %||% 7, opciones$alto %||% 4.5,
              opciones$dpi %||% 200))
  invisible(ruta)
}

#' ggsave con fondo blanco. Un panel que es tabla (reglas_k) no tiene figura:
#' se dice, en vez de guardar un lienzo vacío.
guardar_figura <- function(grafico, ruta, ancho = 7, alto = 4.5, dpi = 200) {
  if (!inherits(grafico, c("ggplot", "gtable", "grob")))
    stop("este panel es una tabla, no un gráfico: quitá --salida para leerla",
         call. = FALSE)
  carpeta <- dirname(ruta)
  if (!dir.exists(carpeta)) dir.create(carpeta, recursive = TRUE)
  # cairo_pdf incrusta las fuentes; sin cairo (macOS sin XQuartz) el pdf() de
  # base, que con la codificación por defecto igual escribe las tildes.
  dispositivo <- if (!identical(tolower(tools::file_ext(ruta)), "pdf")) "png"
                 else if (.hay_cairo()) grDevices::cairo_pdf else grDevices::pdf
  ggplot2::ggsave(ruta, grafico, width = ancho, height = alto, dpi = dpi,
                  units = "in", bg = "white", device = dispositivo)
  invisible(ruta)
}

# capabilities() dice TRUE aunque la biblioteca no cargue: se prueba abrir.
.hay_cairo <- function() {
  prueba <- tempfile(fileext = ".pdf")
  abierto <- tryCatch(suppressWarnings({
    grDevices::cairo_pdf(prueba); grDevices::dev.off(); file.exists(prueba)
  }), error = function(e) FALSE)
  unlink(prueba)
  isTRUE(abierto)
}

# ---------------------------------------------------------------------------
# Recetas de la fase 1: los paneles cuyo gráfico NO recibe el data.frame
# ---------------------------------------------------------------------------

# La mayoría de los gráficos de la fase 1 se llaman (datos, columna...), y por
# eso `panel` los resuelve sin receta. Estos tres reciben el resultado de su
# lógica, igual que en su card (ui/f1/balanceo.R, analisis/bivariado.R,
# analisis/multivariado.R): sin la receta fallaban con "unused arguments".
RECETAS_F1 <- list(
  "f1.balanceo.frecuencias" = function(datos, columnas, opciones)
    graficar_balance(resumir_balance(datos, .exigir(columnas[1],
      "panel f1.balanceo.frecuencias <columna>"))),
  "f1.analisis.mosaico" = function(datos, columnas, opciones) {
    uso <- "panel f1.analisis.mosaico <a> <b>"
    a <- .exigir(columnas[1], uso); b <- .exigir(columnas[2], uso)
    graficar_mosaico(tabla_contingencia(datos[[a]], datos[[b]], a, b))
  },
  "f1.analisis.heatmap_correlacion" = function(datos, columnas, opciones)
    graficar_heatmap_correlacion(matriz_correlacion(
      datos, if (length(columnas)) columnas else NULL)))

# ---------------------------------------------------------------------------
# Recetas de la fase 3: la traza del ajuste
# ---------------------------------------------------------------------------

# Lo que dibuja ui/f3/analisis.R y ui/f3/consola.R al terminar el paso a paso:
# la traza entera, no un paso intermedio.
RECETAS_F3 <- list(
  "f3.analisis.convergencia" = function(a, x)
    graficar_convergencia(traza_a_tabla(.traza_exigida(a)),
                          objetivo = a$traza$objetivo),
  "f3.analisis.trayectoria" = function(a, x) {
    tabla <- parametros_a_tabla(.traza_exigida(a))
    graficar_trayectoria(tabla[tabla$componente == 1L, , drop = FALSE],
                         componente = 1L)
  },
  "f3.consola.estado" = function(a, x) {
    final <- if (!is.null(a$asignaciones_por_iter))
      a$asignaciones_por_iter[, ncol(a$asignaciones_por_iter)]
    graficar_mapa_2d(coordenadas_2d(a, grupo = final), ejes = etiquetas_ejes(a))
  })

.traza_exigida <- function(ajuste) {
  if (is.null(ajuste$traza))
    stop("este ajuste no dejó traza: su optimizador resuelve en un paso",
         call. = FALSE)
  ajuste$traza
}

# ---------------------------------------------------------------------------
# Concordancia: la partición de otro método como clase de referencia
# ---------------------------------------------------------------------------

#' `--comparar <metodo>`: ajusta un segundo método sobre el mismo dataset y
#' pone SU partición donde iría la clase real, de modo que
#' f4.desempeno.cruce_clase da la tabla grupo x grupo y el ARI entre los dos.
#' Es el `table(K_means, Jerarquico)` y las dos semillas de la sesión 5.
#'
#' `--grupos` + `--clase grupo` no alcanzaba: la clase se declara antes de
#' agregar los grupos, y la única `--clase` ya es `tipo`.
#'
#' El segundo ajuste usa las mismas opciones que el primero, pisadas por
#' `--hiper_comparar a=1,b=2`, `--semilla_comparar n` e
#' `--inicializacion_comparar x`. Así `--metodo kmodos --comparar kmodos
#' --semilla_comparar 456` son las dos semillas del cuaderno del curso.
#'
#' @param ajustado salida de ajustar_cli() del método principal
#' @return el ajuste, con `referencia` y los rótulos de los dos ejes
adjuntar_comparacion <- function(ds, ajustado, opciones) {
  ajuste <- ajustado$ajuste
  otro <- opciones[["comparar"]]
  if (is.null(otro) || !nzchar(otro)) return(ajuste)
  propias <- .opciones_comparacion(opciones)
  segundo <- ajustar_cli(ds, otro, propias)
  if (length(segundo$ajuste$grupos) != length(ajuste$grupos))
    stop("los dos métodos no ajustaron las mismas filas: no se pueden cruzar",
         call. = FALSE)
  ajuste$referencia <- factor(segundo$ajuste$grupos,
                              levels = seq_len(segundo$ajuste$k))
  ajuste$columna_referencia <- otro
  ajuste$etiqueta_referencia <- .etiqueta_corrida(otro, segundo, propias)
  ajuste$etiqueta_particion <- .etiqueta_corrida(
    opciones$metodo %||% "", ajustado, sin_opciones_de_comparacion(opciones))
  message(sprintf("[comparar] %s contra %s · ARI = %.3f",
                  ajuste$etiqueta_particion, ajuste$etiqueta_referencia,
                  indice_rand_ajustado(ajuste$grupos, ajuste$referencia)))
  ajuste
}

#' Las opciones sin las `*_comparar`. Hace falta porque `$` sobre una lista
#' completa nombres parciales: sin `--semilla`, `opciones$semilla` devolvía el
#' valor de `--semilla_comparar` y los dos ajustes salían iguales.
sin_opciones_de_comparacion <- function(opciones)
  opciones[!grepl("_comparar$", names(opciones))]

# Las opciones del segundo ajuste: las del primero con lo `_comparar` encima.
# Todo con `[[` exacto, por la misma razón.
.opciones_comparacion <- function(opciones) {
  propias <- sin_opciones_de_comparacion(opciones)
  extra <- trimws(strsplit(opciones[["hiper_comparar"]] %||% "", ",")[[1]])
  pares <- c(extra[nzchar(extra)], propias[["hiper"]])
  # Gana el primero de cada nombre, que es el de `--hiper_comparar`.
  propias$hiper <- pares[!duplicated(sub("=.*$", "", pares))]
  propias$semilla <- opciones[["semilla_comparar"]] %||% propias[["semilla"]]
  propias$inicializacion <- opciones[["inicializacion_comparar"]] %||%
    propias[["inicializacion"]]
  propias
}

# "gower (estrategia=jerarquico, enlace=average)": el método y los
# hiperparámetros que se escribieron en la línea (salvo k, que es el mismo en
# los dos ejes), más el arranque y la semilla si se pidieron.
.etiqueta_corrida <- function(metodo, ajustado, opciones) {
  clave <- if (nzchar(metodo)) metodo else ajustado$metodo$clave %||% "método"
  escritos <- intersect(unique(sub("=.*$", "", opciones$hiper %||% character(0))),
                        setdiff(names(ajustado$parametros), "k"))
  partes <- c(if (length(escritos))
                texto_de_pares(ajustado$parametros[escritos]),
              if (!is.null(opciones$inicializacion))
                paste("inicio", opciones$inicializacion),
              if (!is.null(opciones$semilla)) paste("semilla", opciones$semilla))
  if (!length(partes)) return(clave)
  sprintf("%s (%s)", clave, paste(partes, collapse = ", "))
}
