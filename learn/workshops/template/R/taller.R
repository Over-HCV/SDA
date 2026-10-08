# learn/workshops/template/R/taller.R
#
# Responsabilidad: lo que todo taller repite al armar el cuaderno.
#
# Se carga desde el chunk de configuración del .qmd:
#
#   source("../template/R/taller.R")
#
# Son dos familias: presentación (código y resultado lado a lado,
# paginación, tabla de documentación) y estadística descriptiva que el enunciado pide una y otra
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

#' Que LaTeX no parta lo que debe ir junto.
#'
#' Parte cada chunk de R en tramos (un bloque de código con la salida,
#' tabla o figura que le sigue) y antes de cada tramo emite
#' `\Needspace{alto}` (paquete needspace de taller-qmd-template.tex): Si
#' el tramo no cabe en lo que queda de página, empieza en la siguiente. Así
#' el código no queda al pie de una página con su salida en la otra, una
#' tabla corta no se parte y una salida larga (más de `tope` renglones)
#' empieza con aire. Es opcional: El taller que no la llame compila igual
#' que antes. Un chunk se excluye con `paginar = FALSE`.
#'
#' @param tope renglones máximos que se reservan para un tramo sin figura
#' @param renglon alto de un renglón de código o de salida, en pulgadas
paginar <- function(tope = 24, renglon = 0.19) {
  reservar <- function(alto) {
    if (alto <= 0) return(character(0))
    c("", "```{=latex}", sprintf("\\Needspace{%.2fin}", alto), "```", "")
  }
  alto_tramo <- function(l, fig_alto) {
    l <- l[nzchar(trimws(l)) & !grepl("^\\s*(```|:::)", l)]
    figura <- grepl("!\\[", l)
    tabla <- grepl("^\\s*\\||^Table:", l)
    renglones <- sum(!figura) + if (any(tabla)) 2 else 0
    if (any(figura)) min(fig_alto + 0.7 + renglones * renglon, 8.6)
    else min(renglones, tope) * renglon
  }
  # Un diagrama mermaid y su pie (que quarto deja como párrafo suelto)
  # van juntos. Alto estimado a 5.2 pulgadas de ancho: Uno de arriba
  # abajo mide unas 3.7; uno de izquierda a derecha, 0.72 por cada nodo
  # de la columna más poblada (la clase con más nodos).
  alto_mermaid <- function(codigo) {
    clases <- grep("^\\s*class ", codigo, value = TRUE)
    filas <- max(c(2, lengths(strsplit(clases, ","))))
    alto <- if (any(grepl("flowchart LR", codigo))) 0.72 * filas else 3.7
    alto + 0.6
  }
  previo <- knitr::knit_hooks$get("chunk")
  knitr::knit_hooks$set(chunk = function(x, options) {
    x <- previo(x, options)
    if (isFALSE(options$paginar)) return(x)
    if (tolower(options$engine) == "mermaid")
      return(paste(c(reservar(alto_mermaid(options$code)), x),
                   collapse = "\n"))
    if (tolower(options$engine) != "r") return(x)
    l <- unlist(strsplit(x, "\n"))
    # Un tramo empieza en cada bloque de código mostrado.
    inicio <- grepl("^```\\{?\\.?r[ }.]|^```r$", l)
    # Una salida "asis" (dos_columnas) va entera: Sus bloques de código
    # están dentro de minipages.
    if (identical(options$results, "asis")) inicio[] <- FALSE
    inicio[1] <- TRUE
    tramo <- cumsum(inicio)
    partes <- split(l, tramo)
    paste(unlist(lapply(partes, function(p) {
      # Una tabla corta no se parte aunque el código quede arriba.
      t <- which(grepl("^\\s*\\||^Table:", p))
      if (length(t))
        p <- append(p, reservar(min(length(t), tope) * renglon + 0.6),
                    after = t[1] - 1)
      c(reservar(alto_tramo(p, options$fig.height)), p)
    })), collapse = "\n")
  })
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
  # Los paquetes de CRAN que no vienen con R tienen su ayuda en rdrr.io.
  cran <- c("ggExtra", "factoextra", "GGally", "cluster", "ggrepel")
  url <- ifelse(
    funciones$paquete == "ggplot2",
    paste0("https://ggplot2.tidyverse.org/reference/", funciones$tema, ".html"),
    ifelse(funciones$paquete %in% cran,
           sprintf("https://rdrr.io/cran/%s/man/%s.html",
                   funciones$paquete, funciones$tema),
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
#'
#' @param cercas TRUE dibuja además las cercas de Tukey con su valor, que es lo
#'   que hay que mirar cuando la pregunta es si hay atípicos. Se calculan sobre
#'   las bisagras, igual que `boxplot()`, y por eso pueden diferir en décimas de
#'   los cuartiles anotados.
#' @param relleno color de la caja
caja <- function(variable, etiqueta, cercas = FALSE, relleno = "steelblue",
                 datos = get("datos", knitr::knit_global())) {
  x <- datos[[variable]]
  q <- quantile(x, c(0.25, 0.5, 0.75))
  grafico <- ggplot(data.frame(x), aes(x = x, y = "")) +
    geom_boxplot(fill = relleno, alpha = 0.5, outlier.colour = "firebrick") +
    annotate("text", x = q, y = 1.5, label = format(round(q, 2)),
             size = 3, check_overlap = TRUE)
  if (cercas) {
    b <- boxplot.stats(x)$stats
    limites <- c(b[2] - 1.5 * (b[4] - b[2]), b[4] + 1.5 * (b[4] - b[2]))
    grafico <- grafico +
      geom_vline(xintercept = limites, linetype = "dashed",
                 colour = "grey45", linewidth = 0.4) +
      annotate("text", x = limites, y = 0.62,
               label = format(round(limites, 2), trim = TRUE),
               size = 3, colour = "grey30")
  }
  # Las cercas caen en el borde del panel: sin aire, su rótulo se sale.
  grafico + scale_x_continuous(expand = expansion(mult = 0.08)) +
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
