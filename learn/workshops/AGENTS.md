# AGENTS.md — Talleres AED (`learn/workshops/`)

Cómo se convierte una exploración de SDA Lab en el PDF que se entrega. Vale
para cualquier `taller-XX/`. Los comandos corren desde la carpeta del taller,
salvo donde se diga otra cosa.

## El flujo, de punta a punta

1. **El usuario explora en SDA Lab** y marca con «Añadir» los paneles que
   responden el taller, escribiendo su lectura en la pestaña ⤓ Informe.
2. **Descarga tres archivos** a `taller-XX/`: el cuaderno (`.qmd`), la
   selección (`.json`) y, si la fuente no es `ori`, el CSV de los datos.
   El enunciado del curso va en `Taller-XX.md`.
3. **El usuario manda el prompt**: corregir, completar y reescribir ese
   cuaderno hasta el entregable.
4. **Compilás** con `../template/build.sh`, revisás el PDF y reportás.

## Qué hay en cada carpeta

| Archivo | Qué es |
|---|---|
| `Taller-XX.md` | El enunciado. Manda: define el orden y qué pide cada pregunta. |
| `sda-lab-exploracion.qmd` | El cuaderno exportado, que se reescribe hasta ser el informe. |
| `seleccion-sda-lab.json` | La selección con las notas crudas del usuario, por si el `.qmd` se regenera. |
| `sesion-XX.json` | La sesión del lab (fuente, pila, diccionario, paneles), si se guardó. Opcional: sirve para reabrir el lab con todo puesto. |
| `build/` | Salida de latexmk. El entregable es `build/<nombre>.pdf`. |
| `<nombre>.tex` | Generado por quarto y **editable a mano**: `build.sh pdf` no lo pisa. |

Los datos viven en Kaggle (`overhcv/<slug>`), se bajan en el chunk
`cargar-datos` y caen a la copia local de `data/` si no hay red.

## Qué marcar en el lab al exportar

Las casillas «Qué lleva el cuaderno» vienen puestas para el entregable:
`ficha_datos`, `notas` y `plantilla_taller`. Eso evita el ruido que antes había
que borrar a mano (texto del lab, clave y hora del panel, tablas de estado y
de parámetros, encabezado y pie). Si hace falta el material de estudio, se
prenden `texto_esencial` y `texto_ampliado`. Por consola es lo mismo:

```bash
Rscript learn/R/lab.R cuaderno <claves> --fuente <f> --filtro Col=valor \
  --incluir texto_esencial --excluir plantilla_taller --salida taller-XX/x.qmd
```

## Reescribir el cuaderno: contenido

- **Una sección por pregunta y en el orden del enunciado.** Las notas del lab
  llegan en el orden en que se marcaron los paneles, que casi nunca es el de
  las preguntas, y suelen traer el número equivocado: hay que remapearlas
  leyendo `Taller-XX.md`. Título: `## Pregunta N --- Tema`.
- **Verificar cada cifra corriendo R antes de escribirla.** Las notas del
  usuario traen números de memoria, valores a medias y cuentas de otra
  variable. Nada entra al texto sin haberlo recalculado sobre la base.
- **No afirmar lo que el gráfico no sostiene.** Una moda que desaparece al
  duplicar el ancho de banda (`modas(x, 2)`) es ruido del suavizado, no
  bimodalidad; un atípico a 0.05 de la cerca se reporta con ese matiz.
- **Dejar nota de incertidumbre** cuando algo no se puede verificar con los
  datos (por ejemplo, atribuir un grupo frío a la altitud sin columna de
  altitud), en un bloque `> **Nota.**` aparte.
- **Definir cada término nuevo** en una línea: qué mide y para qué sirve.
- **Preferir lo que el enunciado pide.** Si no pide un Q-Q, no va un Q-Q.

## Reescribir el cuaderno: forma

- **Estilo del usuario**: usar la skill `estilo-redaccion-personal`. En corto:
  respuesta directa primero (`**¿…?** No, pues…`), oraciones largas unidas con
  conectores y no con comas, nunca coma antes de "y", mayúscula después de `:`
  y `;`, decimales y miles con punto, incisos `a. **Término.** Oración`.
- **Código**: ≤ 68 columnas (más ancho se sale del margen), un chunk por
  pregunta, `echo: true`.
- **`dos_columnas()`** solo cuando la salida es uno o dos números; el resto va como
  chunk normal.
- **Figuras**: pie que describe y concluye tras dos puntos. Los diagramas
  mermaid usan la paleta cálida (raíz `#2b2220`, grupos `#a6192e`, tipos
  `#f08a3c`, ejemplos `#fdecc0`).
- **Citas**: `\parencite{clave}` con las entradas de `template/bib/refs-taller.bib`
  (IDEAM, R, ggplot2, ggExtra, Tukey, Silverman, Sturges, Shapiro-Wilk,
  Pearson, Spearman). Antes de `\appendix` va `\imprimirbibliografia`.
- **Apéndice**: `tabla_documentacion()` arma la tabla de funciones usadas con
  enlace a su ayuda oficial.
- **Helpers**: `source("../template/R/taller.R")` trae `dos_columnas()`, `caja()`,
  `densidad()`, `modas()`, `g1()` y `tabla_documentacion()`. Lo que se repita
  en dos talleres se sube ahí.

## Compilar

```bash
cd learn/workshops/taller-XX
../template/build.sh                 # render (si falta el .tex) + pdf
../template/build.sh render --force  # regenerar el .tex tras editar el .qmd
../template/build.sh pdf             # recompilar el .tex editado a mano
```

También acepta destino: `template/build.sh all taller-02` desde `workshops/`.
Si solo hay un `.Rmd`, lo copia a `.qmd` (quarto dibuja mermaid solo en qmd).

**Importante**: tras editar el `.qmd` hay que correr `render --force`, porque
`build.sh` preserva el `.tex` para no pisar ediciones manuales. Un PDF que
"no cambió" casi siempre es esto.

## Antes de decir que está listo

1. `grep -c "Missing character" build/<nombre>.log` debe dar 0 y el log no
   debe traer `undefined` (citas o referencias sin resolver).
2. Leer el PDF: portada con integrantes, resumen, índice, las preguntas en
   orden, figuras visibles y tablas que no se salen del ancho.
3. Cotejar las cifras del texto contra las salidas de los chunks.
4. Reportar lo que quedó sin verificar y lo que se decidió omitir.

La metadata fija del curso (universidad, programa, integrantes, profesor) vive
en `template/common/meta-taller-es.tex`; lo del taller (título, fecha,
resumen, palabras clave) va en el YAML del `.qmd`.
