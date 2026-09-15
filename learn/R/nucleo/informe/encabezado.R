# learn/R/nucleo/informe/encabezado.R
#
# Responsabilidad: el YAML del cuaderno de exploración.
#
# Son dos documentos distintos con el mismo cuerpo: el de estudio abre en el
# navegador y el del taller entra a la plantilla LaTeX de la universidad. Lo
# único que cambia entre ellos es este encabezado, así que vive aparte.

#' El YAML del cuaderno, en una de sus dos formas.
#'
#' Con `plantilla_taller` sale el del entregable: quarto lo compone con
#' `template/taller-qmd-template.tex` (portada, resumen e índice de la
#' universidad) y los campos que solo sabe quien entrega quedan vacíos. Sin
#' esa pieza sale el de estudio, que abre en el navegador sin más.
.encabezado_exploracion <- function(dataset, opciones) {
  nombre <- if (is.null(dataset)) "sin dataset" else dataset$nombre
  intro <- if (incluye(opciones, "marco")) c(
    "",
    "Cuaderno generado desde SDA Lab. Cada sección corresponde a un panel marcado",
    "con la casilla **Añadir**: trae su texto explicativo, los parámetros con que",
    "se produjo y el código R que lo redibuja sobre `datos`.") else NULL
  if (!incluye(opciones, "plantilla_taller")) return(.bloque(
    "---",
    'title: "Exploración de datos · SDA Lab"',
    sprintf('subtitle: "%s"', nombre),
    sprintf('date: "%s"', format(Sys.time(), "%Y-%m-%d %H:%M")),
    "output:",
    "  html_document:",
    "    toc: true",
    "    toc_float: true",
    "    number_sections: true",
    "---",
    intro))
  .bloque(
    "---",
    sprintf('title: "Taller --- exploración de %s"', nombre),
    'subtitle: "Análisis Estadístico de Datos"',
    sprintf('fecha: "Bogotá D.C., %s"', .fecha_en_espanol()),
    "resumen: |",
    "  (Resumen del taller: qué base, qué se hizo y qué se encontró.)",
    'palabras: "(Palabras clave separadas por punto y coma)"',
    "format:",
    "  latex:",
    "    template: ../template/taller-qmd-template.tex",
    "    keep-tex: true",
    "    top-level-division: chapter",
    "    df-print: kable",
    "execute:",
    "  echo: true",
    "  warning: false",
    "  message: false",
    "---",
    intro)
}

MESES_ES <- c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
              "agosto", "septiembre", "octubre", "noviembre", "diciembre")

.fecha_en_espanol <- function(hoy = Sys.Date())
  sprintf("%d de %s de %s", as.integer(format(hoy, "%d")),
          MESES_ES[as.integer(format(hoy, "%m"))], format(hoy, "%Y"))
