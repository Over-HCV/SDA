# learn/R/pruebas/verificar_bundle.R
#
# Responsabilidad: comprobar que el bundle wasm ARRANCA de verdad (spec S2b).
#
# Uso:  Rscript learn/R/pruebas/verificar_bundle.R
#       SDA_ESPERA_WEBR=180 Rscript learn/R/pruebas/verificar_bundle.R
#
# Que el export termine sin error no prueba nada. El bundle de libs/shiny-live
# exportaba limpio y moría en webR por seis motivos distintos, todos visibles
# solo al abrirlo en un navegador. Y este mismo bundle salió una vez sin ningún
# paquete de R dentro, con el export en verde.
#
# Por qué no reusa verificar_html() de libs/_comun/R/pruebas_web.R: esa función
# espera el evento `Page.loadEventFired` con un tope de 60 s. webR descarga
# decenas de MB antes de que el `load` dispare, así que con el bundle siempre
# expira. Acá se navega y se SONDEA el DOM hasta que aparece lo esperado, que
# además es una señal más honesta: no interesa cuándo el navegador dice
# "cargué", interesa cuándo la app pintó.

source("learn/R/cargar.R")

ESPERA_WEBR <- as.integer(Sys.getenv("SDA_ESPERA_WEBR", "180"))

# Lo que tiene que estar pintado. Son aserciones POSITIVAS: sin ellas, una
# página en blanco pasa el test.
ESPERADOS <- list(
  ".navbar"       = 1L,   # el shell arrancó
  ".nav-link"     = 7L,   # las 7 secciones
  ".progress-bar" = 8L,   # el mapa del curso: una barra por sesión
  ".card"         = 4L    # las tarjetas del Inicio
)

.JS_COLECTOR <- "
  window.__sda_errores = [];
  window.addEventListener('error', function (e) {
    window.__sda_errores.push('error: ' + (e.message || e.type));
  });
  window.addEventListener('unhandledrejection', function (e) {
    window.__sda_errores.push('promesa: ' + e.reason);
  });
  (function () {
    var original = console.error;
    console.error = function () {
      window.__sda_errores.push('console: ' +
        Array.prototype.join.call(arguments, ' '));
      original.apply(console, arguments);
    };
  })();
"

.puerto_libre <- function(desde = 8801, hasta = 8899) {
  for (p in desde:hasta) {
    libre <- tryCatch({
      con <- suppressWarnings(socketConnection("127.0.0.1", port = p,
                                               open = "r", blocking = TRUE,
                                               timeout = 0.3))
      close(con); FALSE
    }, error = function(e) TRUE)
    if (libre) return(p)
  }
  stop("No se encontró un puerto libre")
}

# shinylive monta la app dentro de un <iframe>, así que contar sobre el
# documento raíz da siempre cero. Los iframes de shinylive son same-origin
# (srcdoc), de modo que su contentDocument sí es accesible desde el padre.
.JS_CONTAR <- "
  (function (selector) {
    var total = document.querySelectorAll(selector).length;
    document.querySelectorAll('iframe').forEach(function (marco) {
      try { total += marco.contentDocument.querySelectorAll(selector).length; }
      catch (e) { /* iframe de otro origen: se ignora */ }
    });
    return total;
  })(%s)
"

.contar <- function(sesion, selector) {
  resultado <- sesion$Runtime$evaluate(
    sprintf(.JS_CONTAR, jsonlite::toJSON(selector, auto_unbox = TRUE)),
    returnByValue = TRUE)
  as.integer(resultado$result$value %||% 0L)
}

# Errores que shinylive y Shiny pintan DENTRO del iframe. La consola del padre
# no los ve, así que hay que leer el DOM del hijo.
.JS_ERRORES_DOM <- "
  (function () {
    var selectores = ['.shiny-output-error', '.shinylive-error',
                      '.shiny-output-error-validation'];
    var salida = [];
    var recolectar = function (doc) {
      selectores.forEach(function (s) {
        doc.querySelectorAll(s).forEach(function (nodo) {
          var t = (nodo.innerText || nodo.textContent || '').trim();
          if (t) salida.push(s + ' :: ' + t.slice(0, 300));
        });
      });
    };
    recolectar(document);
    document.querySelectorAll('iframe').forEach(function (marco) {
      try { recolectar(marco.contentDocument); } catch (e) {}
    });
    return JSON.stringify(salida);
  })()
"

verificar_bundle <- function(destino = ruta_app("docs"), espera = ESPERA_WEBR) {
  indice <- file.path(destino, "index.html")
  if (!file.exists(indice))
    stop("No hay bundle en ", destino, ". Construilo con: ",
         "Rscript -e 'source(\"learn/build.R\"); construir_bundle()'")

  puerto <- .puerto_libre()
  servidor <- processx::process$new(
    "python3", c("-m", "http.server", as.character(puerto),
                 "--directory", normalizePath(destino)),
    stdout = "|", stderr = "|")
  on.exit(try(servidor$kill(), silent = TRUE), add = TRUE)
  Sys.sleep(1.5)

  url <- sprintf("http://127.0.0.1:%d/index.html", puerto)
  cat(sprintf("[bundle] %s · hasta %ds esperando a webR\n", url, espera))

  sesion <- chromote::ChromoteSession$new()
  on.exit(try(sesion$close(), silent = TRUE), add = TRUE)
  sesion$Runtime$enable()
  sesion$Page$enable()
  # El colector se instala ANTES de navegar: los errores de arranque de webR
  # ocurren antes de que se pueda escuchar de otra forma.
  sesion$Page$addScriptToEvaluateOnNewDocument(source = .JS_COLECTOR)
  sesion$Page$navigate(url, wait_ = TRUE)

  # Sondeo en vez de esperar `load`: lo que importa es que la app pinte.
  limite <- Sys.time() + espera
  repeat {
    conteos <- lapply(names(ESPERADOS), function(s) .contar(sesion, s))
    names(conteos) <- names(ESPERADOS)
    listo <- all(vapply(names(ESPERADOS),
                        function(s) conteos[[s]] >= ESPERADOS[[s]], logical(1)))
    if (listo || Sys.time() > limite) break
    Sys.sleep(3)
  }

  errores <- tryCatch({
    crudo <- sesion$Runtime$evaluate(
      "JSON.stringify(window.__sda_errores || [])", returnByValue = TRUE)
    unlist(jsonlite::fromJSON(crudo$result$value %||% "[]"))
  }, error = function(e) character(0))
  if (is.null(errores)) errores <- character(0)
  # Ruido del entorno, no de la app.
  errores <- errores[!grepl("favicon|DevTools listening|sourcemap",
                            errores, ignore.case = TRUE)]

  errores_dom <- tryCatch({
    crudo <- sesion$Runtime$evaluate(.JS_ERRORES_DOM, returnByValue = TRUE)
    unlist(jsonlite::fromJSON(crudo$result$value %||% "[]"))
  }, error = function(e) character(0))
  if (is.null(errores_dom)) errores_dom <- character(0)
  errores <- c(errores, errores_dom)

  cat("[bundle] conteos en el DOM:\n")
  for (s in names(ESPERADOS))
    cat(sprintf("    %-16s %3d  (esperado >= %d)%s\n", s, conteos[[s]],
                ESPERADOS[[s]],
                if (conteos[[s]] >= ESPERADOS[[s]]) "" else "   FALLA"))

  if (length(errores)) {
    cat("[bundle] errores de consola:\n")
    for (e in utils::head(errores, 15)) cat("    ", e, "\n")
  }

  ok <- listo && length(errores) == 0
  cat(sprintf("[bundle] %s\n", if (ok) "OK" else "FALLA"))
  invisible(ok)
}

# Solo se autoejecuta si es EL script invocado por Rscript.
.invocado_directamente <- function(nombre) {
  args <- commandArgs(trailingOnly = FALSE)
  archivo <- sub("^--file=", "", args[grepl("^--file=", args)])
  length(archivo) > 0L && basename(archivo[1]) == nombre
}

if (.invocado_directamente("verificar_bundle.R")) {
  if (!isTRUE(verificar_bundle())) quit(status = 1L)
}
