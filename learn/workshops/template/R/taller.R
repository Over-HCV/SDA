# learn/workshops/template/R/taller.R
#
# Responsabilidad: lo que todo taller repite al armar el cuaderno.
#
# Se carga desde el chunk de configuración del .qmd:
#
#   source("../template/R/taller.R")
#
# Son dos familias: presentación (código y resultado lado a lado, tabla de
# documentación) y estadística descriptiva que el enunciado pide una y otra
# vez (asimetría, cajas anotadas, densidades, modas). Todo depende de que el
# cuaderno tenga un data.frame llamado `datos`, que es el nombre que usa el
# cuaderno exportado por SDA Lab.

library(ggplot2)

# --- Presentación -----------------------------------------------------------

#' Código a la izquierda y su resultado a la derecha.
#'
#' Solo para instrucciones cuya salida es uno o dos números: una línea de
#' código y un `[1] 118` ocupando dos bloques enteros desperdician media
#' página. Usa el entorno `codres` de taller-qmd-template.tex, así que el
#' chunk debe ir con `echo=FALSE, results="asis"`.
#'
#' @param ... instrucciones como cadenas de texto; el salto de línea dentro de
#'   la cadena parte el código en la columna angosta
dos_columnas <- function(...) {
  for (codigo in c(...)) {
    salida <- capture.output({
      v <- withVisible(eval(parse(text = codigo),
                            envir = knitr::knit_global()))
      if (v$visible) print(v$value)
    })
    cat("\n```{=latex}\n\\begin{codres}\n```\n\n",
        "```r\n", codigo, "\n```\n\n",
        "```{=latex}\n\\codressep\n```\n\n",
        "```\n", paste(salida, collapse = "\n"), "\n```\n\n",
        "```{=latex}\n\\end{codres}\n```\n\n", sep = "")
  }
}

#' La tabla del apéndice: función, paquete, dónde se usó y su ayuda oficial.
#'
#' El enlace es el mismo que abre `?función`. Las de ggplot2 y ggExtra no
#' están en el manual de R, así que van a su propia referencia.
#'
#' @param funciones data.frame(f, paquete, tema, uso)
tabla_documentacion <- function(funciones) {
  manual <- function(paquete, tema) sprintf(
    "https://stat.ethz.ch/R-manual/R-devel/library/%s/html/%s.html",
    paquete, tema)
  url <- ifelse(
    funciones$paquete == "ggplot2",
    paste0("https://ggplot2.tidyverse.org/reference/", funciones$tema, ".html"),
    ifelse(funciones$paquete == "ggExtra",
           paste0("https://rdrr.io/cran/ggExtra/man/", funciones$tema, ".html"),
           manual(funciones$paquete, funciones$tema)))
  knitr::kable(
    data.frame(Función = sprintf("[`%s()`](%s)", funciones$f, url),
               Paquete = funciones$paquete, Uso = funciones$uso),
    caption = "Funciones de R utilizadas y enlace a su documentación.")
}

# --- Descriptiva ------------------------------------------------------------

#' Coeficiente de asimetría g1: negativo con cola a la izquierda.
g1 <- function(x) {
  d <- x - mean(x)
  mean(d^3) / mean(d^2)^(3/2)
}

#' Diagrama de caja horizontal con Q1, mediana y Q3 anotados.
#'
#' Sin las anotaciones, la lectura de la caja se hace a ojo y termina siendo
#' intuición; con ellas el número que se cita en el texto está en la figura.
caja <- function(variable, etiqueta, datos = get("datos", knitr::knit_global())) {
  x <- datos[[variable]]
  q <- quantile(x, c(0.25, 0.5, 0.75))
  ggplot(data.frame(x), aes(x = x, y = "")) +
    geom_boxplot(fill = "steelblue", alpha = 0.5,
                 outlier.colour = "firebrick") +
    annotate("text", x = q, y = 1.5, label = format(round(q, 2)),
             size = 3, check_overlap = TRUE) +
    labs(x = etiqueta, y = NULL) + theme_minimal()
}

#' Histograma de densidad (clases de Sturges) con la KDE encima.
#'
#' El subtítulo trae el ancho de banda de Silverman, que es el que hay que
#' justificar al describir la curva.
densidad <- function(variable, etiqueta, color,
                     datos = get("datos", knitr::knit_global())) {
  x <- datos[[variable]]
  ggplot(datos, aes(x = .data[[variable]])) +
    geom_histogram(aes(y = after_stat(density)),
                   bins = nclass.Sturges(x), fill = color,
                   colour = "black", alpha = 0.5) +
    geom_density(colour = "black", linewidth = 1) +
    labs(x = etiqueta, y = "Densidad",
         subtitle = sprintf("h (Silverman) = %.3f", bw.nrd0(x))) +
    theme_minimal()
}

#' Dónde están las modas de la KDE.
#'
#' `ajuste = 2` duplica el ancho de banda: una moda que no sobrevive a eso es
#' ruido del suavizado y no se reporta como hallazgo.
modas <- function(x, ajuste = 1) {
  k <- density(x, adjust = ajuste)
  round(k$x[which(diff(sign(diff(k$y))) == -2) + 1], 2)
}
