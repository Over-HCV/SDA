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
- Lo que agrupa es la **carpeta**, no un prefijo en el nombre:
  `logica/datos/calidad.R`, no `logica/datos_calidad.R`; `graficos/univariado.R`,
  no `graficos/g_univariado.R`. Cuando tres archivos comparten prefijo, ese
  prefijo era una carpeta.

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

### C3b · La UI pregunta qué mide, no de qué método es

Corolario que el segundo método hizo obligatorio. Toda `ajustar_*()` devuelve
su lista con `class = c("ajuste_<clave>", "ajuste_sda")`, y contesta en
`R/logica/metricas_<familia>.R` las genéricas que declara
`R/logica/metricas.R`:

| Genérica | Qué contesta |
|---|---|
| `metricas_de_corrida()` | los números que van al JSON y a las value boxes |
| `tabla_resultado()` | la tabla que hay detrás del resultado principal (CSV) |
| `grafico_resultado()` | el gráfico que resume la corrida cuando cabe uno |
| `resumen_ajuste()` | los pares que van a la franja de estado |
| `lectura_resultado()` | la frase que interpreta, con el número a la vista |
| `coordenadas_2d()` | las observaciones en un plano |
| `etiquetas_ejes()` | cómo se llaman esos ejes |

Ningún módulo de `ui/` puede preguntar `if (clave == "acp")` ni leer un campo
que solo una familia tiene. Qué **cards** se dibujan sale del registro
(`metodo(clave)$artefactos` vía `panel_si_declara()`); qué **dicen** sale de
estas genéricas. El método por defecto de cada una falla y explica: un ajuste
sin clase es un método a medio escribir, y una vista vacía lo escondería.

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
│ vivos    │ ▸ contexto(colapsado)                      │
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

- Un `.md` por artefacto en `learn/textos/`, en la carpeta que dicta su clave:
  `f1.analisis.histograma` → `textos/f1/analisis/histograma.md`. La ruta la
  calcula `ruta_texto_de()`; con 79 artefactos una carpeta plana no se navega.
- Contenido **genérico**: explica el gráfico, no los datos del usuario.
- Estructura fija de cuatro bloques:

```markdown
## Para qué sirve
## Qué muestra
## Qué buscar
## Cuándo engaña
```

- Los bloques **no se muestran juntos**. `bloques_md()` parte el archivo por
  encabezado y cada mitad va a un sitio distinto:

| Bloque | Dónde sale | Responde |
|---|---|---|
| Para qué sirve | sello ⓘ del encabezado | qué decisión alimenta esta card |
| Qué muestra · Qué buscar · Cuándo engaña | «¿Cómo se lee?», plegado en el pie | cómo interpretarla |

  El sello ⓘ **no repite la traza**: clave y rutas ya están completas en el
  bloque «Contexto», y las 25 cards lo ofrecen. Un metadato mostrado dos veces
  no es redundancia inofensiva, es una card que desperdicia el único lugar
  donde cabía otra cosa.

- «Para qué sirve» son **dos o tres frases**: entra en un popover.
- Si el archivo o el bloque no existen, `texto()` y `texto_bloque()` devuelven
  un aviso discreto y **la UI no falla**. Los textos se escriben
  incrementalmente; son muchos. Un `.md` viejo de tres bloques sigue
  funcionando: se pierde el sello, no la card.

Lo mismo para las fichas de método: `learn/fichas/<clave>.md`.

### LaTeX en los textos

**Se escribe LaTeX, y se ve como LaTeX.** `$...$` en línea, `$$...$$` en
bloque, con la sintaxis de siempre:

```markdown
La distancia de Mahalanobis es $d^2(x) = (x - \bar{x})^{\mathsf{T}} S^{-1} (x - \bar{x})$.

$$
W = \sum_{k=1}^{K} \sum_{i \in C_k} \lVert x_i - \mu_k \rVert^2
$$
```

Antes esto estaba prohibido y la notación se escribía con Unicode dentro de una
valla ` ``` `. Se cayó por dos razones: las fórmulas salían monoespaciadas y en
caja gris, indistinguibles del código R de al lado, y **no hay forma de escribir
una matriz** con subíndices Unicode.

Cómo funciona, porque el orden importa:

1. `proteger_formulas()` (`R/nucleo/formulas.R`) saca las fórmulas del markdown
   **antes** de commonmark y deja marcadores alfanuméricos.
2. commonmark convierte el resto.
3. `restaurar_formulas()` reinyecta el TeX literal en `<div class="formula-bloque">`
   o `<span class="formula-linea">`.
4. KaTeX los pinta en el cliente.

El paso 1 no es una optimización: **CommonMark se come el `\\`**, que es el
separador de filas de una matriz, y lee el `_` de un subíndice como énfasis. Un
`\begin{pmatrix}` que atraviese el parser de markdown llega roto al navegador,
sin error y sin aviso. Hay una aserción dedicada a eso en `test_headless.R`.

Sigue habiendo vallas ` ``` `, y son para lo que siempre fueron: **código R** y
enumeraciones. Una fórmula en una valla es un error de formato.

Verifica: `Rscript learn/R/pruebas/test_app_piezas.R`

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

Cada panel de resultado expone un toggle "contexto" con un bloque
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

### La excepción: `learn/www/katex/enganche.js`

Es el único JS nuestro del proyecto, y está acá para que se discuta y no para
que se copie.

**Por qué no había alternativa.** El paquete R `katex` necesita V8, que no
compila en webR. MathJax o KaTeX por CDN sería una petición de red que el modo
wasm no garantiza. Queda vendorizar KaTeX y llamarlo desde el cliente.

**Por qué es aceptable pese a C10.** Lo que C10 protege es que no haya lógica
que R no pueda ver romperse. Acá:

- La lógica está en R y es **pura**: `R/nucleo/formulas.R` decide qué es una
  fórmula y la marca. `test_headless.R` la prueba sin navegador.
- El JS no decide nada. Recorre nodos ya marcados y llama a `katex.render()`.
- **Se asevera en un navegador de verdad**: `test_app_piezas.R` comprueba que
  hay nodos `.katex` pintados y que la consola queda limpia.
- `verificar_bundle.R` comprueba que los assets llegaron al bundle wasm.

Si aparece un segundo candidato a excepción, la vara es esa: lógica en R,
prueba en navegador, y escrito acá con su razón.

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

Sin GUI:

- `pruebas/test_headless.R` — núcleo, contratos, exportadores y el despacho
  por familia (C3b).
- `pruebas/test_fase1.R` — lógica y gráficos de la fase 1.
- `pruebas/test_<metodo>.R` — uno por método implementado, con sus gráficos.
- `pruebas/test_contrato.R` — el contrato S2 de la salida y la regla de las
  tres partes (C11), que sin `run_headless.R` no se puede comprobar.

En navegador **y con su consola** (`app$get_logs()`):

- `pruebas/test_app.R` — el flujo de la fase 1.
- `pruebas/test_app_<metodo>.R` — un archivo por método, recorriendo las fases
  2, 3 y 4. Cierra C11: mueve cada hiperparámetro para probar que además está
  enlazado. Uno solo parametrizado sonaba mejor y no lo era: cada método toca
  controles distintos y espera textos distintos, y el archivo unificado pasaba
  de 300 LOC para no compartir casi nada. (`test_app_metodo.R` es el del ACP;
  conserva el nombre porque es el que la documentación cita desde el Hito 3.)
- `pruebas/test_app_piezas.R` — la envoltura que comparten todas las cards:
  sello ⓘ, fórmulas y sidebar. Va aparte de `test_app.R` por C2: prueba las
  piezas transversales, no el recorrido de una fase.

Que un gráfico devuelva un `ggplot` no prueba nada: hay que construirlo con
`ggplot2::ggplot_build()`, que es donde de verdad se evalúa el `aes()`.

Los dos son obligatorios (S2b). `test_headless.R` no puede ver lo que se rompe
del lado del cliente: un `conditionalPanel` mal escrito deja el servidor
contento, responde 200, y la funcionalidad queda muerta en silencio.

Ambos harness incluyen **aserciones positivas** (que el contenido esperado esté
presente), no solo ausencia de errores.

Y una advertencia que costó una tarde: **en el navegador, que un texto esté en
el DOM no prueba que se vea.** `page_navbar` deja las cuatro fases montadas y
`conditionalPanel` oculta en vez de quitar, así que el título de una card
aparece aunque su método no la declare, y el log de la fase 3 hace casar un
patrón de la fase 4. Las aserciones de visibilidad van contra la bandera que la
gobierna (`bandera_artefacto()`); las de espera, contra un texto que solo
produzca la vista que se va a tocar. Y las opciones de un `selectInput` no
están en el DOM: selectize las guarda en JavaScript.

---

## Cómo verificar todo

```bash
Rscript learn/R/pruebas/verificar_loc.R      # C2
Rscript learn/R/pruebas/verificar_idioma.R   # C1
Rscript learn/R/pruebas/verificar_mapa.R     # C9
Rscript learn/R/pruebas/test_headless.R      # C3, C11, C13
Rscript learn/R/pruebas/test_fase1.R         # C3, C8, C13
Rscript learn/R/pruebas/test_acp.R           # C3, C13
Rscript learn/R/pruebas/test_contrato.R      # C11, C13
Rscript learn/R/pruebas/test_app.R           # C14
Rscript learn/R/pruebas/test_app_metodo.R    # C11, C14
Rscript learn/R/pruebas/test_app_piezas.R    # C6, C10, C14
```
