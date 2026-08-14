# libs/_comun/R/temas_bslib.R
#
# Presets de tema bslib compartidos por todas las apps del curso.
#
# Por que existe este archivo:
#   app.R hacia `bs_theme_update(actual, bootswatch = x)`. Eso solo cambia el
#   bootswatch: si el tema actual traia fuentes o reglas Sass propias (como el
#   preset "retro"), quedaban pegadas al cambiar. Aca cada preset se construye
#   COMPLETO desde cero, asi que cambiar de tema siempre da un estado limpio.
#
# Funciones expuestas:
#   listar_temas()            -> character() con los nombres validos
#   tema(nombre)              -> objeto bs_theme completo
#   cambiar_tema(session, n)  -> aplica el preset en runtime (setCurrentTheme)
#
# NOTA sobre fuentes: font_google() descarga la fuente la primera vez y la
# cachea en disco (ver `sass::font_cache()`). La primera construccion del tema
# "retro" necesita red; despues funciona offline.

# ---------------------------------------------------------------------------
# Rutas a los .scss. Usa proyecto_raiz() de datos.R si ya esta cargado;
# si no, lo resuelve por su cuenta (este archivo debe poder sourcearse solo).
# ---------------------------------------------------------------------------
.raiz_temas <- function() {
  if (exists("proyecto_raiz", mode = "function")) return(proyecto_raiz())
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "data", "charcoal.csv")) ||
        file.exists(file.path(d, "renv", "activate.R"))) return(d)
    p <- dirname(d); if (p == d) stop("Raiz SDA no encontrada desde: ", getwd())
    d <- p
  }
}

scss_path <- function(archivo) {
  file.path(.raiz_temas(), "libs", "_comun", "scss", archivo)
}

# ---------------------------------------------------------------------------
# Catalogo
# ---------------------------------------------------------------------------
.TEMAS <- c("flatly", "darkly", "cosmo", "minty", "vapor",
            "retro", "retro-dark")

listar_temas <- function() .TEMAS

# ---------------------------------------------------------------------------
# Constructor principal
# ---------------------------------------------------------------------------
#' @param nombre uno de listar_temas()
#' @return objeto bs_theme listo para pasar a page_navbar(theme = ...)
tema <- function(nombre = "flatly") {
  nombre <- match.arg(nombre, .TEMAS)

  if (nombre %in% c("retro", "retro-dark")) return(.tema_retro(oscuro = nombre == "retro-dark"))

  # Presets bootswatch "normales": tipografia limpia, sin reglas extra.
  bslib::bs_theme(
    bootswatch         = nombre,
    base_font          = bslib::font_google("Inter"),
    heading_font       = bslib::font_google("Inter"),
    `enable-gradients` = TRUE,
    `enable-shadows`   = TRUE
  )
}

# ---------------------------------------------------------------------------
# Preset 8-bit. Replica el ejemplo NES.css de la vinieta de theming de bslib:
#   https://rstudio.github.io/bslib/articles/theming/index.html
#
# La vinieta vendoriza nes.min.css; aca en cambio usamos retro.scss, escrito
# contra las variables Sass de Bootstrap para que el look siga a los colores
# que elijas (o que elija el widget bs_themer()).
# ---------------------------------------------------------------------------
.tema_retro <- function(oscuro = FALSE) {
  colores <- if (oscuro) {
    # Paleta de la demo oscura: fondo carbon, acento rojo NES.
    list(bg = "#212529", fg = "#e9ecef", primary = "#f08080")
  } else {
    # Paleta exacta del ejemplo de la vinieta.
    list(bg = "#e5e5e5", fg = "#0d0c0c", primary = "#dd2020")
  }

  base <- bslib::bs_theme(
    bg        = colores$bg,
    fg        = colores$fg,
    primary   = colores$primary,
    base_font = bslib::font_google("Press Start 2P"),
    code_font = bslib::font_google("Press Start 2P"),
    # Press Start 2P es enorme por glifo: sin bajar la base, nada entra.
    `font-size-base`  = "0.75rem",
    `enable-rounded`  = FALSE,
    `enable-shadows`  = FALSE,
    `enable-gradients` = FALSE
  )

  bslib::bs_add_rules(base, list(
    sass::sass_file(scss_path("retro.scss")),
    sass::sass_file(scss_path("custom.scss"))
  ))
}

# ---------------------------------------------------------------------------
# Cambio en runtime. Construye el preset completo (no bs_theme_update) para
# que fuentes y reglas Sass del preset anterior no queden pegadas.
# ---------------------------------------------------------------------------
cambiar_tema <- function(session, nombre) {
  session$setCurrentTheme(tema(nombre))
  if (requireNamespace("shiny", quietly = TRUE)) {
    shiny::showNotification(sprintf("Tema: %s", nombre), type = "message",
                            duration = 2)
  }
  invisible(nombre)
}
