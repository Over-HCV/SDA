# libs/shiny-live/R/datos.R
#
# Carga y preparación de datos para ANOVA one-way. Cubre los 3 datasets
# alternables en la UI: twins (salario por nivel educativo), charcoal
# (producción por región) y sintético (demo controlable).
#
# Funciones expuestas:
#   cargar_twins_sl(complete_cases) -> data.frame del estudio de gemelos
#   categorizar_educ(anios)       -> factor 3 niveles (workshops/twins/t00)
#   asignar_region(pais)          -> región de un país (tabla 8 regiones)
#   datos_anova(dataset, ...)     -> data.frame(valor, grupo) listo para aov()
#
# Depende de: _comun/R/datos.R (cargar_charcoal, gen_sintetico, filtrar_charcoal)

# ---------------------------------------------------------------------------
# Bootstrap auto-contenido: carga los helpers compartidos de _comun.
# Define su propio root-finder para evitar chicken-and-egg (proyecto_raiz()
# todavía no existe cuando se sourcea este archivo aislado).
# ---------------------------------------------------------------------------
.bootstrap_comun_shinylive <- FALSE
bootstrap_comun <- function(force = FALSE) {
  if (.bootstrap_comun_shinylive && !force) return(invisible(TRUE))
  raiz <- (function() {
    d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
    repeat {
      if (file.exists(file.path(d, "data", "charcoal.csv")) ||
          file.exists(file.path(d, "renv", "activate.R"))) return(d)
      p <- dirname(d); if (p == d) stop("Raíz SDA no encontrada desde: ", getwd())
      d <- p
    }
  })()
  for (f in c("datos.R", "metricas.R", "temas.R"))
    source(file.path(raiz, "libs", "_comun", "R", f))
  .bootstrap_comun_shinylive <<- TRUE
  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Cargar twins.csv. NA codificado como ".". complete_cases=TRUE filtra filas
# con cualquier NA (igual que workshops/twins/t00.rmd pregunta 2).
# ---------------------------------------------------------------------------
# Sufijo `_sl` (shiny-live) a propósito: `_comun/R/datos.R` define su propio
# `cargar_twins(completos, vars)` con otra firma, y `bootstrap_comun()` puede
# re-sourcearlo DESPUÉS de este archivo — sin el sufijo la nuestra queda
# pisada y la app muere con "unused argument (complete_cases = TRUE)".
cargar_twins_sl <- function(complete_cases = TRUE) {
  bootstrap_comun()
  path <- file.path(proyecto_raiz(), "data", "twins.csv")
  df <- utils::read.csv(path, stringsAsFactors = FALSE,
                        na.strings = ".", check.names = FALSE)
  if (complete_cases) df <- df[complete.cases(df), ]
  df
}

# ---------------------------------------------------------------------------
# Categorización pedagógica de años de educación (workshops/twins/t00 p.7).
#   [0,12)   -> "Primaria/Secundaria"
#   [12,16)  -> "Pregrado"
#   [16,Inf] -> "Posgrado"
# ---------------------------------------------------------------------------
categorizar_educ <- function(anios) {
  cut(anios, breaks = c(0, 12, 16, Inf), right = FALSE, include.lowest = FALSE,
       labels = c("Primaria/Secundaria", "Pregrado", "Posgrado"))
}

# ---------------------------------------------------------------------------
# Tabla país -> región. 8 regiones (más granular que continente simple) para
# los ~190 países que retorna listar_paises() en charcoal.csv. Las variantes
# "(former)" se mapean a su región histórica; lo no reconocido -> "Otros".
# ---------------------------------------------------------------------------
.paises_region <- list(
  Africa = c(
    "Angola","Benin","Botswana","Burkina Faso","Burundi","Cabo Verde","Cameroon",
    "Central African Rep.","Chad","Comoros","Congo","Côte d'Ivoire",
    "Dem. Rep. of the Congo","Djibouti","Egypt","Equatorial Guinea","Eritrea",
    "Eswatini","Ethiopia","Gabon","Gambia","Ghana","Guinea","Guinea-Bissau",
    "Kenya","Lesotho","Liberia","Libya","Madagascar","Malawi","Mali",
    "Mauritania","Mauritius","Mayotte","Morocco","Mozambique","Namibia","Niger",
    "Nigeria","Reunion","Réunion","Rwanda","Sao Tome and Principe","Senegal",
    "Seychelles","Sierra Leone","Somalia","South Africa","South Sudan","Sudan",
    "Sudan (former)","Togo","Tunisia","Uganda","United Rep. of Tanzania",
    "Zambia","Zimbabwe"),
  `America del Norte` = c("Bermuda","United States"),
  `America del Sur` = c(
    "Argentina","Bolivia (Plur. State of)","Brazil","Chile","Colombia",
    "Falkland Is. (Malvinas)","French Guiana","Guyana","Paraguay","Peru",
    "Suriname","Uruguay","Venezuela (Bolivar. Rep.)"),
  `America Central` = c(
    "Belize","Costa Rica","El Salvador","Guatemala","Honduras","Nicaragua",
    "Panama"),
  Caribe = c(
    "Aruba","Bahamas","Barbados","Bonaire, St Eustatius, Saba",
    "British Virgin Islands","Cayman Islands","Cuba","Curaçao","Dominica",
    "Dominican Republic","Grenada","Guadeloupe","Haiti","Jamaica","Martinique",
    "Neth. Antilles (former)","Sint Maarten (Dutch part)","St. Kitts-Nevis",
    "St. Lucia","St. Vincent-Grenadines","Trinidad and Tobago",
    "Turks and Caicos Islands"),
  Europa = c(
    "Andorra","Austria","Belarus","Belgium","Bosnia and Herzegovina","Bulgaria",
    "Croatia","Cyprus","Faeroe Islands","Finland","Germany",
    "Germany, Fed. R. (former)","Gibraltar","Greece","Italy","Latvia",
    "Lithuania","Malta","Montenegro","Netherlands","North Macedonia","Norway",
    "Portugal","Republic of Moldova","Romania","Russian Federation","Serbia",
    "Serbia and Montenegro","Slovakia","Spain","Ukraine",
    "Yugoslavia, SFR (former)"),
  Asia = c(
    "Afghanistan","Armenia","Azerbaijan","Bahrain","Bangladesh","Bhutan",
    "Brunei Darussalam","Cambodia","China","China, Hong Kong SAR",
    "China, Macao SAR","India","Indonesia","Iran (Islamic Rep. of)","Iraq",
    "Israel","Japan","Jordan","Kazakhstan","Korea, Dem.Ppl's.Rep.","Kuwait",
    "Kyrgyzstan","Lao People's Dem. Rep.","Lebanon","Malaysia","Maldives",
    "Mongolia","Myanmar","Nepal","Oman","Pakistan","Philippines","Qatar",
    "Saudi Arabia","Singapore","Sri Lanka","Syrian Arab Republic","Tajikistan",
    "Thailand","Turkmenistan","United Arab Emirates","Uzbekistan","Viet Nam",
    "Yemen"),
  Oceania = c(
    "Fiji","French Polynesia","Kiribati","Micronesia (Fed. States of)",
    "New Caledonia","New Zealand","Niue","Palau","Papua New Guinea","Samoa",
    "Solomon Islands","Tonga","Vanuatu")
)

# Lookup país -> región (named character), construido una sola vez.
.lookup_region <- local({
  v <- unlist(.paises_region, use.names = FALSE)            # nombres de país
  regs <- rep(names(.paises_region), lengths(.paises_region)) # región c/u
  setNames(regs, v)
})

asignar_region <- function(pais) {
  r <- .lookup_region[pais]
  out <- ifelse(is.na(r), "Otros", r)
  factor(out, levels = c(names(.paises_region), "Otros"))
}

# ---------------------------------------------------------------------------
# Construye el data.frame para ANOVA: columnas `valor` (numeric) y `grupo`
# (factor). Unifica los 3 datasets bajo el mismo contrato.
#   dataset = "twins"    : valor = HRWAGEL, grupo = categorizar_educ(EDUCL)
#   dataset = "charcoal" : valor = Quantity, grupo = asignar_region(pais)
#                          para un (flujo, anio) fijos
#   dataset = "sintetico": gen_sintetico(tipo="anova") renombrado
# ---------------------------------------------------------------------------
datos_anova <- function(dataset = c("twins", "charcoal", "sintetico"),
                        flujo = "Production", anio = 2019,
                        k_grupos = NULL, n_por_grupo = 30,
                        efecto = 5, ruido = 1, semilla = 42,
                        balanceado = TRUE) {
  dataset <- match.arg(dataset)
  bootstrap_comun()

  if (dataset == "twins") {
    df <- cargar_twins_sl(complete_cases = TRUE)
    out <- data.frame(
      valor = df$HRWAGEL,
      grupo = categorizar_educ(df$EDUCL),
      stringsAsFactors = FALSE)
  } else if (dataset == "charcoal") {
    d <- filtrar_charcoal(cargar_charcoal(), flujos = flujo, anios = anio)
    out <- data.frame(
      valor = d$Quantity,
      grupo = asignar_region(d$Country_Area),
      stringsAsFactors = FALSE)
  } else {
    k <- if (is.null(k_grupos)) 4 else k_grupos
    n <- max(k_grupos %||% 4, n_por_grupo * k)
    s <- gen_sintetico(n = n, k_grupos = k, efecto = efecto,
                       ruido = ruido, semilla = semilla, tipo = "anova")
    out <- data.frame(valor = s$valor, grupo = s$grupo, stringsAsFactors = FALSE)
    if (!balanceado) {
      set.seed(semilla)
      keep <- as.logical(rbinom(nrow(out), 1, 0.85))
      out <- out[keep, ]
    }
  }
  out <- out[is.finite(out$valor) & !is.na(out$grupo), ]
  out$grupo <- factor(out$grupo)  # drop unused levels
  out[order(as.integer(out$grupo)), ]
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---------------------------------------------------------------------------
# Flujos disponibles en charcoal.csv, para poblar el selectInput EN LA UI
# (no vía updateSelectInput: ese mensaje no siempre llega en webR y el select
# queda vacío). Memoizado: parsear charcoal.csv cuesta ~2.7 MB.
# ---------------------------------------------------------------------------
.flujos_cache <- NULL
flujos_charcoal <- function() {
  if (!is.null(.flujos_cache)) return(.flujos_cache)
  out <- tryCatch({ bootstrap_comun(); listar_flujos() },
                  error = function(e) "Production")
  .flujos_cache <<- out
  out
}
