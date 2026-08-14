# Convenciones — SDA Lab

Reglas de ingeniería de `learn/`. Son **verificables**, no aspiracionales: cada
una tiene un script en `learn/R/pruebas/` que la comprueba, o una razón
explícita de por qué no se puede automatizar todavía.

Hereda las invariantes S1–S8 de `libs/sdd.md` y endurece S4.

---

## C1 · Español en todo lo nuestro

**Por qué**: al abrir cualquier archivo, lo que está en español es nuestro y lo
que está en inglés viene de una librería. Eso hace legible la frontera entre
"lo que escribimos" y "lo que llamamos", tanto para humanos como para agentes.

| Elemento | Regla | Ejemplo |
|---|---|---|
| Funciones | verbo español, `snake_case`, ASCII sin tildes | `graficar_roc()`, `validar_compatibilidad()` |
| Argumentos y campos | español ASCII | `semilla`, `corrida$metricas$exactitud` |
| Archivos y carpetas | español | `graficos/`, `logica/`, `nucleo/` |
| IDs de módulo Shiny | español | `mod_fuente_ui("fuente")` |
| Claves de artefacto | español ASCII, minúsculas | `f4.desempeno.roc` |
| Comentarios, UI, docs | español **con** tildes | `"Tamaño de muestra"` |
| Llamadas a librería | quedan en inglés | `prcomp()`, `renderPlot()`, `nav_panel()` |

Sin tildes ni `ñ` en identificadores: `tamano_muestra`, no `tamaño_muestra`.
Con tildes en todo lo que lee un humano.

Verifica: `Rscript learn/R/pruebas/verificar_idioma.R`

---

## C2 · Responsabilidad única, techo de 300 LOC

**Por qué**: un archivo que hace una sola cosa se lee entero de una sentada, se
prueba sin montar el mundo, y un agente lo puede cargar en contexto sin gastar
la mitad de su ventana.

- Un archivo = una responsabilidad nombrable **en una frase**. Esa frase va en
  la cabecera del archivo.
- Techo duro: **300 LOC**. Objetivo: 80–150.
- Un módulo de UI por **subsección**, no por fase. `f1_fuente.R` y
  `f1_calidad.R` son archivos distintos.
- Al acercarse al techo, partir por eje natural (por subsección, por familia de
  gráficos), **nunca** por "parte 1 / parte 2".

Verifica: `Rscript learn/R/pruebas/verificar_loc.R`

---

## C3 · Lógica y presentación, separadas sin excepción

Hereda S1 de `libs/sdd.md`.

| Carpeta | Contiene | Prohibido |
|---|---|---|
| `R/nucleo/` | registro, estado, contratos, claves, exportación | — |
| `R/logica/` | funciones **puras** de cálculo | `input`, `reactive`, `session`, `output` |
| `R/graficos/` | funciones **puras** que devuelven un `ggplot` | ídem |
| `metodos/` | una función `ajustar_*()` pura por método | ídem |
| `R/ui/` | módulos Shiny; solo cablean inputs → funciones puras | estadística |

Regla operativa: si borrás Shiny del proyecto, todo lo que hay en `logica/`,
`graficos/` y `metodos/` debe seguir corriendo con `Rscript`.

---

## C4 · Layout: tabs y toggles, no columnas fijas

El tríptico **entrada → proceso → resultado** es una invariante *lógica*, no
tres columnas literales.

```
┌─ navbar ── ⌂ ① Datos ② Modelado ③ Ajuste ④ Evaluación ──── 🎨 ⚙ ⓘ ─┐
├──────────┬────────────────────────────────────────────────────────┤
│ ENTRADAS │  [ Fuente ][ Diccionario ][ Calidad ][ … ][ ▣ Análisis ]│ ← tabs
│ sidebar  │ ┌────────────────────────────────────────────────────┐ │
│ colapsa- │ │              RESULTADO (domina)                    │ │
│ ble      │ └────────────────────────────────────────────────────┘ │
│          │ ▸ ¿Cómo se lee?        (colapsado)                      │
│ controles│ ▸ ¿Por qué importa?    (colapsado)                      │
│ vivos    │ ▸ Contexto para el chat(colapsado)                      │
├──────────┴────────────────────────────────────────────────────────┤
│ franja de estado — solo valores que cambian                        │
└────────────────────────────────────────────────────────────────────┘
```

- Subsecciones → `bslib::navset_card_tab` (horizontal). Con más de 6, o si hay
  sub-sub-secciones → `navset_pill_list` (vertical a la izquierda).
- **Entradas** → `sidebar()` colapsable; los controles secundarios dentro de
  `accordion(open = FALSE)`.
- **Resultado** → cuerpo de la card. Máximo espacio, siempre.
- **Proceso / explicaciones** → `accordion_panel(open = FALSE)` debajo, o
  `popover()` en el encabezado si cabe en una línea.

Ninguna vista construye estas piezas a mano: todas salen de
`R/ui/ui_piezas.R`.

---

## C5 · Regla de lo estático

> Si un contenido **no cambia** en respuesta a los inputs de esta fase, se
> oculta en un toggle. Los píxeles son para lo que se mueve.

| Contenido | ¿Cambia con inputs? | Destino |
|---|---|---|
| Gráfico, métricas, tabla de resultados | sí | visible siempre |
| Franja de estado (n, p, % faltantes) | sí | visible, una línea |
| Fórmula del método, explicación del algoritmo | no | `accordion` colapsado |
| "¿Por qué es necesaria esta técnica?" | no | `accordion` colapsado |
| "¿Cómo se lee este gráfico?" | no | `accordion` colapsado |
| Ficha completa del método | no | modal o pestaña aparte |
| Definición de un símbolo | no | `tooltip()` sobre el símbolo |

---

## C6 · Los textos viven fuera del código

Ningún párrafo explicativo dentro de un `.R`.

- Un `.md` por artefacto en `learn/textos/`, nombrado por su clave:
  `textos/f1.analisis.histograma.md`.
- Contenido **genérico**: explica el gráfico, no los datos del usuario.
- Estructura fija de tres bloques:

```markdown
## Qué muestra
## Qué buscar
## Cuándo engaña
```

- Si el archivo no existe, `texto(clave)` devuelve un aviso discreto y **la UI
  no falla**. Los textos se escriben incrementalmente; son muchos.

Lo mismo para las fichas de método: `learn/fichas/<clave>.md`.

### Sin LaTeX en los textos

`commonmark` no renderiza matemáticas, y traer MathJax o KaTeX significaría una
dependencia de red que en el navegador (wasm, servido como archivos estáticos)
no está garantizada — además de JavaScript propio, que C10 prohíbe.

Un `$$\sum x_i$$` sin renderizar no es una fórmula: es ruido que estorba.
Entonces la notación se escribe con **Unicode y código**, igual que en
`notes/tree.md`:

| En vez de | Escribir |
|---|---|
| `$\lambda_i$` | `λᵢ` |
| `$\sum_{i=1}^{n} x_i$` | `Σᵢ xᵢ` |
| `$\lVert x - \mu \rVert^2$` | `‖x − μ‖²` |
| bloque `$$...$$` | bloque de código con la fórmula en una línea |

Para una fórmula que necesita aire, un bloque de código:

```
W = Σₖ Σ_{i ∈ Cₖ} ‖xᵢ − μₖ‖²
```

---

## C7 · Tablas siempre acotadas

Ninguna tabla vuelca todo. Se usa `tabla_paginada()` de `ui_piezas.R`, que
centraliza `pageLength = 10`, `scrollX`, `deferRender`, `filter = "top"` y, en
modo servidor, `server = TRUE`. Toda tabla lleva pie con "mostrando X de N".

---

## C8 · Muestreo visible en datos grandes

Por encima de **5.000 filas** los gráficos usan una muestra con semilla y
aparece el badge:

```
graficando 5.000 de 35.115 · muestra semilla 42 · [usar todo]
```

**Las métricas siempre se calculan sobre el total.** El umbral y la semilla
viajan al JSON de la corrida.

---

## C9 · Trazabilidad: toda salida sabe de dónde vino

Cada artefacto visual tiene una **clave estable** `fase.subseccion.artefacto`
registrada en `R/nucleo/claves.R` junto a sus rutas de gráfico, lógica y texto.

Cada panel de resultado expone un toggle "Contexto para el chat" con un bloque
seleccionable que trae clave, rutas, corrida, parámetros y métricas. Pegado en
una conversación, basta para reconstruir la derivación completa de un resultado.

`learn/MAPA.md` es el índice generado de todas las claves. Es el primer archivo
que lee un agente.

Verifica: `Rscript learn/R/pruebas/verificar_mapa.R`

---

## C10 · Sin JavaScript propio

`libs/sdd.md` S2b documenta cuatro bugs que pasaron render limpio y HTTP 200 y
solo aparecieron en la consola del navegador. JS propio es superficie que R no
puede testear.

En vez de "copiar al portapapeles": bloque seleccionable + `downloadHandler`.
Si más adelante duele de verdad, se añade `rclipboard` (una dependencia
testeada) antes que escribir JS a mano.

---

## C11 · La regla de las tres partes

Heredada de `projects/_template/R/run_headless.R`.

Todo hiperparámetro existe en **tres** lugares a la vez:

1. la función pura en `metodos/` o `logica/`,
2. el argumento de `correr()` en `run_headless.R`, incluido su bloque `params`,
3. el input en el módulo de UI.

Si falta uno, la app y el batch divergen en silencio.

---

## C12 · Los errores se muestran, no tumban la sesión

Patrón obligatorio en todo módulo, tomado de
`projects/_template/R/mod_main.R:78-101`:

```r
resultado <- reactive({
  req(entrada())
  validate(need(condicion, "Mensaje en español para el usuario."))
  tryCatch(calcular(entrada()), error = function(e) list(error = conditionMessage(e)))
})
```

---

## C13 · Toda aleatoriedad lleva semilla, y la semilla viaja

Ninguna llamada a `sample()`, `rnorm()`, `kmeans()` sin `semilla` explícita en
la firma. La semilla entra al JSON de la corrida. Un resultado que no se puede
reproducir no es un resultado.

---

## C14 · Verificación en dos harness, no uno

- `pruebas/test_headless.R` — lógica y contratos, sin GUI.
- `pruebas/test_app.R` — UI **y consola del navegador** (`app$get_logs()`).

Los dos son obligatorios (S2b). `test_headless.R` no puede ver lo que se rompe
del lado del cliente: un `conditionalPanel` mal escrito deja el servidor
contento, responde 200, y la funcionalidad queda muerta en silencio.

Ambos harness incluyen **aserciones positivas** (que el contenido esperado esté
presente), no solo ausencia de errores.

---

## Cómo verificar todo

```bash
Rscript learn/R/pruebas/verificar_loc.R      # C2
Rscript learn/R/pruebas/verificar_idioma.R   # C1
Rscript learn/R/pruebas/verificar_mapa.R     # C9
Rscript learn/R/pruebas/test_headless.R      # C3, C11, C13
Rscript learn/R/pruebas/test_app.R           # C14
```
