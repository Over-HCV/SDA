# learn/R/nucleo/catalogo/poblar.R
#
# Responsabilidad: poblar el registro de métodos.
#
# Aquí no hay lógica: solo la llamada a los seis catálogos por macro-tema del
# curso más el de métodos bloqueados. Cada uno vive en su propio archivo de
# esta carpeta para que crecer el temario no engorde un único fichero (C2).
#
# Se llama desde cargar_sda(), DESPUÉS de sourcear todo el árbol, para no
# depender del orden en que se cargaron los archivos.
#
# Orden: las sesiones del curso, tal como aparecen en guide-eda-26A.md.
#   1-2 herramientas básicas · 3 normal multivariada · 4 ACP
#   5 clustering · 6-7 regresión · 8 ANOVA
#
# Estado de cada método en el Hito 1: "pendiente" o "bloqueado". Ninguno es
# "activo" todavía porque `registrar_metodo()` exige una función `ajustar` para
# serlo, y esas llegan a partir del Hito 3.

poblar_catalogo <- function() {
  limpiar_registro()
  poblar_catalogo_basicos()
  poblar_catalogo_multivariada()
  poblar_catalogo_reduccion()
  poblar_catalogo_agrupamiento()
  poblar_catalogo_regresion()
  poblar_catalogo_anova()
  poblar_catalogo_bloqueados()
  invisible(length(claves_metodos()))
}
