# learn/R/ui/piezas/formulas.R
#
# Responsabilidad: llevar KaTeX a la página, una sola vez.
#
# La mitad pura de las fórmulas está en R/nucleo/formulas.R: ahí se saca el TeX
# del markdown y se deja en nodos con clase. Acá solo se declara la dependencia
# que el navegador necesita para pintarlos.
#
# Va como htmlDependency y no como tags$script para no inventar nada: es el
# mismo mecanismo por el que bslib y bsicons ya llegan al bundle wasm, con la
# deduplicación y las rutas resueltas por htmltools.

VERSION_KATEX <- "0.16.11"

#' Dependencia de KaTeX. Se engancha una vez, en el `header` de page_navbar.
dependencia_formulas <- function() {
  htmltools::htmlDependency(
    name = "katex-sda",
    version = VERSION_KATEX,
    src = c(file = ruta_app("www", "katex")),
    script = c("katex.min.js", "enganche.js"),
    stylesheet = "katex.min.css",
    # Las fuentes las pide katex.min.css por ruta relativa; all_files las
    # arrastra al bundle. Sin esto el CSS llega y las fuentes no.
    all_files = TRUE
  )
}
