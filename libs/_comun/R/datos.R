# libs/_comun/R/datos.R
#
# Carga y limpieza de charcoal.csv (panel FAO de carbón vegetal).
# Compartido por los 3 proyectos (Shiny / Quarto+OJS / shinylive).
#
# Funciones expuestas:
#   cargar_charcoal()     -> data.frame limpio (Country_Area, flujo, Year, Quantity)
#   listar_flujos()       -> character() con los flujos disponibles
#   listar_paises()       -> character() con los países disponibles
#   filtrar_charcoal()    -> data.frame filtrado por país/año/flujo
#   pivot_paises()        -> matrix país × año (para PCA/clustering)
#   gen_sintetico()       -> data.frame sintético para demos ANOVA/regresión

# ---------------------------------------------------------------------------
# Resolución robusta de la raíz del proyecto (busca hacia arriba hasta
# encontrar data/charcoal.csv o renv/activate.R). Así da igual desde qué
# subdirectorio se source este archivo.
# ---------------------------------------------------------------------------
proyecto_raiz <- function() {
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "data", "charcoal.csv")) ||
        file.exists(file.path(d, "renv", "activate.R"))) {
      return(d)
    }
    padre <- dirname(d)
    if (padre == d) stop("No se encontro la raiz del proyecto SDA desde: ", getwd())
    d <- padre
  }
}

charcoal_path <- function() file.path(proyecto_raiz(), "data", "charcoal.csv")

twins_path <- function() file.path(proyecto_raiz(), "data", "twins.csv")

# ---------------------------------------------------------------------------
# Cargar y limpiar
# ---------------------------------------------------------------------------
cargar_charcoal <- function(limpiar = TRUE) {
  df <- utils::read.csv(charcoal_path(), stringsAsFactors = FALSE,
                        check.names = FALSE, encoding = "UTF-8")
  if (!limpiar) return(df)

  # Filas basura al final del CSV (NA en Year, "Footnote"/"Estimate" en Commodity)
  df <- df[!is.na(df$Year) &
             df$Country_Area != "" &
           grepl("^Charcoal\\s*-", df$Commodity), ]
  # Quitar filas con Quantity NA
  df <- df[!is.na(df$Quantity), ]
  # Normalizar encoding de país (algunos vienen con caracteres raros)
  df$Country_Area <- enc2utf8(df$Country_Area)
  # Separar flow: "Charcoal - Production" -> "Production"
  df$flujo <- sub("^Charcoal\\s*-\\s*", "", df$Commodity)
  # Trimming de espacios al final (algunos flujos los traen)
  df$flujo <- trimws(df$flujo)
  # Year a entero
  df$Year <- as.integer(df$Year)
  # Mantener solo columnas útiles
  df[, c("Country_Area", "flujo", "Year", "Unit", "Quantity")]
}

# ---------------------------------------------------------------------------
# twins.csv — estudio de gemelos (Ashenfelter & Krueger). 183 pares, 16 vars.
# Es la fuente cross-section del curso: sirve para regresion multiple, LDA/QDA,
# EFA, CCA y todo lo que necesite varias variables numericas por observacion.
#
# Dos trampas del archivo, ambas resueltas aca:
#   1. Los faltantes vienen como "." (no como celda vacia). Sin na.strings, R
#      lee TODA la columna como character.
#   2. El archivo trae BOM UTF-8, asi que la primera columna se llamaria
#      "﻿DLHRWAGE". Se limpia con fileEncoding = "UTF-8-BOM".
#
# Faltantes por columna: DLHRWAGE 34, HRWAGEH 22, HRWAGEL 21, DTEN 4.
# Como DLHRWAGE es la respuesta habitual, casi todo modelo va a querer
# completos = TRUE.
# ---------------------------------------------------------------------------
cargar_twins <- function(completos = FALSE, vars = NULL) {
  df <- utils::read.csv(twins_path(),
                        na.strings    = c(".", "", "NA"),
                        fileEncoding  = "UTF-8-BOM",
                        stringsAsFactors = FALSE)

  # Todas las columnas son numericas; forzamos por si alguna quedo character
  # (pasa si aparece un separador raro en una fila).
  for (nm in names(df)) df[[nm]] <- suppressWarnings(as.numeric(df[[nm]]))

  if (!is.null(vars)) {
    faltan <- setdiff(vars, names(df))
    if (length(faltan))
      stop("Columnas inexistentes en twins.csv: ", paste(faltan, collapse = ", "))
    df <- df[, vars, drop = FALSE]
  }

  if (isTRUE(completos)) df <- df[stats::complete.cases(df), , drop = FALSE]

  df
}

# Diccionario corto, para poblar selectores y tooltips sin hardcodear en la UI.
twins_diccionario <- function() {
  c(
    DLHRWAGE = "Dif. en log-salario horario entre gemelos (respuesta habitual)",
    DEDUC1   = "Dif. de educacion, reporte propio",
    DEDUC2   = "Dif. de educacion, reporte del hermano",
    AGE      = "Edad",
    AGESQ    = "Edad al cuadrado",
    HRWAGEH  = "Salario horario, gemelo H",
    HRWAGEL  = "Salario horario, gemelo L",
    WHITEH   = "Indicador raza blanca, gemelo H",
    WHITEL   = "Indicador raza blanca, gemelo L",
    MALEH    = "Indicador hombre, gemelo H",
    MALEL    = "Indicador hombre, gemelo L",
    EDUCH    = "Anios de educacion, gemelo H",
    EDUCL    = "Anios de educacion, gemelo L",
    DTEN     = "Dif. de antiguedad en el empleo",
    DMARRIED = "Dif. en estado civil",
    DUNCOV   = "Dif. en cobertura sindical"
  )
}

listar_vars_twins <- function() names(twins_diccionario())

# ---------------------------------------------------------------------------
# Selectores para UI
# ---------------------------------------------------------------------------
listar_flujos <- function(df = cargar_charcoal()) sort(unique(df$flujo))

listar_paises <- function(df = cargar_charcoal()) sort(unique(df$Country_Area))

listar_anios <- function(df = cargar_charcoal()) sort(unique(df$Year))

# ---------------------------------------------------------------------------
# Filtro con arguments opcionales (NULL = no filtrar esa dimensión)
# ---------------------------------------------------------------------------
filtrar_charcoal <- function(df = cargar_charcoal(),
                              paises = NULL,
                              anios = NULL,
                              flujos = "Production",
                              q_min = -Inf, q_max = Inf) {
  if (!is.null(paises)) df <- df[df$Country_Area %in% paises, ]
  if (!is.null(anios))  df <- df[df$Year %in% anios, ]
  if (!is.null(flujos)) df <- df[df$flujo %in% flujos, ]
  df <- df[df$Quantity >= q_min & df$Quantity <= q_max, ]
  df
}

# ---------------------------------------------------------------------------
# Pivot a matriz país × año (para PCA / clustering / series).
# Solo conserva países con suficientes observaciones (min_obs por año).
# ---------------------------------------------------------------------------
pivot_paises <- function(df = cargar_charcoal(),
                          flujo = "Production",
                          anio_min = 1990, anio_max = 2020,
                          min_obs = 10,
                          fun_agrega = mean) {
  d <- filtrar_charcoal(df, flujos = flujo,
                        anios = seq(anio_min, anio_max))
  d <- d[d$Country_Area != "", ]

  # Agregar duplicados (pais, year): algunos países reportan varias veces el
  # mismo año; colapsamos con fun_agrega (default: mean). Evita el warning
  # silencioso de reshape() que tomaba la primera fila arbitrariamente.
  agg <- aggregate(Quantity ~ Country_Area + Year,
                   data = d, FUN = fun_agrega, na.rm = TRUE)

  wide <- reshape(agg, idvar = "Country_Area", timevar = "Year",
                  direction = "wide")
  nms <- names(wide)
  nms[nms == "Country_Area"] <- "pais"
  names(wide) <- c("pais",
                   as.character(sort(unique(agg$Year))))

  # Filtrar países con al menos min_obs observaciones no-NA
  obs <- rowSums(!is.na(wide[, -1, drop = FALSE]))
  wide <- wide[obs >= min_obs, ]

  rownames(wide) <- wide$pais
  mat <- as.matrix(wide[, -1])
  rownames(mat) <- wide$pais
  # Imputación simple: 0 (producción/stock nulo reportado) — documentalo en UI
  mat[is.na(mat)] <- 0
  mat
}

# ---------------------------------------------------------------------------
# Generador sintético para demos ANOVA / regresión.
#   tipo = "anova"    : k_grupos normales con efecto aditivo, 1 observación por fila
#   tipo = "regresion": relación cuadrática + ruido, devuelve x, y, y_verdadero
# ---------------------------------------------------------------------------
gen_sintetico <- function(n = 100, k_grupos = 4, efecto = 5, ruido = 1,
                           semilla = 42, tipo = c("anova", "regresion")) {
  set.seed(semilla)
  tipo <- match.arg(tipo)

  if (tipo == "anova") {
    n <- max(n, k_grupos)  # al menos 1 por grupo
    grupo_size <- n %/% k_grupos
    resto <- n - grupo_size * k_grupos
    sizes <- rep(grupo_size, k_grupos) + c(rep(1, resto), rep(0, k_grupos - resto))
    media_global <- 50
    efecto_grupo <- seq_len(k_grupos) * efecto
    valores <- unlist(Map(function(sz, ef) {
      rnorm(sz, mean = media_global + ef, sd = ruido)
    }, sizes, efecto_grupo))
    data.frame(
      observacion = seq_len(n),
      grupo = factor(rep(LETTERS[seq_len(k_grupos)], sizes)),
      valor = valores,
      semilla = semilla
    )
  } else {
    x <- seq(-3, 3, length.out = n)
    y_verdadero <- 0.5 * x^3 - 2 * x^2 + x + 1
    y <- y_verdadero + rnorm(n, mean = 0, sd = ruido)
    data.frame(
      observacion = seq_len(n),
      x = x, y = y, y_verdadero = y_verdadero,
      semilla = semilla
    )
  }
}
