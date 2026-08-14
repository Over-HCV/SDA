# learn/R/ui/f2/modelado.R
#
# Fase 2 · Modelado. Elegir la familia de hipótesis y configurarla.
#
# Hito 1: la subsección Catálogo es real (catalogo.R); las otras cuatro están
# navegables y vacías.

SUBSECCIONES_MODELADO <- c("Catálogo", "Especificación", "Supuestos",
                           "Hiperparámetros", ETIQUETA_ANALISIS)

DETALLE_MODELADO <- list(
  "Especificación" = paste("Constructor de fórmula (y ~ x1 + x2 + x1:x2) o",
                           "selección de bloques X / Y, con la matriz de",
                           "diseño resultante a la vista."),
  "Supuestos" = paste("El checklist propio del método, evaluado sobre el",
                      "dataset actual ANTES de ajustar, con semáforo por",
                      "supuesto y el gráfico que lo prueba al lado."),
  "Hiperparámetros" = paste("Los del modelo, no los del ajuste. El formulario",
                            "se genera desde el catálogo, así que no puede",
                            "desincronizarse de la función de ajuste (C11)."))
DETALLE_MODELADO[[ETIQUETA_ANALISIS]] <- paste(
  "Geometría del modelo ANTES de ajustarlo: espacio de hipótesis, modelo",
  "manual donde vos movés los parámetros y ves subir el error, superficie de",
  "pérdida y presupuesto de parámetros. Acá el optimizador sos vos; la fase 3",
  "muestra cómo lo hace la máquina.")

mod_modelado_ui <- function(id) {
  ns <- shiny::NS(id)
  pendientes <- lapply(SUBSECCIONES_MODELADO[-1], function(titulo)
    panel_pendiente(titulo, "Hito 3", DETALLE_MODELADO[[titulo]]))
  subsecciones <- c(list("Catálogo" = salida_catalogo(ns)),
                    stats::setNames(pendientes, SUBSECCIONES_MODELADO[-1]))

  armazon_fase(controles = controles_catalogo(ns),
               subsecciones = subsecciones,
               id_pestanas = ns("pestana"))
}

mod_modelado_server <- function(id, almacen = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    servidor_catalogo(input, output, session)
  })
}
