# learn/R/logica/metricas.R
#
# Responsabilidad: declarar las cinco preguntas que la app le hace a CUALQUIER
# ajuste, sin saber de qué método viene.
#
# Hasta el hito 3 no hacía falta: con un solo método, "las métricas de la
# corrida" y "las métricas del ACP" eran lo mismo, y `metricas_de_corrida()`
# leía `ajuste$varianza_explicada` directamente. Con el segundo método eso deja
# de funcionar, y la fase 4 se llenaría de `if (metodo == "acp")`.
#
# La solución es despacho S3 sobre el objeto de ajuste: cada `ajustar_*()`
# devuelve su lista con clase `c("ajuste_<clave>", "ajuste_sda")` y contesta
# estas cinco preguntas en su archivo de familia (`metricas_reduccion.R`,
# `metricas_grupos.R`). La UI no pregunta de qué método es; pregunta qué mide.
#
# El default falla a propósito: un ajuste sin clase es un método a medio
# escribir, y una vista vacía lo escondería hasta que alguien mire el JSON.

#' Las métricas de la corrida, como lista plana con nombre.
#' Van al JSON (S2), a las value boxes de la fase 4 y al bloque de contexto.
metricas_de_corrida <- function(ajuste) UseMethod("metricas_de_corrida")

#' Las observaciones en un plano de dos dimensiones.
#' @return data.frame(fila, x, y, grupo)
coordenadas_2d <- function(ajuste, ...) UseMethod("coordenadas_2d")

#' La tabla que hay detrás del resultado principal: lo que se exporta a CSV.
tabla_resultado <- function(ajuste) UseMethod("tabla_resultado")

#' El gráfico que resume la corrida cuando solo cabe uno (batch, informe).
grafico_resultado <- function(ajuste, ...) UseMethod("grafico_resultado")

#' Lo que va a la franja de estado: pares nombre → valor ya formateados.
resumen_ajuste <- function(ajuste) UseMethod("resumen_ajuste")

#' Cómo se llaman los ejes que esta familia sabe dibujar, en orden.
#' El ACP tiene tantos como componentes retenidas; una partición tiene dos, que
#' son un dibujo y no un resultado.
etiquetas_ejes <- function(ajuste) UseMethod("etiquetas_ejes")

#' La frase que interpreta el resultado, con los números a la vista para que se
#' pueda discutir. Dice qué haría falta; no decide por nadie.
lectura_resultado <- function(ajuste, ...) UseMethod("lectura_resultado")

metricas_de_corrida.default <- function(ajuste) .sin_familia("metricas_de_corrida", ajuste)
coordenadas_2d.default      <- function(ajuste, ...) .sin_familia("coordenadas_2d", ajuste)
tabla_resultado.default     <- function(ajuste) .sin_familia("tabla_resultado", ajuste)
grafico_resultado.default   <- function(ajuste, ...) .sin_familia("grafico_resultado", ajuste)
resumen_ajuste.default      <- function(ajuste) .sin_familia("resumen_ajuste", ajuste)
lectura_resultado.default   <- function(ajuste, ...) .sin_familia("lectura_resultado", ajuste)
etiquetas_ejes.default      <- function(ajuste) .sin_familia("etiquetas_ejes", ajuste)

.sin_familia <- function(generica, ajuste) {
  stop(sprintf(paste("%s() no sabe leer un ajuste de clase '%s'.",
                     "Su funcion ajustar_*() tiene que devolver la lista con",
                     "class = c('ajuste_<clave>', 'ajuste_sda') y declarar el",
                     "metodo en su archivo de familia de logica/."),
               generica, paste(class(ajuste), collapse = "/")))
}
