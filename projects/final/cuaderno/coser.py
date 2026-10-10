"""Cose los chunks de generado.Rmd (SDA Lab) en plantilla.Rmd.

Uso, desde esta carpeta:  python3 coser.py
Cada @@CHUNK n@@ de la plantilla se reemplaza por el n-ésimo panel de
generado.Rmd, sin tocarlo; @@CONFIG@@ y @@DATOS@@, por el chunk de
configuración y el de carga. Los chunks deben usarse en orden: el
generador escribe cada función una sola vez, en el primero que la usa.
"""
import re, sys

lineas = open("generado.Rmd", encoding="utf-8").read().split("\n")
chunks, actual = [], None
for linea in lineas:
    if actual is None and linea.startswith("```{r"):
        actual = [linea]
    elif actual is not None:
        actual.append(linea)
        if linea == "```":
            chunks.append("\n".join(actual))
            actual = None
config = [c for c in chunks if c.startswith("```{r configuracion")][0]
datos = [c for c in chunks if c.startswith("```{r cargar-datos")][0]
paneles = [c for c in chunks if c.startswith("```{r}")]

texto = open("plantilla.Rmd", encoding="utf-8").read()
usados = [int(n) for n in re.findall(r"@@CHUNK (\d+)@@", texto)]
if usados != sorted(usados):
    sys.exit("los chunks de la plantilla no van en el orden del generado")
for n in usados:
    if "no se dibuja" in paneles[n - 1]:
        sys.exit("el panel %d no tiene código para su método" % n)
texto = texto.replace("@@CONFIG@@", config).replace("@@DATOS@@", datos)
texto = re.sub(r"@@CHUNK (\d+)@@", lambda m: paneles[int(m.group(1)) - 1],
               texto)
open("clustering-cualitativo.Rmd", "w", encoding="utf-8").write(texto)
print("clustering-cualitativo.Rmd: %d paneles de %d" % (len(usados),
                                                       len(paneles)))
