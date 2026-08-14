# learn/R/mapa.R
#
# Responsabilidad: generar learn/MAPA.md, el índice que un agente lee primero.
#
# Uso:  Rscript learn/R/mapa.R
#
# El mapa traduce lo que el usuario ve en pantalla a los archivos que lo
# produjeron. Es la mitad estática de la trazabilidad (C9); la otra mitad es
# el bloque de contexto que la app genera en vivo.
#
# Se regenera, no se edita a mano. verificar_mapa.R falla si quedó viejo.

.si_vacio <- function(x, alterno = "—") ifelse(is.na(x) | x == "", alterno, x)

.marca <- function(x) ifelse(x, "sí", "no")

.tabla_metodos <- function() {
  df <- metodos_df()
  c("| Clave | Método | Sesión | Objetivo | Estado | wasm | Ficha | Nodo teórico |",
    "|---|---|---|---|---|---|---|---|",
    sprintf("| `%s` | %s | %s | %s | %s | %s | `fichas/%s.md` | `%s` |",
            df$clave, df$nombre, .si_vacio(as.character(df$sesion)),
            df$objetivo, df$estado, .marca(df$wasm), df$clave,
            .si_vacio(df$nodo)),
    "")
}

.tabla_artefactos <- function() {
  df <- artefactos_df()
  c("| Clave | Artefacto | Gráfico | Lógica | Texto |",
    "|---|---|---|---|---|",
    sprintf("| `%s` | %s | `%s` | `%s` | %s |",
            df$clave, df$titulo, .si_vacio(df$grafico), .si_vacio(df$logica),
            ifelse(df$hay_texto, sprintf("`%s`", df$texto), "*pendiente*")),
    "")
}

.tabla_bloqueados <- function() {
  claves <- filtrar_metodos(estado = "bloqueado")
  if (!length(claves)) return(character(0))
  filas <- lapply(claves, function(k) {
    m <- metodo(k)
    sprintf("| `%s` | %s | %s | %s |", m$clave, m$nombre, m$motivo,
            .si_vacio(m$puente))
  })
  c("## Métodos bloqueados", "",
    "No se pueden ejecutar aquí. Cada uno lleva un **puente**: la frase que",
    "lo conecta con algo que sí corre en el lab.", "",
    "| Clave | Método | Motivo | Puente |", "|---|---|---|---|",
    unlist(filas), "")
}

.resumen <- function() {
  estados <- resumen_catalogo()
  cobertura <- cobertura_textos()
  c("## Resumen", "",
    sprintf("- **Métodos**: %d registrados — %d activos, %d pendientes, %d bloqueados",
            length(claves_metodos()), estados[["activo"]],
            estados[["pendiente"]], estados[["bloqueado"]]),
    sprintf("- **Artefactos**: %d registrados", length(claves_artefactos())),
    sprintf("- **Textos escritos**: %d de %d", cobertura$textos_escritos,
            cobertura$textos_esperados),
    sprintf("- **Fichas escritas**: %d de %d", cobertura$fichas_escritas,
            cobertura$fichas_esperadas),
    "")
}

#' Genera el contenido de MAPA.md.
#' @return character() de líneas
generar_mapa <- function() {
  c(
    "<!-- GENERADO por learn/R/mapa.R. No editar a mano. -->",
    "",
    "# MAPA — índice de artefactos y métodos",
    "",
    "Traducción de lo que se ve en pantalla a los archivos que lo produjeron.",
    "Si te preguntan por un resultado, empezá por acá: buscá la clave, abrí",
    "primero la **lógica** (de ahí sale el número), después el **gráfico** (cómo",
    "se dibuja) y por último el **texto** (qué se le dijo al usuario).",
    "",
    "Todas las rutas son relativas a `learn/`.",
    "",
    .resumen(),
    "## Artefactos",
    "",
    "Clave: `fase.subseccion.artefacto`. Un texto *pendiente* significa que el",
    "`.md` todavía no está escrito; la UI lo avisa y no falla.",
    "",
    .tabla_artefactos(),
    "## Métodos",
    "",
    .tabla_metodos(),
    .tabla_bloqueados(),
    "---",
    "",
    "Regenerar: `Rscript learn/R/mapa.R`"
  )
}

escribir_mapa <- function(ruta = ruta_app("MAPA.md")) {
  writeLines(generar_mapa(), ruta, useBytes = TRUE)
  invisible(ruta)
}

# Solo se autoejecuta si es EL script invocado por Rscript, no cuando otro
# archivo lo sourcea para reutilizar sus funciones.
.invocado_directamente <- function(nombre) {
  args <- commandArgs(trailingOnly = FALSE)
  archivo <- sub("^--file=", "", args[grepl("^--file=", args)])
  length(archivo) > 0L && basename(archivo[1]) == nombre
}

if (.invocado_directamente("mapa.R")) {
  source("learn/R/cargar.R")
  cargar_sda(con_ui = FALSE)
  ruta <- escribir_mapa()
  cat(sprintf("[mapa] %s · %d métodos · %d artefactos\n", ruta,
              length(claves_metodos()), length(claves_artefactos())))
}
