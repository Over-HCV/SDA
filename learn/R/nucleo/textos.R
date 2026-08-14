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
#   textos/<clave-artefacto>.md   qué muestra / qué buscar / cuándo engaña
#   fichas/<clave-metodo>.md      qué es / por qué / supone / falla si

#' Lee un markdown de la app. NULL si no existe.
#' @param relativa ruta relativa a learn/. Ej: "textos/f1.analisis.hist.md"
leer_md <- function(relativa) {
  ruta <- ruta_app(relativa)
  if (!file.exists(ruta)) return(NULL)
  paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

#' Markdown -> HTML. Sin dependencias nuevas: commonmark ya está en renv.
md_a_html <- function(md) {
  if (is.null(md) || !nzchar(md)) return("")
  commonmark::markdown_html(md, extensions = TRUE, smart = TRUE)
}

.AVISO_SIN_TEXTO <- paste0(
  "<p class='text-muted small mb-0'>Sin texto todavía. ",
  "Escribilo en <code>%s</code> con los bloques ",
  "<em>Qué muestra</em> / <em>Qué buscar</em> / ",
  "<em>Cuándo engaña</em>.</p>")

#' Texto explicativo de un artefacto, como HTML listo para la UI.
#' @param clave clave de artefacto. Ej: "f1.analisis.histograma"
texto <- function(clave) {
  relativa <- if (existe_artefacto(clave)) artefacto(clave)$texto
              else ruta_texto_de(clave)
  md <- leer_md(relativa)
  if (is.null(md)) return(sprintf(.AVISO_SIN_TEXTO, file.path("learn", relativa)))
  md_a_html(md)
}

#' ¿Hay texto escrito para esta clave?
hay_texto <- function(clave) {
  relativa <- if (existe_artefacto(clave)) artefacto(clave)$texto
              else ruta_texto_de(clave)
  file.exists(ruta_app(relativa))
}

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
