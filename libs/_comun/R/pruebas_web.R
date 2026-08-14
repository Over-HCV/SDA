# libs/_comun/R/pruebas_web.R
#
# Verificacion a nivel NAVEGADOR de artefactos web estaticos (el dashboard de
# Quarto+OJS hoy; el bundle de shiny-live despues).
#
# Por que existe:
#   Un `quarto render` limpio y un HTTP 200 NO son evidencia de que la cosa
#   funcione. Los tres bugs de OJS del Proyecto 2 (`pca_all.map`,
#   `Inputs.selection`, `highlight.trim`) convivieron los tres con render
#   limpio: son errores de RUNTIME, en el navegador, dentro de una celda.
#   OJS los pinta en el DOM y sigue como si nada, asi que la pagina "carga".
#
# Estrategia: en vez de escuchar eventos del protocolo de Chrome (fragil),
# se inyecta un colector de errores ANTES de que corra cualquier script de la
# pagina, y despues se lee. Mas portable y no se pierde nada temprano.
#
# Depende de: chromote, jsonlite, processx (los tres ya en renv).

# ---------------------------------------------------------------------------
# JS que se instala antes que nada en la pagina. Captura las tres vias por las
# que un error puede escaparse sin romper la carga.
# ---------------------------------------------------------------------------
.JS_COLECTOR <- "
window.__eda_errores = [];
window.addEventListener('error', function (e) {
  window.__eda_errores.push('error: ' + (e && e.message ? e.message : String(e)));
});
window.addEventListener('unhandledrejection', function (e) {
  window.__eda_errores.push('promesa: ' + String(e && e.reason ? e.reason : e));
});
(function () {
  var orig = console.error;
  console.error = function () {
    try {
      window.__eda_errores.push('console: ' +
        Array.prototype.map.call(arguments, String).join(' '));
    } catch (_) {}
    return orig.apply(console, arguments);
  };
})();
"

# ---------------------------------------------------------------------------
# Servidor estatico efimero. OJS importa modulos ES: bajo file:// eso lo
# bloquea CORS, asi que hay que servir por HTTP aunque el HTML sea autocontenido.
# ---------------------------------------------------------------------------
.servir_dir <- function(dir, puerto) {
  p <- processx::process$new(
    "python3", c("-m", "http.server", as.character(puerto), "--directory", dir),
    stdout = NULL, stderr = NULL
  )
  # Esperar a que el puerto responda (hasta ~10 s).
  for (i in 1:50) {
    Sys.sleep(0.2)
    ok <- tryCatch({
      con <- suppressWarnings(socketConnection("127.0.0.1", port = puerto,
                                               open = "r", blocking = TRUE,
                                               timeout = 1))
      close(con); TRUE
    }, error = function(e) FALSE)
    if (ok) return(p)
  }
  p$kill()
  stop("El servidor estatico no levanto en el puerto ", puerto)
}

.puerto_libre <- function() {
  for (intento in 1:20) {
    p <- sample(8000:9999, 1)
    libre <- tryCatch({
      con <- suppressWarnings(socketConnection("127.0.0.1", port = p,
                                               open = "r", blocking = TRUE,
                                               timeout = 0.3))
      close(con); FALSE          # alguien contesto => ocupado
    }, error = function(e) TRUE) # nadie contesto => libre
    if (libre) return(p)
  }
  stop("No se encontro un puerto libre")
}

# ---------------------------------------------------------------------------
# verificar_html: carga el HTML en Chrome headless y devuelve lo que encuentra.
#
#   ruta                 archivo .html (se sirve su directorio por HTTP)
#   selectores_error     nodos que OJS/Quarto usan para pintar errores
#   selectores_esperados named list(selector = minimo). ASERCIONES POSITIVAS:
#                        sin esto, una pagina que no pinta NADA pasa el test.
#   espera               segundos tras 'load'. El grafo reactivo de OJS se
#                        resuelve async; mirar de inmediato da falsos verdes.
#
# Devuelve list(ok, errores_js, nodos_error, conteos, faltantes)
# ---------------------------------------------------------------------------
verificar_html <- function(ruta,
                            selectores_error = c(".observablehq--error",
                                                 ".quarto-ojs-error"),
                            selectores_esperados = list(),
                            espera = 6,
                            verbose = TRUE) {

  stopifnot(file.exists(ruta))
  ruta <- normalizePath(ruta)
  dir  <- dirname(ruta)
  archivo <- basename(ruta)

  puerto <- .puerto_libre()
  srv <- .servir_dir(dir, puerto)
  on.exit(try(srv$kill(), silent = TRUE), add = TRUE)

  url <- sprintf("http://127.0.0.1:%d/%s", puerto, archivo)
  if (verbose) cat("  [web] sirviendo ", url, "\n", sep = "")

  b <- chromote::ChromoteSession$new()
  on.exit(try(b$close(), silent = TRUE), add = TRUE)

  b$Runtime$enable()
  b$Page$enable()
  # Clave: instalar el colector ANTES de navegar, si no los errores tempranos
  # (los de las primeras celdas de OJS) ocurren antes de poder escucharlos.
  b$Page$addScriptToEvaluateOnNewDocument(source = .JS_COLECTOR)

  b$Page$navigate(url, wait_ = TRUE)
  b$Page$loadEventFired(wait_ = TRUE, timeout_ = 60)
  if (verbose) cat("  [web] cargado; esperando ", espera, "s a que OJS asiente\n", sep = "")
  Sys.sleep(espera)

  evaluar <- function(js) {
    r <- b$Runtime$evaluate(js, returnByValue = TRUE)
    r$result$value
  }

  # --- Errores JS recolectados ---
  errores_js <- tryCatch({
    v <- evaluar("JSON.stringify(window.__eda_errores || [])")
    unlist(jsonlite::fromJSON(v %||% "[]"))
  }, error = function(e) character())
  if (is.null(errores_js)) errores_js <- character()

  # --- Nodos de error en el DOM (la senal PRINCIPAL para OJS) ---
  sel_js <- jsonlite::toJSON(selectores_error, auto_unbox = FALSE)
  nodos <- tryCatch({
    v <- evaluar(sprintf("
      (function () {
        var sels = %s, out = [];
        sels.forEach(function (s) {
          document.querySelectorAll(s).forEach(function (n) {
            var t = (n.innerText || n.textContent || '').trim();
            if (t) out.push(s + ' :: ' + t.slice(0, 300));
          });
        });
        return JSON.stringify(out);
      })()", sel_js))
    unlist(jsonlite::fromJSON(v %||% "[]"))
  }, error = function(e) character())
  if (is.null(nodos)) nodos <- character()

  # --- Aserciones positivas ---
  conteos <- list(); faltantes <- character()
  for (sel in names(selectores_esperados)) {
    minimo <- selectores_esperados[[sel]]
    n <- tryCatch(
      evaluar(sprintf("document.querySelectorAll(%s).length",
                      jsonlite::toJSON(sel, auto_unbox = TRUE))),
      error = function(e) 0
    )
    n <- as.integer(n %||% 0)
    conteos[[sel]] <- n
    if (n < minimo)
      faltantes <- c(faltantes, sprintf("%s: %d (esperado >= %d)", sel, n, minimo))
  }

  list(
    ok          = length(errores_js) == 0 && length(nodos) == 0 &&
                  length(faltantes) == 0,
    errores_js  = errores_js,
    nodos_error = nodos,
    conteos     = conteos,
    faltantes   = faltantes,
    url         = url
  )
}

`%||%` <- function(a, b) if (is.null(a)) b else a
