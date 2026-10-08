# learn/R/lab.R
#
# Responsabilidad: hacer el laboratorio DESDE LA CONSOLA, sin navegador.
#
# La app es la forma de mirar; esta es la forma de preguntar por escrito. Sirve
# para responder un taller sin abrir Shiny, para comprobar en dos segundos lo
# que un panel dice, y para que un agente o un script puedan recorrer las
# fases igual que una persona recorre las pestañas: la 1 sobre el dataset, y
# la 2-4 ajustando un método del catálogo por el mismo camino que run_headless.
#
# La regla que la hace útil: **un gráfico se devuelve como su TABLA**. `panel`
# construye el mismo ggplot que pinta la app y en vez de dibujarlo imprime las
# capas ya calculadas — los bordes y las alturas del histograma, los bigotes de
# la caja, los puntos de la nube. Es la misma información que uno lee del
# dibujo, en un formato que se puede leer sin ojos.
#
# Uso, desde la raíz del repo:
#
#   Rscript learn/R/lab.R fuentes
#   Rscript learn/R/lab.R datos --fuente ori          # --fuente es obligatorio
#   Rscript learn/R/lab.R resumen Temperatura --fuente ori --filtro Hora=12:00
#   Rscript learn/R/lab.R atipicos Presion --fuente ori --filtro Hora=12:00
#   Rscript learn/R/lab.R asociacion Temperatura Velocidad_del_Viento \
#     --fuente ori --filtro Hora=12:00
#   Rscript learn/R/lab.R panel f1.analisis.histograma Temperatura \
#     --fuente ori --filtro Hora=12:00
#   Rscript learn/R/lab.R cuaderno \
#     f1.analisis.boxplot:Temperatura,\
#     f1.analisis.dispersion:Temperatura+Velocidad_del_Viento+marginales=TRUE \
#     --fuente ori --filtro Hora=12:00 --salida taller.Rmd
#   Rscript learn/R/lab.R sesion f1.analisis.boxplot:Temperatura \
#     --fuente ori --filtro Hora=12:00 --salida sesion.json
#   Rscript learn/R/lab.R cuaderno --sesion sesion.json --salida taller.Rmd
#
# Fases 2-4 (Taller 02: EIA sin los cuatro países atípicos):
#
#   EIA="--fuente eia --filtro Country!=UnitedStates,China,SaudiArabia,Russia"
#   Rscript learn/R/lab.R momentos Col_a Col_b Col_c $EIA     # x̄ y S
#   Rscript learn/R/lab.R metodo acp --hiper matriz=covarianza $EIA
#   Rscript learn/R/lab.R metodo kmeans --hiper k=3 --columnas a,b,c $EIA
#   Rscript learn/R/lab.R panel f4.diagnostico.scree --metodo acp $EIA
#   Rscript learn/R/lab.R panel f4.explicabilidad.mapa_2d --metodo acp \
#     --ejes 2,3 --color grupo --grupos kmeans --hiper k=3 $EIA
#   Rscript learn/R/lab.R panel f1.analisis.boxplot_grupos Col_a grupo \
#     --grupos kmeans --hiper k=3 $EIA
#   Rscript learn/R/lab.R cuaderno \
#     f4.explicabilidad.contribuciones:metodo=acp+ejes=1-2+top=30,\
#     f4.diagnostico.scree:metodo=acp+matriz=covarianza $EIA
#
# `--filtro Columna!=a,b` saca esas filas en vez de conservarlas. `--hiper
# nombre=valor` se repite y cada método se lleva los nombres que declara;
# `--grupos <metodo>` ajusta ese método antes del comando y deja la columna
# `grupo` (el traspaso ② → ①). `--reinicios` y `--semilla` son el control del
# optimizador; `--ejes`, `--umbral`, `--k_max` y `--color` los controles de
# la subsección de la fase 4.
#
# Una SESIÓN (nucleo/sesion.R) es fuente + pila + diccionario + paneles
# marcados. `--sesion archivo.json` arma el dataset desde ella, así que la
# misma configuración sirve por consola y abriendo la app con
# `?sesion=...`: se guarda una vez y se reusa.
#
# `--incluir` y `--excluir` prenden y apagan piezas del cuaderno (texto del
# panel, procedencia, tablas de estado, YAML de la plantilla: ver
# informe/opciones.R), sobre las de fábrica o las de la sesión. `--texto
# completo|breve|ninguno` es el atajo viejo para las dos piezas de texto.
#
# En `cuaderno`, lo que va tras los dos puntos son los parámetros del panel:
# columnas separadas por `+`, y opciones con nombre como `normal=TRUE`. Son los
# mismos que en la app fijan los controles del sidebar.
#
# Las opciones `--fuente` y `--filtro` arman el dataset ANTES de cada comando y
# se pueden repetir: `--filtro Hora=12:00 --filtro Region=ORI` encadena dos, en
# orden, igual que la pila de la subsección Filtro.

local({
  candidatos <- c("learn/R/cargar.R", "R/cargar.R")
  ruta <- candidatos[file.exists(candidatos)]
  if (!length(ruta)) stop("corre esto desde la raiz del repo (ver AGENT.md)")
  source(ruta[1])
})

# Las piezas del CLI viven en learn/R/lab/ (C2). Se sourcean desde acá y no
# desde cargar_sda(): la consola no es una capa de la app ni viaja al bundle.
for (.archivo_lab in sort(list.files(ruta_app("R", "lab"), "[.][Rr]$",
                                     full.names = TRUE)))
  source(.archivo_lab)
rm(.archivo_lab)

# --- Comandos ---------------------------------------------------------------

#' Cada comando recibe (ds, posicionales[, opciones]) y devuelve algo
#' imprimible. Los que declaran el tercer argumento reciben las opciones.
COMANDOS <- list(

  fuentes = function(ds, args) fuentes_disponibles()[, c("clave", "nombre",
                                                         "filas_aprox")],

  datos = function(ds, args) {
    cat(sprintf("%s · %d filas × %d columnas\n", ds$nombre, ds$n, ds$p))
    for (entrada in ds$transformaciones)
      cat("  pila:", describir_transformacion(entrada), "\n")
    # `args[1]` es NA sin posicional, y `%||%` solo atrapa NULL.
    utils::head(ds$df, as.integer(.arg(args, 1L, "10")))
  },

  diccionario = function(ds, args)
    ds$diccionario[, c("columna", "escala", "clase", "n_unicos",
                       "faltantes_pct")],

  resumen = function(ds, args) {
    columna <- .exigir(args[1], "resumen <columna>")
    resumir_variable(ds$df[[columna]], .escala_cli(ds, columna))
  },

  frecuencias = function(ds, args)
    resumir_balance(ds$df, .exigir(args[1], "frecuencias <columna>")),

  atipicos = function(ds, args) {
    columna <- .exigir(args[1], "atipicos <columna> [metodo] [umbral]")
    metodo <- .arg(args, 2L, "iqr")
    tabla <- detectar_atipicos(ds$df, columna, metodo,
                              as.numeric(.arg(args, 3L, "1.5")))
    corte <- attr(tabla, "corte")
    cat(sprintf("%s · %d atipicos de %d por %s · corte %s\n", columna,
                attr(tabla, "n_atipicos"), nrow(tabla), metodo,
                paste(round(corte, 4), collapse = " a ")))
    # La tabla del panel trae una fila por observación; acá interesa el
    # subconjunto marcado, que es lo que uno lee del diagrama de caja.
    marcadas <- tabla[tabla$atipico, c("fila", "valor", "distancia")]
    marcadas[order(marcadas$valor), ]
  },

  asociacion = function(ds, args) {
    x <- .exigir(args[1], "asociacion <x> <y>")
    y <- .exigir(args[2], "asociacion <x> <y>")
    medida <- medir_asociacion(ds$df[[x]], ds$df[[y]])
    data.frame(medida = c("n", "covarianza", "pearson", "spearman", "p_valor"),
               valor = c(medida$n, medida$covarianza, medida$pearson,
                         medida$spearman, medida$p_valor),
               unidades = c("filas", paste(x, "x", y), "ninguna", "ninguna",
                            "ninguna"))
  },

  normalidad = function(ds, args) {
    columna <- .exigir(args[1], "normalidad <columna>")
    valores <- as.numeric(ds$df[[columna]])
    juicio <- evaluar_normalidad(valores)
    estimada <- estimar_densidad(valores)
    cat(sprintf("%s · %s · %s\n", columna, juicio$prueba, juicio$veredicto))
    data.frame(medida = c("n", "media", "desviacion", "asimetria", "curtosis",
                          "ancho_banda_h", "estadistico", "p_valor"),
               valor = c(juicio$n, mean(valores, na.rm = TRUE),
                         stats::sd(valores, na.rm = TRUE), juicio$asimetria,
                         juicio$curtosis, estimada$ancho, juicio$estadistico,
                         juicio$p_valor))
  },

  contingencia = function(ds, args) {
    a <- .exigir(args[1], "contingencia <a> <b>")
    b <- .exigir(args[2], "contingencia <a> <b>")
    cruce <- tabla_contingencia(ds$df[[a]], ds$df[[b]], a, b)
    cat(sprintf("chi2 = %.3f · V de Cramer = %.4f\n", cruce$chi2, cruce$cramer))
    cruce$observado
  },

  casillas = function(ds, args)
    data.frame(clave = CASILLAS_INFORME,
               titulo = vapply(CASILLAS_INFORME, titulo_de, "")),

  panel = function(ds, args, opciones = list()) tabla_de_panel(ds, .exigir(
    args[1], "panel <clave> [columnas...] | panel f4.<...> --metodo <clave>"),
    args[-1], opciones),

  momentos = comando_momentos,

  metodo = comando_metodo,

  cuaderno = function(ds, args, opciones = list()) {
    seleccion <- seleccion_de_args(ds, args, opciones)
    armar_informe_exploracion(seleccion, ds,
                              opciones = .piezas_pedidas(opciones),
                              texto = opciones$texto)
  },

  #' La sesión guardada: lo mismo que descarga ⚙ Objetos, desde la consola.
  #' Sirve para dejar preparada la configuración de un taller y abrirla
  #' después con `--sesion` o con `?sesion=` en la app.
  sesion = function(ds, args, opciones = list()) {
    seleccion <- seleccion_de_args(ds, args, opciones)
    sesion_actual(NULL, ds, seleccion,
                  opciones_cuaderno(.piezas_pedidas(opciones),
                                    opciones$texto))
  }
)

.exigir <- function(valor, uso) {
  if (is.na(valor) || is.null(valor) || !nzchar(valor))
    stop("faltan argumentos · uso: ", uso, call. = FALSE)
  valor
}

.escala_cli <- function(ds, columna) {
  fila <- ds$diccionario$columna == columna
  if (!any(fila)) stop("no existe la columna: ", columna, call. = FALSE)
  ds$diccionario$escala[fila][1]
}

#' Un posicional opcional. `args[i]` da NA cuando no está, y `%||%` solo
#' atrapa NULL: sin esto un `--metodo` omitido llega como NA a la lógica.
.arg <- function(args, i, alterno) {
  if (i > length(args) || is.na(args[i]) || !nzchar(args[i])) alterno else args[i]
}

#' Punto de entrada del CLI.
correr_lab <- function(argumentos = commandArgs(trailingOnly = TRUE)) {
  cargar_sda(con_ui = FALSE)
  partido <- partir_argumentos(argumentos)
  comando <- partido$posicionales[1]
  if (is.na(comando) || !comando %in% names(COMANDOS)) {
    cat("comandos:", paste(names(COMANDOS), collapse = " · "), "\n")
    cat("opciones: --fuente <clave> · --filtro Columna=valor|Columna!=valor",
        "(repetible) · --sesion archivo.json · --texto completo|breve|ninguno",
        "· --incluir pieza,pieza · --excluir pieza · --salida archivo\n")
    cat("fases 2-4: momentos <col> <col> ... · metodo <clave> ·",
        "panel f4.<...> --metodo <clave>\n",
        "         --hiper nombre=valor (repetible) · --columnas a,b,c ·",
        "--grupos <metodo> · --reinicios n · --semilla n\n",
        "         --ejes 2,3 · --umbral 0.8 · --k_max 10 · --color columna\n")
    cat("métodos activos:", paste(Filter(function(k)
      metodo(k)$estado == "activo", claves_metodos()), collapse = " · "), "\n")
    cat("piezas del cuaderno:", paste(names(PIEZAS_CUADERNO), collapse = " · "),
        "\n")
    return(invisible(FALSE))
  }
  # `fuentes` y `casillas` son catálogos: preguntan qué hay, no miran datos.
  # Exigirles --fuente era pedir el dataset para poder preguntar cuál elegir.
  ds <- if (comando %in% c("fuentes", "casillas")) NULL
        else armar_dataset(partido$opciones)
  accion <- COMANDOS[[comando]]
  resultado <- if (length(formals(accion)) >= 3L)
    accion(ds, partido$posicionales[-1], partido$opciones)
  else accion(ds, partido$posicionales[-1])
  salida <- partido$opciones$salida
  if (identical(comando, "cuaderno") && !is.null(salida)) {
    writeLines(resultado, salida, useBytes = TRUE)
    cat("cuaderno escrito en", salida, "\n")
    return(invisible(TRUE))
  }
  if (identical(comando, "sesion") && !is.null(salida)) {
    exportar_sesion_json(resultado, salida)
    cat("sesión escrita en", salida, "\n")
    return(invisible(TRUE))
  }
  print(resultado)
  invisible(TRUE)
}

if (any(grepl("lab[.]R$", commandArgs(trailingOnly = FALSE)))) correr_lab()
