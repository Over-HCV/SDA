# app.R — punto de entrada para desplegar SDA Lab en un servidor R.
#
# Solo existe para el despliegue (Posit Connect Cloud, shinyapps.io, Shiny
# Server). En desarrollo se sigue usando:
#
#   Rscript -e 'shiny::runApp("learn/R/app.R", launch.browser = TRUE)'
#
# Por qué vive en la raíz del repo y no dentro de learn/: la app necesita tres
# cosas que están fuera de learn/ y que se comparten con el resto del repo —
# `data/`, `libs/_comun/R/` y el marcador de raíz. Al desplegar desde git, el
# servidor clona el repositorio entero, así que basta con que el directorio de
# trabajo sea la raíz. Mover esas carpetas dentro de learn/ las duplicaría:
# `notes/`, `workshops/` y `projects/` también las usan (S3 de libs/sdd.md).
#
# Por qué declara las librerías: el escáner de dependencias de rsconnect mira
# los archivos del bundle, y nuestras llamadas a library() viven dentro de
# R/cargar.R. Es la misma razón por la que learn/app.R las declara para
# shinylive — y el mismo defecto si se olvidan: se despliega sin paquetes.
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(bsicons)
  library(DT)
  library(ggplot2)
  library(commonmark)   # textos.R: markdown -> HTML
  library(jsonlite)     # exportar.R: contrato S2
})

# `$value` es obligatorio: source() devuelve list(value=, visible=) y Shiny
# exige que el último valor del archivo sea el shiny.appobj.
source("learn/R/app.R")$value
