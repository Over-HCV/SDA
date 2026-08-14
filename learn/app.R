# learn/app.R
#
# Wrapper que exige shinylive::export(): tiene que haber un app.R en la raíz
# del directorio exportado. El cableado real vive en R/app.R.
#
# --- Por qué este archivo declara librerías -------------------------------
# shinylive detecta qué paquetes meter en el bundle escaneando llamadas a
# `library()` y `pkg::` en la RAÍZ del directorio de la app, sin recorrer
# subcarpetas. Nuestras llamadas viven en R/cargar.R, así que con un wrapper
# de una sola línea el escaneo encontraba cero dependencias, el bundle salía
# sin paquetes y webR moría con una lluvia de "preload error: Downloading
# webR package: ...".
#
# Estas llamadas no son decorativas: son las mismas que hace
# cargar_librerias_ui(), solo que adelantadas para que el escáner las vea.
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(bsicons)
  library(DT)
  library(ggplot2)
  library(commonmark)   # textos.R: markdown -> HTML
  library(jsonlite)     # exportar.R: contrato S2
})

# `$value` es obligatorio. Shiny evalúa este archivo y exige que el ÚLTIMO
# valor sea el shiny.appobj; source() devuelve list(value=, visible=), así que
# sin `$value` el bundle muere con "app.R did not return a shiny.appobj".
# Fue uno de los seis defectos que destapó correr el bundle de libs/shiny-live.
source("R/app.R")$value
