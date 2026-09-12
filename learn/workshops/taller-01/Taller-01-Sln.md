# Taller 01 · Solucionario

**Base:** `data/ORI.csv` · **Filas usadas en casi todo el taller:** las 118 del mediodía.

Este documento tiene tres caras por pregunta:

- **En el lab** — la ruta exacta dentro de SDA Lab: sección, subsección, controles.
  Donde dice *casilla* «Añadir», marcarla mete ese panel en el cuaderno que se
  descarga desde la pestaña **⤓ Informe**.
- **Por consola** — el mismo laboratorio sin navegador, con `learn/R/lab.R`.
  Cada comando devuelve una tabla; los gráficos también, porque `panel` imprime
  las capas ya calculadas en vez de dibujarlas (los bordes y alturas del
  histograma, los cinco números de la caja).
- **En R** — el código equivalente, autónomo, por si se responde el taller en un
  `.Rmd` propio. Es el mismo que emite el cuaderno exportado.

Los números están calculados sobre el archivo del repo. Si su copia de `ORI.csv`
difiere, cambian.

## Antes de empezar: el camino común

Todas las preguntas menos la 1 y la 3 se responden sobre los registros del
mediodía, así que el filtro se aplica **una vez** y queda puesto:

1. **① Datos → Fuente** → fuente `ori · meteorologico IDEAM` → **Cargar**.
   La franja de estado debe decir 4.543 filas × 18 columnas.
2. **① Datos → Filtro** → *Filtrar por columna* `Hora` → *Valores a conservar*
   `12:00` → **Aplicar filtro**.
   El panel pasa a decir **filas al cargar 4543 · filas ahora 118 · filas fuera 4425**,
   y la pila registra `filtro Hora en [12:00]`.

El filtro no destruye nada: la pila se reaplica siempre desde los datos crudos, y
**Deshacer la última** revive las 4.543 filas exactas.

**Por consola.** El filtro va como opción y se repite si hace falta, así que
cada comando es autónomo — no hay estado escondido entre invocaciones:

```sh
Rscript learn/R/lab.R datos --fuente ori --filtro Hora=12:00
```

Para no repetirlo en cada línea, conviene guardarlo:

```sh
ORI="--fuente ori --filtro Hora=12:00"
```

```R
datos <- read.csv("ORI.csv", sep = ";", dec = ".",
                  fileEncoding = "latin1", stringsAsFactors = FALSE)
names(datos) <- trimws(names(datos))   # el encabezado trae "Pronostico "
medio_dia <- datos[trimws(datos$Hora) == "12:00", ]
```

> La copia del curso viene en ISO-8859-1; la de `data/` del repo está convertida
> a UTF-8 (shinylive necesita UTF-8 para meter el CSV en el bundle wasm). Si usa
> la del repo, quite el `fileEncoding`.

---

## Parte 1. Fundamentos estadísticos

### Pregunta 1 · UE, variables y registros del mediodía

**En el lab.** ① Datos → **Fuente**, sin filtrar todavía: la franja de estado y el
pie de la vista previa dan filas y columnas. Después de aplicar el filtro, el
panel de **Filtro** da el conteo del mediodía. *Casilla:* Vista previa.

**Respuesta.** La tabla tiene **4.543 filas y 18 columnas**: 4.543 unidades
estadísticas —cada una es *una medición en un municipio a una hora concreta*— y
18 variables. A medio día (`Hora = "12:00"`) hay **118 registros**, uno por cada
uno de los 59 municipios en cada una de las 2 fechas de la base.

**Por consola.** `Rscript learn/R/lab.R datos $ORI` imprime el encabezado
`ori · 118 filas × 18 columnas` y la pila aplicada.

```R
dim(datos)                                    # 4543   18
nrow(medio_dia)                               # 118
```

### Pregunta 2 · Pronóstico más y menos frecuente al mediodía

**En el lab.** ① Datos → **Balanceo** → *Clase* `Pronostico`: el panel
«Frecuencias por clase» es la tabla de frecuencias con su gráfico de barras.
*Casilla:* Frecuencias por clase.

**Respuesta.** De las 8 categorías presentes al mediodía:

| Pronóstico | n |
|---|---|
| Parcialmente Nublado | **63** |
| Nublado | 31 |
| Parcialmente Nublado - Lluvia Fuerte | 6 |
| Parcialmente Nublado - Llovizna | 5 |
| Nublado - Llovizna | 4 |
| Nublado - Lluvia | 4 |
| Despejado | 3 |
| Parcialmente Nublado - Tormenta Ligera | **2** |

El más frecuente es **Parcialmente Nublado (63 de 118, el 53 %)** y el menos
frecuente **Parcialmente Nublado - Tormenta Ligera (2)**.

**Por consola.** `Rscript learn/R/lab.R frecuencias Pronostico $ORI`

```R
sort(table(medio_dia$Pronostico), decreasing = TRUE)
```

### Pregunta 3 · Escala y clase de cuatro variables

**En el lab.** ① Datos → **Diccionario**: una fila por columna, con *escala* y
*clase* editables. El lab las autodetecta y deja corregirlas — que es justo el
ejercicio.

**Respuesta.**

| Variable | Escala | Clase |
|---|---|---|
| Pronóstico | Nominal — las categorías no tienen orden | Cualitativa |
| Municipio | Nominal — es una etiqueta geográfica | Cualitativa |
| Temperatura | **Intervalo** — el 0 °C es convencional, no ausencia de temperatura | Cuantitativa continua |
| Velocidad del viento | **Razón** — el 0 mph sí es ausencia de viento | Cuantitativa continua |

> **Ojo con la autodetección.** El diccionario del lab marca `Temperatura` como
> *razón*, porque no puede saber que los grados centígrados son una escala de
> intervalo: eso es información del dominio, no de los datos. Corríjalo a mano en
> el Diccionario. La consecuencia es real, no cosmética: en escala de intervalo
> los cocientes no significan nada — 30 °C **no** es "el doble de calor" que
> 15 °C —, mientras que 3 mph sí es el triple de viento que 1 mph.

### Pregunta 4 · Descripción gráfica: cajas de temperatura y viento

**En el lab.** ① Datos → **▣ Análisis → Univariado** → *Variable* `Temperatura`,
panel «Diagrama de caja». Repetir con `Velocidad_del_Viento`.
*Casilla:* Diagrama de caja.

**Respuesta.**

| | Temperatura (°C) | Viento (mph) |
|---|---|---|
| Mínimo | 22,40 | 0,40 |
| Q1 | 28,82 | 1,00 |
| Mediana | 30,40 | 1,70 |
| Q3 | 31,30 | 2,175 |
| Máximo | 32,70 | 3,70 |
| RIC | 2,475 | 1,175 |
| Asimetría | −1,391 | +0,485 |

- **Centro.** La temperatura al mediodía se concentra alta: mediana 30,4 °C con
  la media (29,75 °C) por debajo. El viento es flojo: mediana 1,7 mph.
- **Dispersión.** La temperatura es más dispersa en unidades absolutas
  (RIC 2,475 °C frente a 1,175 mph), pero **relativa a su tamaño es mucho más
  estable**: el RIC es el 8 % de su mediana, contra el 69 % en el viento. Comparar
  las dos cajas a ojo engaña, porque están en unidades distintas.
- **Localización y forma.** La caja de la temperatura está pegada al extremo
  superior con el bigote inferior largo y 8 puntos atípicos por debajo
  (22,4 a 24,8 °C): asimetría negativa, unos pocos municipios fríos —los de
  mayor altitud— tiran la cola. El viento es levemente asimétrico a la derecha
  y **sin ningún atípico**.

**Por consola.** `Rscript learn/R/lab.R resumen Temperatura $ORI` da los 14
estadísticos, y `Rscript learn/R/lab.R panel f1.analisis.boxplot Temperatura $ORI`
devuelve la caja como tabla: `ymin`, `lower`, `middle`, `upper`, `ymax` y los
atípicos que dibujaría.

```R
boxplot(medio_dia$Temperatura, horizontal = TRUE, main = "Temperatura")
boxplot(medio_dia$Velocidad_del_Viento, horizontal = TRUE, main = "Viento")
```

### Pregunta 5 · Descripción numérica con `summary()`

**En el lab.** El panel «Resumen numérico», justo debajo de la caja: es
`summary()` más desviación, RIC y asimetría, con los estadísticos que la escala
declarada permite. *Casilla:* Resumen numérico.

**Respuesta.** Sí, concuerda, y es la comprobación que la pregunta busca: los
cinco números del `summary()` son exactamente los que dibuja la caja. La mediana
(30,40) queda por encima de la media (29,75) en la temperatura — la firma
numérica de la asimetría negativa que se ve en el bigote largo hacia abajo — y en
el viento pasa al revés (mediana 1,700 contra media 1,719), coherente con su cola
derecha. Ningún dato falta: las 118 filas están completas en las dos variables.

```R
summary(medio_dia$Temperatura)
summary(medio_dia$Velocidad_del_Viento)
```

### Pregunta 6 · Atípicos de Tukey en Presión y Punto de Rocío

**En el lab.** ① Datos → **Calidad** → *Criterio* `IQR (1,5 × RIC)` → *Columna*
`Presion`, y luego `Punto_de_Rocio`. El panel marca los puntos y el badge dice
«N atípicos de M». *Casilla:* Atípicos.

**Respuesta.**

| Variable | Límites de Tukey | Atípicos |
|---|---|---|
| Presión (hPa) | [1009,65 ; 1015,65] | **1** (el valor 1015,7) |
| Punto de Rocío (°C) | [13,45 ; 30,45] | **0** |

> Los límites de arriba salen de los cuartiles tipo 7, que es con lo que el
> panel dibuja la caja. `boxplot(x, plot = FALSE)` corta por **bisagras** y da
> [13,35 ; 30,55] en el Punto de Rocío: décimas de diferencia, mismo conteo. El
> cuaderno exportado usa la vía del enunciado (`$out`) y lo avisa en el chunk.

**La Presión presenta más atipicidades** — una, y por un margen mínimo: 1015,7
contra un límite de 1015,65, apenas 0,05 hPa fuera. El Punto de Rocío no tiene
ninguno pese a moverse en un rango mucho más ancho (16,5 a 29,9 °C), porque su
RIC también es ancho (4,25 °C) y el criterio de Tukey es relativo a la propia
dispersión de la variable, no a una escala absoluta.

**Por consola.** `Rscript learn/R/lab.R atipicos Presion $ORI` — imprime el
corte de Tukey y una fila por atípico, con su distancia al límite. Repetir con
`Punto_de_Rocio`.

```R
boxplot(medio_dia$Presion, plot = FALSE)$out          # 1015.7
boxplot(medio_dia$Punto_de_Rocio, plot = FALSE)$out   # numeric(0)
```

### Pregunta 7 · Dispersión con histogramas marginales

**En el lab.** ① Datos → **▣ Análisis → Bivariado** → *X* `Temperatura`,
*Y* `Velocidad_del_Viento`, y marcar **Histogramas marginales**. El panel compone
la nube con el histograma de cada variable en su borde. *Casilla:* Dispersión.

**Respuesta.** La nube no tiene estructura: para cualquier temperatura aparecen
vientos de todo el rango, y la banda de puntos no sube ni baja. Los marginales
cuentan lo suyo aparte —temperatura apilada arriba con cola a la izquierda,
viento con su moda cerca de 1 mph y cola a la derecha—, y esa es la razón de
verlos juntos: **dos variables pueden ser muy asimétricas cada una y aun así no
tener ninguna relación entre sí**. No parecen correlacionarse; la P8 lo confirma.

```R
completos <- complete.cases(medio_dia[, c("Temperatura", "Velocidad_del_Viento")])
x <- medio_dia$Temperatura[completos]; y <- medio_dia$Velocidad_del_Viento[completos]
hx <- hist(x, plot = FALSE); hy <- hist(y, plot = FALSE)
layout(matrix(c(2, 0, 1, 3), 2, 2, byrow = TRUE), widths = c(4, 1), heights = c(1, 4))
par(mar = c(4, 4, 1, 1))
plot(x, y, pch = 19, col = "#00000099", xlab = "Temperatura", ylab = "Viento",
     xlim = range(hx$breaks), ylim = range(hy$breaks))
par(mar = c(0, 4, 1, 1)); barplot(hx$counts, axes = FALSE, space = 0)
par(mar = c(4, 0, 1, 1)); barplot(hy$counts, axes = FALSE, space = 0, horiz = TRUE)
layout(1)
```

### Pregunta 8 · Covarianza y correlación de Pearson

**En el lab.** El mismo panel «Dispersión»: el bloque *Contexto* del pie trae
`covarianza`, `pearson`, `spearman` y `n`.

**Respuesta.**

| Medida | Valor | Unidades |
|---|---|---|
| Covarianza | **0,0472** | **°C · mph** — el producto de las unidades de las dos variables |
| Pearson (*r*) | **0,0263** | **ninguna** — es adimensional, siempre en [−1, 1] |

No parecen correlacionarse: *r* = 0,026 es prácticamente cero (p = 0,78, o sea que
ni siquiera se distingue del azar con 118 datos), y Spearman da −0,011, así que
tampoco hay relación monótona no lineal escondida.

La pregunta de las unidades es la importante: **la correlación es la covarianza
estandarizada**, r = cov(x,y) / (s_x · s_y). Al dividir por las dos desviaciones,
las unidades se cancelan. Por eso la covarianza sola no se puede interpretar —su
0,0472 °C·mph no dice si es mucho o poco, y cambiaría de valor si midiéramos el
viento en km/h— mientras que r es comparable entre cualquier par de variables.

**Por consola.** `Rscript learn/R/lab.R asociacion Temperatura Velocidad_del_Viento $ORI`
— devuelve n, covarianza, Pearson, Spearman y el p-valor, con la columna de
unidades al lado, que es la mitad de la pregunta.

```R
cov(medio_dia$Temperatura, medio_dia$Velocidad_del_Viento)   # 0.04718528
cor(medio_dia$Temperatura, medio_dia$Velocidad_del_Viento)   # 0.02627245
```

### Pregunta 9 · ¿Univariados, bivariados o multivariados?

**Respuesta.** **Multivariados.** Sobre cada unidad estadística —una medición en
un municipio a las 12:00— se registran 18 variables simultáneas, y las 118
observaciones comparten esa estructura. Que en las preguntas 4 a 6 se mire una
variable por vez (análisis *univariado*) y en las 7 y 8 se miren dos (análisis
*bivariado*) no cambia la naturaleza de los datos: describe qué corte se está
haciendo sobre ellos. Los datos son multivariados; el análisis es lo que va
cambiando de dimensión.

---

## Parte 2. Estimación de la densidad

### Pregunta 10 · Densidad de la Temperatura: ¿normal?

**En el lab.** ① Datos → **▣ Análisis → Univariado** → *Variable* `Temperatura`.
Tres paneles responden esto: «Histograma» (con *Superponer densidad* marcado),
«Densidad kernel» y «Q-Q normal», que trae la prueba de Shapiro-Wilk.
*Casillas:* Histograma, Densidad, Q-Q normal.

**Respuesta.** **No.** Las tres vistas coinciden:

- El histograma y la KDE (h = 0,636) muestran una distribución **asimétrica a la
  izquierda** (asimetría −1,391), con la masa apilada entre 29 y 32 °C y una cola
  larga hacia los 22 °C. Una normal es simétrica.
- El Q-Q se despega de la recta en el extremo inferior: los 8 municipios fríos
  quedan muy por debajo de lo que predice la normal.
- Shapiro-Wilk: **W = 0,860, p = 3,4 × 10⁻⁹**. Se rechaza la normalidad de forma
  contundente.

La explicación de fondo es que estos 118 datos no son una población homogénea:
mezclan municipios de llanura con municipios de altura, y esa mezcla produce la
cola izquierda.

**Por consola.** `Rscript learn/R/lab.R normalidad Temperatura $ORI` da media,
desviación, asimetría, curtosis, el ancho de banda de la KDE y Shapiro-Wilk con
su veredicto. Para ver el histograma como tabla:
`Rscript learn/R/lab.R panel f1.analisis.histograma Temperatura $ORI`.

```R
hist(medio_dia$Temperatura, freq = FALSE, breaks = 20)
lines(density(medio_dia$Temperatura), lwd = 2)
qqnorm(medio_dia$Temperatura); qqline(medio_dia$Temperatura, col = "firebrick")
shapiro.test(medio_dia$Temperatura)
```

### Pregunta 11 · Densidad de la Presión: ¿simétrica?

**En el lab.** Igual que la 10, con *Variable* `Presion`.

**Respuesta.** **No es simétrica: tiene asimetría positiva (a la derecha).**

- Coeficiente de asimetría **+0,838**, de signo opuesto al de la temperatura.
- Media 1012,78 hPa **por encima** de la mediana 1012,50: la regla de bolsillo de
  la cola derecha. Los cuartiles lo confirman — de Q1 a la mediana hay 0,6 hPa,
  de la mediana a Q3 hay 0,9.
- La KDE (h = 0,385) sube rápido desde 1010,9, hace su moda cerca de 1012 y baja
  despacio hasta el 1015,7 que la P6 marcó como atípico. Ese único valor extremo
  es el que estira la cola.
- Shapiro-Wilk: W = 0,927, p = 7,2 × 10⁻⁶, tampoco normal.

**Por consola.** `Rscript learn/R/lab.R normalidad Presion $ORI`

```R
hist(medio_dia$Presion, freq = FALSE, breaks = 20)
lines(density(medio_dia$Presion), lwd = 2)
mean(medio_dia$Presion) - median(medio_dia$Presion)   # > 0: cola a la derecha
```

### Pregunta 12 · KDE del viento contra la normal ajustada

**En el lab.** ① Datos → **▣ Análisis → Univariado** → *Variable*
`Velocidad_del_Viento`, y marcar **Superponer normal (media y desvío)**. La
casilla dibuja N(media, desvío) estimada de los propios datos sobre la KDE, en
línea punteada. *Casilla:* Densidad.

**Respuesta.** El modelo normal ajustado es **N(1,719 ; 0,789)**, y **se aproxima
sólo de lejos**: acierta el centro y el ancho general, pero falla en la forma por
tres motivos visibles en el gráfico.

1. **La KDE es asimétrica** (+0,485) y multimodal en la zona de 1 a 2 mph, con más
   de una joroba; la normal es una sola campana simétrica.
2. **La normal pone masa donde no puede haber datos.** Con media 1,719 y desvío
   0,789, la normal asigna un 1,5 % de probabilidad a viento negativo. La
   velocidad del viento es una magnitud de razón acotada por 0: eso es imposible.
   Es el defecto conceptual del ajuste, no un detalle de la muestra.
3. Shapiro-Wilk: W = 0,962, **p = 0,0019**. Se rechaza la normalidad, aunque el
   rechazo es mucho menos rotundo que el de la temperatura — coherente con que
   aquí las dos curvas al menos se parecen.

**Por consola.** `Rscript learn/R/lab.R normalidad Velocidad_del_Viento $ORI`

```R
v <- medio_dia$Velocidad_del_Viento
plot(density(v), lwd = 2, main = "KDE contra la normal ajustada")
curve(dnorm(x, mean(v), sd(v)), add = TRUE, col = "firebrick", lty = 2, lwd = 2)
shapiro.test(v)
pnorm(0, mean(v), sd(v))    # 0.0147: masa normal en valores imposibles
```

---

## Llevarse el cuaderno

Con las casillas «Añadir» marcadas a lo largo del taller, la pestaña **⤓ Informe**
del navbar arma un `.Rmd` con una sección por panel: su texto explicativo, los
parámetros con que se produjo y el código R que lo redibuja. Se descarga con
**Cuaderno .Rmd**, y a su lado conviene bajar **Datos actuales (CSV)** —los datos
ya filtrados— salvo que se use `ORI.csv` directamente, que es lo que el cuaderno
hace por defecto para esta fuente.

Cada sección deja el renglón de la interpretación en blanco a propósito: el
gráfico lo pone la máquina, la lectura la pone quien responde el taller.

El mismo cuaderno se arma sin abrir la app:

```sh
Rscript learn/R/lab.R cuaderno f1.analisis.boxplot,f1.analisis.dispersion \
  $ORI --salida taller-01.Rmd
```

`Rscript learn/R/lab.R casillas` lista las 18 claves que se pueden pedir.

## Guardar la sesión en vez de repetir los clics

Lo que se arma para responder el taller —la fuente `ori`, el filtro de
mediodía, `Temperatura` declarada de **intervalo** en el Diccionario y los
catorce paneles marcados— es una **sesión**, y se guarda en un archivo:

```sh
Rscript learn/R/lab.R sesion \
  f1.fuente.vista_previa,f1.balanceo.frecuencias:Pronostico,... \
  --fuente ori --filtro Hora=12:00 --escala Temperatura=intervalo \
  --salida learn/sesiones/taller-01.json
```

Ese archivo (8 KB, sin datos adentro: la fuente se recarga) es el del repo, y
sirve de tres formas:

```sh
# el cuaderno, sin volver a listar los paneles
Rscript learn/R/lab.R cuaderno --sesion learn/sesiones/taller-01.json \
  --salida learn/workshops/taller-01/taller-01.Rmd

# la app abierta con todo puesto
SDA_SESION=learn/sesiones/taller-01.json \
  Rscript -e 'shiny::runApp("learn/R/app.R")'
```

y en el navegador, `?sesion=sesiones/taller-01.json`. Desde
la app, ⚙ Objetos → **Exportar JSON** guarda la sesión e **Importar** la
devuelve: vuelven el filtro, el diccionario declarado y las casillas marcadas.

Las lecturas de cada panel se escriben en la pestaña ⤓ Informe (una caja de
texto por panel) o directamente en el campo `nota` del JSON: el cuaderno las
pone en el lugar del recordatorio.
