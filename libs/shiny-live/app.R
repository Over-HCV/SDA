# libs/shiny-live/app.R
#
# Wrapper requerido por shinylive::export(): debe haber un app.R en la raíz
# del directorio exportado. Este simplemente delega en R/app.R, que es donde
# vive el cableado real (UI + módulos + bootstrap).
# `$value` es obligatorio: shiny evalúa este archivo y exige que el ÚLTIMO
# valor sea el shiny.appobj. source() devuelve list(value=, visible=), así que
# sin `$value` el bundle falla con "app.R did not return a shiny.appobj".
source("R/app.R")$value
