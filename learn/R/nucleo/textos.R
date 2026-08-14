# learn/R/nucleo/textos.R
#
# Responsabilidad: leer los textos explicativos desde disco y convertirlos a
# HTML (C6, los textos viven fuera del código).
#
# Regla dura: si el .md no existe, esto devuelve un aviso discreto y NO falla.
# Los textos son cientos y se escriben poco a poco; una vista rota por un
# archivo que falta sería un castigo absurdo.
#
# Dos familias:
#   textos/<clave-artefacto>.md   para qué sirve / qué muestra / qué buscar /
#                                 cuándo engaña
#   fichas/<clave-metodo>.md      qué es / por qué / supone / falla si
#
# Los bloques del artefacto no se muestran juntos: "Para qué sirve" es la
# respuesta corta que va al sello ⓘ del encabezado, y los otros tres son la
# lectura larga que vive plegada en el pie. Por eso hace falta partir el .md
# por encabezado en vez de volcarlo entero.

#' Lee un markdown de la app. NULL si no existe.
#' @param relativa ruta relativa a learn/. Ej: "textos/f1.analisis.hist.md"
leer_md <- function(relativa) {
  ruta <- ruta_app(relativa)
  if (!file.exists(ruta)) return(NULL)
  paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

#' Markdown -> HTML, con las fórmulas a salvo del parser.
#'
#' Punto único de conversión: textos, fichas y el bloque del sello ⓘ pasan
#' todos por acá, así que las matemáticas funcionan igual en los tres sin que
#' ninguna vista tenga que acordarse. Ver R/nucleo/formulas.R.
md_a_html <- function(md) {
  if (is.null(md) || !nzchar(md)) return("")
  protegido <- proteger_formulas(md)
  html <- commonmark::markdown_html(protegido$texto, extensions = TRUE,
                                    smart = TRUE)
  restaurar_formulas(html, protegido$formulas)
}

# ---------------------------------------------------------------------------
# Partir un markdown en bloques
# ---------------------------------------------------------------------------

#' El bloque que va al sello ⓘ y NO se muestra en "¿Cómo se lee?".
BLOQUE_UTILIDAD <- "Para qué sirve"

#' Parte un markdown por sus encabezados de nivel 2.
#'
#' Un `##` dentro de una valla de código es código, no un encabezado: por eso
#' se lleva la cuenta de las vallas en vez de mirar solo el principio de línea.
#'
#' Lo que venga antes del primer `##` se devuelve bajo el nombre `""`. Un .md
#' sin encabezados devuelve un solo elemento con todo, y así un texto viejo de
#' tres bloques —o de ninguno— sigue funcionando sin tocarlo.
#'
#' @return lista con nombre: título del bloque -> su markdown, sin el `##`.
bloques_md <- function(md) {
  if (is.null(md) || !nzchar(md)) return(list())
  lineas <- strsplit(md, "\n", fixed = TRUE)[[1]]
  en_valla <- cumsum(grepl("^\\s*```", lineas)) %% 2L == 1L
  es_titulo <- grepl("^##\\s+\\S", lineas) & !en_valla

  grupo <- cumsum(es_titulo)
  nombres <- c("", trimws(sub("^##\\s+", "", lineas[es_titulo])))
  partido <- split(lineas[!es_titulo], grupo[!es_titulo])

  bloques <- lapply(seq_along(nombres) - 1L, function(i) {
    .recortar_vacias(partido[[as.character(i)]])
  })
  names(bloques) <- nombres
  Filter(function(x) nzchar(x), bloques)
}

#' Quita las líneas en blanco de los extremos y vuelve a pegar.
.recortar_vacias <- function(lineas) {
  if (is.null(lineas)) return("")
  con_texto <- which(nzchar(trimws(lineas)))
  if (!length(con_texto)) return("")
  paste(lineas[min(con_texto):max(con_texto)], collapse = "\n")
}

#' Vuelve a armar un markdown a partir de bloques con nombre.
.rearmar_md <- function(bloques) {
  if (!length(bloques)) return("")
  piezas <- vapply(names(bloques), function(nombre) {
    if (!nzchar(nombre)) return(bloques[[nombre]])
    paste0("## ", nombre, "\n\n", bloques[[nombre]])
  }, character(1))
  paste(piezas, collapse = "\n\n")
}

# ---------------------------------------------------------------------------
# Textos de artefacto
# ---------------------------------------------------------------------------

.AVISO_SIN_TEXTO <- paste0(
  "<p class='text-muted small mb-0'>Sin texto todavía. ",
  "Escribilo en <code>%s</code> con los bloques ",
  "<em>Para qué sirve</em> / <em>Qué muestra</em> / <em>Qué buscar</em> / ",
  "<em>Cuándo engaña</em>.</p>")

.AVISO_SIN_BLOQUE <- paste0(
  "<p class='text-muted small mb-0'>Falta el bloque <em>%s</em>. ",
  "Escribilo en <code>%s</code>.</p>")

#' Ruta relativa del .md de un artefacto, esté registrado o no.
.ruta_texto <- function(clave) {
  if (existe_artefacto(clave)) artefacto(clave)$texto else ruta_texto_de(clave)
}

#' Texto explicativo de un artefacto, como HTML listo para la UI.
#'
#' Devuelve TODO menos el bloque de utilidad: ese se pide aparte con
#' `texto_bloque()` y se pinta en el sello ⓘ. Mostrarlo dos veces era
#' exactamente el problema que este reparto viene a arreglar.
#'
#' @param clave clave de artefacto. Ej: "f1.analisis.histograma"
texto <- function(clave) {
  relativa <- .ruta_texto(clave)
  md <- leer_md(relativa)
  if (is.null(md)) return(sprintf(.AVISO_SIN_TEXTO, file.path("learn", relativa)))
  bloques <- bloques_md(md)
  md_a_html(.rearmar_md(bloques[setdiff(names(bloques), BLOQUE_UTILIDAD)]))
}

#' Un bloque suelto del texto de un artefacto, como HTML.
#'
#' Si el .md o el bloque no existen devuelve un aviso discreto, nunca falla:
#' los textos se escriben poco a poco y una card no puede romperse por eso.
texto_bloque <- function(clave, titulo = BLOQUE_UTILIDAD) {
  relativa <- .ruta_texto(clave)
  bloque <- bloques_md(leer_md(relativa))[[titulo]]
  if (is.null(bloque))
    return(sprintf(.AVISO_SIN_BLOQUE, titulo, file.path("learn", relativa)))
  md_a_html(bloque)
}

#' ¿Hay texto escrito para esta clave?
hay_texto <- function(clave) file.exists(ruta_app(.ruta_texto(clave)))

.AVISO_SIN_FICHA <- paste0(
  "<p class='text-muted small mb-0'>Ficha pendiente. ",
  "Escribila en <code>%s</code>.</p>")

#' Ficha completa de un método, como HTML.
#' @param clave clave de método. Ej: "acp"
ficha <- function(clave) {
  relativa <- if (existe_metodo(clave)) metodo(clave)$ficha
              else file.path("fichas", paste0(clave, ".md"))
  md <- leer_md(relativa)
  if (is.null(md)) return(sprintf(.AVISO_SIN_FICHA, file.path("learn", relativa)))
  md_a_html(md)
}

hay_ficha <- function(clave) {
  relativa <- if (existe_metodo(clave)) metodo(clave)$ficha
              else file.path("fichas", paste0(clave, ".md"))
  file.exists(ruta_app(relativa))
}

#' Cobertura de textos y fichas: cuántos escritos sobre cuántos esperados.
#' Alimenta el Inicio y sirve de recordatorio de deuda pedagógica.
cobertura_textos <- function() {
  artefactos <- claves_artefactos()
  metodos_visibles <- claves_metodos()
  list(
    textos_escritos  = sum(vapply(artefactos, hay_texto, logical(1))),
    textos_esperados = length(artefactos),
    fichas_escritas  = sum(vapply(metodos_visibles, hay_ficha, logical(1))),
    fichas_esperadas = length(metodos_visibles)
  )
}
