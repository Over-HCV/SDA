# learn/R/nucleo/tema_app.R
#
# Responsabilidad: elegir un tema que funcione en los dos modos de ejecución.
#
# Por qué no se usa `tema()` de libs/_comun/R/temas_bslib.R directamente:
# esa función llama a `font_google()`, que descarga la fuente la primera vez y
# la cachea en disco. Dentro de webR no hay ni red garantizada ni disco
# persistente, así que la app se colgaría al construir el tema — antes de
# pintar nada, y sin un error legible.
#
# Los presets de bootswatch, en cambio, vienen empaquetados dentro de bslib:
# funcionan sin red y sin caché. En navegador se usan esos.

#' Tema inicial, seguro en ambos modos.
tema_seguro <- function(nombre = "flatly") {
  if (!es_wasm()) return(tema(nombre))
  bslib::bs_theme(bootswatch = .bootswatch_equivalente(nombre))
}

#' Cambio de tema en runtime, seguro en ambos modos.
cambiar_tema_seguro <- function(session, nombre) {
  if (!es_wasm()) return(cambiar_tema(session, nombre))
  session$setCurrentTheme(tema_seguro(nombre))
  shiny::showNotification(sprintf("Tema: %s", nombre), type = "message",
                          duration = 2)
  invisible(nombre)
}

#' Los presets propios del curso ("retro") son SCSS más una fuente de Google.
#' En navegador se sustituyen por el bootswatch más parecido y se avisa en la
#' notificación, en vez de fallar en silencio con un tema a medias.
.bootswatch_equivalente <- function(nombre) {
  equivalencias <- c(retro = "sandstone", `retro-dark` = "darkly")
  if (nombre %in% names(equivalencias)) return(equivalencias[[nombre]])
  nombre
}

#' Temas ofrecidos en el navbar. En wasm se ocultan los que no se pueden
#' construir tal cual, porque ofrecer algo que va a salir distinto es peor que
#' no ofrecerlo.
temas_disponibles <- function() {
  todos <- listar_temas()
  if (!es_wasm()) return(todos)
  setdiff(todos, c("retro", "retro-dark"))
}
