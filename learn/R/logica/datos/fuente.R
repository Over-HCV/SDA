# learn/R/logica/datos/fuente.R
#
# Responsabilidad: convertir "elegí charcoal" en un data.frame listo para
# nuevo_dataset(), sin que la UI sepa de rutas ni de CSV.
#
# Los cargadores de verdad viven en libs/_comun/R/datos.R y no se duplican
# acá (cargar_charcoal, cargar_twins, pivot_paises, gen_sintetico). Lo que se
# añade es el catálogo: qué fuentes hay, cuánto pesan y cuáles conviene no
# tocar dentro del navegador sin avisar antes.

#' Catálogo de fuentes del curso.
#'
#' `diferida = TRUE` significa que no se lee hasta que el usuario lo pide y que
#' en wasm se muestra el peso antes: el panel crudo de charcoal son 35.115
#' filas y 2,7 MB inlinados en base64 dentro del bundle.
#'
#' @return data.frame(clave, nombre, descripcion, filas_aprox, diferida)
fuentes_disponibles <- function() {
  data.frame(
    clave = c("charcoal_crudo", "charcoal_pivot", "twins",
              "sintetico_anova", "sintetico_regresion"),
    nombre = c("charcoal · panel crudo", "charcoal · pais x anio",
               "twins", "sintetico · anova", "sintetico · regresion"),
    descripcion = c(
      "Produccion y comercio de carbon vegetal por pais, ano y flujo.",
      "Matriz pais x ano de un solo flujo, ya agregada.",
      "Gemelos: salario, educacion y controles. 16 variables numericas.",
      "k grupos normales con medias separadas por 'efecto'.",
      "Relacion cubica con ruido: la recta se queda corta a proposito."),
    filas_aprox = c(35113L, 145L, 182L, 100L, 100L),
    diferida = c(TRUE, TRUE, FALSE, FALSE, FALSE),
    stringsAsFactors = FALSE)
}

# Los cuatro flujos que se usan en clase, de los 31 del archivo. La lista
# completa sale de listar_flujos(), pero pedirla obliga a leer el CSV entero:
# justo lo que la carga diferida evita.
FLUJOS_SUGERIDOS <- c("Production", "Imports", "Exports",
                      "Consumption by households")

#' Aviso de peso previo a cargar, o NULL si la fuente es liviana.
#' En modo servidor no molesta a nadie; en wasm es información necesaria.
aviso_de_peso <- function(clave) {
  fila <- fuentes_disponibles()
  fila <- fila[fila$clave == clave, ]
  if (!nrow(fila) || !fila$diferida || !es_wasm()) return(NULL)
  sprintf(paste("%s trae unas %s filas y en el navegador tarda en abrir.",
                "Las metricas van sobre el total; los graficos usan muestra."),
          fila$nombre, format(fila$filas_aprox, big.mark = "."))
}

#' Carga una fuente del catálogo.
#'
#' @param semilla usada por las fuentes sintéticas (C13)
#' @return list(datos, fuente, avisos)
cargar_fuente <- function(clave, semilla = 42L, n = 100L, k_grupos = 4L,
                          efecto = 5, flujo = "Production") {
  avisos <- list()
  agregar <- function(mensaje, sugerencia = NA_character_)
    avisos[[length(avisos) + 1L]] <<-
      list(severidad = "aviso", mensaje = mensaje, sugerencia = sugerencia)

  datos <- switch(clave,
    charcoal_crudo = cargar_charcoal(),
    charcoal_pivot = {
      matriz <- pivot_paises(flujo = flujo)
      agregar(paste("pivot_paises() rellena con 0 los pares pais-anio sin",
                    "dato: no son ceros observados."),
              "Mirá el panel crudo si la ausencia importa.")
      cbind(data.frame(pais = rownames(matriz), stringsAsFactors = FALSE),
            as.data.frame(matriz))
    },
    twins = cargar_twins(),
    sintetico_anova = gen_sintetico(n = n, k_grupos = k_grupos, efecto = efecto,
                                    semilla = semilla, tipo = "anova"),
    sintetico_regresion = gen_sintetico(n = n, semilla = semilla,
                                        tipo = "regresion"),
    stop("fuente desconocida: ", clave))

  list(datos = datos, fuente = clave, avisos = avisos)
}

#' Lee un CSV subido por el usuario, con los cuatro parámetros que de verdad
#' cambian el resultado. Devuelve avisos en vez de fallar: un decimal mal
#' elegido no rompe la lectura, la vuelve inútil en silencio.
#'
#' @return list(datos, avisos)
leer_archivo_subido <- function(ruta, separador = ",", decimal = ".",
                                faltante = c("", "NA", "."),
                                codificacion = "UTF-8") {
  datos <- utils::read.csv(ruta, sep = separador, dec = decimal,
                           na.strings = faltante, fileEncoding = codificacion,
                           stringsAsFactors = FALSE, check.names = TRUE)
  avisos <- list()
  if (ncol(datos) == 1L)
    avisos <- c(avisos, list(list(
      severidad = "aviso", mensaje = "el archivo quedo en una sola columna",
      sugerencia = "Probá otro separador (; o tabulador).")))

  sospechosas <- names(datos)[vapply(datos, function(columna)
    is.character(columna) && all(grepl("^[-0-9.,]+$", stats::na.omit(columna))),
    logical(1))]
  if (length(sospechosas))
    avisos <- c(avisos, list(list(
      severidad = "aviso",
      mensaje = paste("parecen numericas pero se leyeron como texto:",
                      paste(sospechosas, collapse = ", ")),
      sugerencia = "Revisá el separador decimal.")))
  list(datos = datos, avisos = avisos)
}
