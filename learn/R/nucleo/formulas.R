# learn/R/nucleo/formulas.R
#
# Responsabilidad: sacar las fórmulas del markdown antes de que commonmark las
# toque, y volver a ponerlas después convertidas en nodos que KaTeX reconoce.
#
# Por qué no basta con escribir `$$...$$` y dejar que pasen de largo:
# CommonMark se come la barra invertida doble. `\\` es el separador de filas de
# una matriz, así que un `\begin{pmatrix} a & b \\ c & d \end{pmatrix}` que
# atraviese el parser de markdown llega roto al navegador — sin error, sin
# aviso, solo mal. Lo mismo con `_`, que markdown lee como énfasis y que en TeX
# es un subíndice.
#
# Entonces: se extraen las fórmulas, se dejan marcadores alfanuméricos (que
# markdown no interpreta como nada), se convierte el resto, y se reinyecta el
# TeX literal dentro de nodos con clase. El renderizado lo hace KaTeX en el
# cliente; ver R/ui/piezas/formulas.R y learn/www/katex/.
#
# Todo lo de este archivo es PURO: entra texto, sale texto. Es la mitad de la
# cadena que se puede probar con Rscript, y por eso es donde vive la lógica.

# Alfanumérico a propósito: cualquier cosa con guiones bajos, asteriscos o
# barras sería markdown y volvería transformada.
.MARCA_FORMULA <- "zzsdaformula%dzz"

#' Saca las fórmulas del markdown y las reemplaza por marcadores.
#'
#' Reconoce `$$...$$` (bloque, puede ocupar varias líneas) y `$...$` (en línea).
#' Una fórmula en línea no puede empezar ni terminar con espacio: así
#' "cuesta $ 5 y $ 8" no se confunde con matemáticas.
#'
#' @return list(texto = markdown con marcadores, formulas = data.frame)
proteger_formulas <- function(md) {
  vacio <- data.frame(tex = character(0), bloque = logical(0),
                      stringsAsFactors = FALSE)
  if (is.null(md) || !nzchar(md)) return(list(texto = md, formulas = vacio))

  guardadas <- vacio
  guardar <- function(texto, patron, bloque) {
    posiciones <- gregexpr(patron, texto, perl = TRUE)[[1]]
    if (posiciones[1] == -1L) return(texto)
    encontradas <- regmatches(texto, gregexpr(patron, texto, perl = TRUE))[[1]]
    marcas <- character(length(encontradas))
    for (i in seq_along(encontradas)) {
      guardadas <<- rbind(guardadas, data.frame(
        tex = .desnudar_tex(encontradas[i], bloque), bloque = bloque,
        stringsAsFactors = FALSE))
      marcas[i] <- sprintf(.MARCA_FORMULA, nrow(guardadas))
    }
    regmatches(texto, gregexpr(patron, texto, perl = TRUE)) <- list(marcas)
    texto
  }

  # El bloque primero: si no, el patrón en línea partiría cada `$$` en dos.
  md <- guardar(md, "\\$\\$(?s).+?\\$\\$", TRUE)
  md <- guardar(md, "\\$(?![\\s$])[^\\n$]*?(?<![\\s$])\\$", FALSE)
  list(texto = md, formulas = guardadas)
}

#' Quita los delimitadores y el espacio sobrante de una fórmula capturada.
.desnudar_tex <- function(bruto, bloque) {
  n <- if (bloque) 2L else 1L
  trimws(substr(bruto, n + 1L, nchar(bruto) - n))
}

#' Devuelve las fórmulas al HTML, ya como nodos que KaTeX sabe encontrar.
#'
#' Una fórmula de bloque que quedó sola en su párrafo se lleva el `<p>` puesto:
#' un `<div>` dentro de un `<p>` es HTML inválido y el navegador lo reacomoda
#' por su cuenta, así que se reemplaza el párrafo entero.
restaurar_formulas <- function(html, formulas) {
  if (!length(formulas) || !nrow(formulas)) return(html)
  for (i in seq_len(nrow(formulas))) {
    marca <- sprintf(.MARCA_FORMULA, i)
    nodo <- .nodo_formula(formulas$tex[i], formulas$bloque[i])
    if (formulas$bloque[i])
      html <- gsub(paste0("<p>", marca, "</p>"), nodo, html, fixed = TRUE)
    html <- gsub(marca, nodo, html, fixed = TRUE)
  }
  html
}

#' El TeX literal dentro de un nodo con clase. Escapado, porque un `<` de TeX
#' partiría el HTML; el cliente lo recupera con textContent.
.nodo_formula <- function(tex, bloque) {
  escapado <- gsub("<", "&lt;", gsub("&", "&amp;", tex, fixed = TRUE),
                   fixed = TRUE)
  if (bloque)
    return(paste0("<div class=\"formula-bloque\">", escapado, "</div>"))
  paste0("<span class=\"formula-linea\">", escapado, "</span>")
}
