# learn/R/lab/paneles.R
#
# Responsabilidad: devolver un panel de la app como TABLA — el gráfico
# registrado, construido y leído con ggplot_build() en vez de dibujado.
#
# Fase 1: el gráfico se llama con el data.frame y las columnas pedidas, que es
# su firma. Fase 4: se ajusta el método (lab/metodos.R) y se encadenan la
# lógica y el gráfico del artefacto con los mismos argumentos que les pasa la
# card de la app (ui/f4/diagnostico.R, aportes.R, explicabilidad.R,
# desempeno.R). Un artefacto sin receta propia se resuelve por el registro:
# lógica(ajuste) y gráfico(resultado). Las recetas de las fases 1 y 3 y el
# guardado como imagen viven en lab/figuras.R.

# Las columnas de estilo (color, alpha, linetype) no son el resultado: son cómo
# se pintó. Se van para que quede la tabla que uno leería del dibujo.
ESTILO_CAPAS <- c("colour", "fill", "alpha", "linewidth", "linetype", "shape",
                  "size", "weight", "flipped_aes", "PANEL", "group")

#' Las capas ya calculadas de un ggplot, sin las columnas de estilo.
#'
#' Un eje discreto sale de ggplot_build() como 1, 2, 3…: la variable de cada
#' barra de contribuciones o el grupo de cada caja se perdían. Se devuelven en
#' `x_nombre` / `y_nombre`, al principio, que es lo que uno lee en el eje. Con
#' facetas (una por componente) va además `faceta`: sin ella, las barras de
#' CP1 y CP2 quedaban mezcladas en una sola tabla sin decir de cuál eran.
.lab_capas <- function(grafico, encabezado) {
  construido <- ggplot2::ggplot_build(grafico)
  cat(sprintf("%s · %d capa(s)\n", encabezado, length(construido$data)))
  # El subtítulo lleva el número que resume el panel (silueta media, ARI,
  # acumulado del scree): sin él, la tabla de capas no lo dice en ningún lado.
  if (length(grafico$labels$subtitle))
    cat("subtítulo:", grafico$labels$subtitle, "\n")
  lapply(construido$data, .lab_capa_legible, construido$layout)
}

.lab_capa_legible <- function(capa, disposicion) {
  nombres <- list()
  escalas <- list(x = disposicion$panel_scales_x[[1]],
                  y = disposicion$panel_scales_y[[1]])
  for (eje in names(escalas)) {
    escala <- escalas[[eje]]
    if (!is.null(escala) && escala$is_discrete() && eje %in% names(capa))
      nombres[[paste0(eje, "_nombre")]] <-
        escala$get_limits()[round(as.numeric(capa[[eje]]))]
  }
  paneles <- disposicion$layout
  facetas <- setdiff(names(paneles), c("PANEL", "ROW", "COL", "SCALE_X",
                                       "SCALE_Y", "COORD"))
  if (nrow(paneles) > 1L && length(facetas) && "PANEL" %in% names(capa))
    nombres$faceta <- do.call(paste, unname(as.list(
      paneles[match(capa$PANEL, paneles$PANEL), facetas, drop = FALSE])))
  limpia <- capa[, setdiff(names(capa), ESTILO_CAPAS), drop = FALSE]
  if (!length(nombres)) return(limpia)
  cbind(as.data.frame(nombres, stringsAsFactors = FALSE), limpia)
}

#' El gráfico de un panel, como tabla. Las claves `f3.` y `f4.` van por su
#' lado: no miran columnas, miran un ajuste.
tabla_de_panel <- function(ds, clave, columnas, opciones = list()) {
  panel <- grafico_de_panel(ds, clave, columnas, opciones)
  if (!inherits(panel$grafico, "ggplot")) {
    cat(panel$encabezado, "\n")
    return(panel$grafico)
  }
  capas <- .lab_capas(panel$grafico, panel$encabezado)
  contexto <- panel$contexto
  if (is.null(contexto) || !clave %in% PANELES_DE_INDIVIDUOS) return(capas)
  # El color se fue con las columnas de estilo; acá vuelve como el valor que
  # pinta (el grupo de cada país), que es lo que dice la leyenda.
  lapply(capas, function(capa) {
    if (!is.null(contexto$nombres) && nrow(capa) == length(contexto$nombres))
      capa$etiqueta <- contexto$nombres
    if (!is.null(contexto$grupo) && nrow(capa) == length(contexto$grupo))
      capa[[contexto$color]] <- contexto$grupo
    capa
  })
}

#' El gráfico de un panel tal como lo dibuja la app, sin leerlo todavía:
#' list(grafico, encabezado, contexto). Lo comparten la tabla (`panel`) y la
#' figura (`panel --salida x.png`, lab/figuras.R), así que las dos miran el
#' mismo objeto.
grafico_de_panel <- function(ds, clave, columnas, opciones = list()) {
  if (!existe_artefacto(clave))
    stop("clave desconocida: ", clave, ". Ver: Rscript learn/R/lab.R casillas")
  if (grepl("^f[34][.]", clave)) return(grafico_de_panel_f4(ds, clave, opciones))
  receta <- RECETAS_F1[[clave]]
  nombre <- .lab_funcion(artefacto(clave)$grafico, clave, "grafico")
  grafico <- tryCatch(
    if (is.null(receta)) do.call(nombre, c(list(ds$df), as.list(columnas)))
    else receta(ds$df, columnas, opciones),
    error = function(e)
      stop(sprintf("%s(datos, %s) falló: %s\n  Probá con otras columnas.",
                   nombre, paste(columnas, collapse = ", "),
                   conditionMessage(e)), call. = FALSE))
  list(grafico = grafico, encabezado = sprintf("%s · %s", clave, nombre))
}

#' `R/graficos/x.R::graficar_y` -> "graficar_y", comprobando que esté cargada.
.lab_funcion <- function(referencia, clave, que) {
  if (is.null(referencia) || is.na(referencia))
    stop("el artefacto ", clave, " todavia no tiene ", que, " registrado")
  nombre <- sub("^.*::", "", referencia)
  if (!exists(nombre, mode = "function"))
    stop("la funcion ", nombre, " no esta cargada")
  nombre
}

# Cada receta repite lo que hace el renderPlot de su card. `x` es el contexto:
# ajuste, ejes, etiquetas de ejes, umbral, k_max y el color.
RECETAS_F4 <- list(
  "f4.diagnostico.scree" = function(a, x)
    graficar_scree(varianza_explicada(a), k = a$k, umbral = x$umbral,
                   reglas = reglas_k(a, x$umbral)),
  "f4.diagnostico.reglas_k" = function(a, x) reglas_k(a, x$umbral),
  "f4.diagnostico.ortogonalidad" = function(a, x)
    graficar_heatmap_correlacion(correlacion_puntuaciones(a)),
  "f4.diagnostico.codo" = function(a, x)
    graficar_codo(inercia_por_k(a, k_max = x$k_max), k = a$k),
  "f4.diagnostico.silueta" = function(a, x) graficar_silueta(silueta(a)),
  "f4.desempeno.grupos" = function(a, x) graficar_tamanos(resumen_grupos(a)),
  "f4.desempeno.cruce_clase" = function(a, x) {
    cruce <- cruce_con_clase(a, x$clase)
    cruce$eje_clase <- a$etiqueta_referencia
    cruce$eje_grupo <- a$etiqueta_particion
    graficar_cruce_clase(cruce)
  },
  "f4.diagnostico.dendrograma" = function(a, x)
    if (length(x$enlaces))
      graficar_enlaces_radial(arboles_por_enlace(a, x$enlaces))
    else graficar_dendrograma(arbol_jerarquico(a), etiquetas = x$hojas,
                              forma = x$forma),
  "f4.explicabilidad.cargas" = function(a, x)
    graficar_cargas(cargas(a, componentes = unique(x$ejes))),
  "f4.explicabilidad.contribuciones" = function(a, x)
    graficar_contribuciones(contribuciones(a, componentes = unique(x$ejes))),
  "f4.explicabilidad.circulo_correlaciones" = function(a, x)
    graficar_circulo(correlaciones_componentes(a, x$ejes), x$etiquetas,
                     sobre_correlacion = identical(a$matriz, "correlacion")),
  "f4.explicabilidad.calidad" = function(a, x)
    graficar_calidad(calidad_variables(a, x$ejes),
                     sobre_correlacion = identical(a$matriz, "correlacion")),
  "f4.explicabilidad.mapa_2d" = function(a, x)
    graficar_mapa_2d(coordenadas_2d(a, x$ejes, x$grupo), x$etiquetas,
                     color_nombre = x$color),
  "f4.explicabilidad.biplot" = function(a, x)
    graficar_biplot(coordenadas_biplot(a, x$ejes, x$grupo), x$etiquetas,
                    color_nombre = x$color),
  "f4.explicabilidad.centroides" = function(a, x)
    graficar_centroides(centroides_tabla(a)))

# Los paneles que pintan una fila por observación, en el orden del ajuste: a
# esos se les puede pegar el nombre de cada fila (el país, en el Taller 02).
PANELES_DE_INDIVIDUOS <- c("f4.explicabilidad.mapa_2d",
                           "f4.explicabilidad.biplot")

#' Un panel de las fases 3-4: ajusta, arma el contexto y llama la receta (o
#' el registro, si la clave no tiene receta). Con `--comparar` la clase de
#' referencia pasa a ser la partición del otro método (lab/figuras.R).
grafico_de_panel_f4 <- function(ds, clave, opciones = list()) {
  metodo <- metodo_para_clave(clave, opciones$metodo)
  if (!clave %in% metodo(metodo)$artefactos)
    message("[aviso] ", metodo, " no declara ", clave,
            ": la app no mostraría este panel")
  # Las `*_comparar` son del segundo ajuste y salen antes del primero: `$` de
  # una lista completa nombres parciales, y sin --semilla, `opciones$semilla`
  # devolvía la de --semilla_comparar.
  propias <- sin_opciones_de_comparacion(opciones)
  ajustado <- ajustar_cli(ds, metodo, propias,
                          .lab_hiper_para_ejes(metodo, propias))
  ajuste <- adjuntar_comparacion(ds, ajustado, opciones)
  contexto <- .lab_contexto_f4(ds, ajuste, propias)
  receta <- RECETAS_F4[[clave]] %||% RECETAS_F3[[clave]] %||%
    function(a, x) .lab_por_registro(clave, a, x)
  list(grafico = receta(ajuste, contexto), contexto = contexto,
       encabezado = sprintf("%s · %s · %s", clave, metodo,
                            texto_de_pares(ajustado$parametros)))
}

#' `--ejes 2,3` sobre un ACP que retiene dos componentes: la app no ofrece la
#' tercera, y acá se sube `n_componentes` a lo que piden los ejes —avisando—
#' salvo que se haya fijado a mano, en cuyo caso falla como fallaría allá.
.lab_hiper_para_ejes <- function(metodo, opciones) {
  hiper <- hiper_cli(metodo, opciones)
  defecto <- hiper_por_defecto(metodo)
  if (is.null(opciones$ejes) || !"n_componentes" %in% names(defecto) ||
      !is.null(hiper$n_componentes)) return(hiper)
  tope <- max(as.integer(strsplit(opciones$ejes, "[,-]")[[1]]))
  if (tope > defecto$n_componentes) {
    message(sprintf("[aviso] --ejes pide la componente %d: n_componentes=%d",
                    tope, tope))
    hiper$n_componentes <- tope
  }
  hiper
}

#' Lo que en la app ponen los controles de la subsección: ejes, umbral, K
#' máximo, color. Acá salen de las opciones, con los mismos defaults.
.lab_contexto_f4 <- function(ds, ajuste, opciones) {
  ejes <- if (is.null(opciones$ejes)) c(1L, 2L)
          else as.integer(strsplit(opciones$ejes, "[,-]")[[1]])
  nombres_ejes <- etiquetas_ejes(ajuste)
  # Las filas que entraron al ajuste: recortar a ellas el color y los nombres
  # es lo que hace f4/plano.R, y desalinearlos pintaría cada punto ajeno.
  completas <- stats::complete.cases(ds$df[, ajuste$columnas, drop = FALSE])
  color <- opciones$color
  list(ejes = ejes, etiquetas = nombres_ejes[pmin(ejes, length(nombres_ejes))],
       umbral = as.numeric(opciones$umbral %||% 0.8),
       k_max = as.integer(opciones$k_max %||% 10L), k = ajuste$k,
       color = color, hojas = if (!is.null(opciones$hojas))
         as.logical(toupper(opciones$hojas)),
       forma = opciones$forma %||% "rectangular",
       enlaces = if (!is.null(opciones$enlaces))
         trimws(strsplit(opciones$enlaces, ",", fixed = TRUE)[[1]]),
       grupo = if (!is.null(color)) ds$df[[color]][completas] else NULL,
       # La clase de referencia ya viene recortada en el ajuste (ajustar_cli).
       clase = ajuste$referencia,
       nombres = .lab_nombres_filas(ds)[completas])
}

#' El nombre de cada fila: la columna con rol `id` o, si no hay, la primera de
#' texto sin repetidos (Country en EIA). Sin ninguna, NULL.
.lab_nombres_filas <- function(ds) {
  dic <- ds$diccionario
  candidatas <- c(dic$columna[dic$rol %in% "id"],
                  names(ds$df)[vapply(ds$df, function(v)
                    is.character(v) && !anyDuplicated(v), TRUE)])
  if (!length(candidatas)) return(NULL)
  as.character(ds$df[[candidatas[1]]])
}

#' Sin receta: la lógica registrada sobre el ajuste y el gráfico registrado
#' sobre lo que devuelva, cada uno con los argumentos del contexto que su firma
#' declare. Así un artefacto nuevo funciona por consola sin tocar este archivo.
.lab_por_registro <- function(clave, ajuste, contexto) {
  registro <- artefacto(clave)
  logica <- .lab_funcion(registro$logica, clave, "logica")
  resultado <- .lab_llamar(logica, ajuste, contexto)
  if (is.null(registro$grafico) || is.na(registro$grafico)) return(resultado)
  .lab_llamar(.lab_funcion(registro$grafico, clave, "grafico"), resultado,
              contexto)
}

.lab_llamar <- function(nombre, primero, contexto) {
  acepta <- names(formals(get(nombre, mode = "function")))
  extra <- contexto[intersect(setdiff(names(contexto), "etiquetas"),
                              acepta[-1])]
  do.call(nombre, c(list(primero), extra))
}
