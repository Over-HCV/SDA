## Para qué sirve

Mirar observaciones y variables en el mismo dibujo. Es el gráfico que contesta
"¿por qué esta observación cayó acá?": porque tiene valores altos en las
variables cuyas flechas apuntan hacia ahí.

## Qué muestra

Dos cosas superpuestas:

- **Los puntos** son las observaciones proyectadas sobre el plano de dos
  componentes: sus puntuaciones.
- **Las flechas** son las variables originales, en la dirección en que hacen
  crecer las componentes.

Tienen unidades distintas, así que las flechas van reescaladas por un factor
para que quepan junto a los puntos. Ese factor es una decisión de dibujo, no un
resultado, y por eso está escrito en el subtítulo.

## Qué buscar

- **Puntos alineados con una flecha.** Son las observaciones con valores altos
  en esa variable. Es la lectura directa del biplot.
- **Puntos en el extremo opuesto a una flecha.** Valores bajos en esa variable.
- **Grupos de puntos.** Si las observaciones se separan en el plano, el ACP
  encontró estructura sin que nadie le dijera que había grupos. Coloreá por una
  columna de grupo para confirmar si coincide con algo conocido.
- **Puntos muy lejos del resto.** Atípicos multivariados. Miralos: pueden estar
  torciendo las componentes ellos solos.
- **Flechas largas contra flechas cortas.** Las largas son las variables que
  gobiernan este plano.

## Cuándo engaña

**La escala de las flechas es arbitraria.** Cambiar el factor no cambia el
análisis, pero cambia mucho la impresión visual: con flechas grandes parece que
las variables dominan, con flechas chicas que los puntos están dispersos. No
leas magnitudes absolutas, leé direcciones y posiciones relativas.

**Las distancias entre puntos son aproximadas.** Están medidas en el plano, no
en el espacio original. Dos observaciones que se ven pegadas pueden estar lejos
en las componentes que no se dibujan. Mirá el scree: si CP1 y CP2 acumulan poco,
este gráfico representa poco.

**Es un gráfico denso.** Con muchas observaciones los puntos se apilan y el
biplot miente por sobreploteo, no por matemática. Bajá la transparencia o mirá
el mapa 2D solo.

**Superponer dos espacios es una aproximación, no una identidad.** El biplot es
una construcción útil y bien fundada, pero puntos y flechas no viven realmente
en la misma escala. Es un préstamo visual que hay que saber que se está
tomando.
