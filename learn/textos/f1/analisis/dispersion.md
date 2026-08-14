## Para qué sirve

Decidir si dos variables tienen relación, y de qué tipo, antes de resumirla en
un coeficiente. Todo lo que venga después —correlación, regresión— da por
hecha una forma; acá se comprueba que esa forma existe.

## Qué muestra

Cada observación como un punto en el plano de dos variables. Es el gráfico más
directo que existe y el que sostiene toda la idea de regresión: si hay relación,
se ve acá antes de ajustar nada.

El subtítulo trae dos números que conviene leer juntos:

```
r   = correlación de Pearson  → mide relación LINEAL
rho = correlación de Spearman → mide relación MONÓTONA
```

Cuando `|rho|` es bastante mayor que `|r|`, hay relación y no es una recta.

## Qué buscar

- **Forma**: recta, curva, abanico, nube sin estructura.
- **Dirección y fuerza**: cuánto se aprieta la nube alrededor de su tendencia.
- **Heterocedasticidad**: si la dispersión vertical crece con x, el abanico
  está avisando que la varianza no es constante.
- **Grupos**: dos nubes separadas piden colorear por una tercera variable.
- **Puntos con influencia**: los que están lejos en x mueven una recta ajustada
  mucho más que los que están lejos en y.

## Cuándo engaña

**El sobreploteo miente por saturación.** Con muchos puntos, la mancha negra
oculta dónde está la masa: cualquier zona llena se ve igual de negra que una
diez veces más densa. Las tres curas están en el panel: bajar la transparencia,
agregar jitter cuando los valores están redondeados, o pasar a conteo por celda,
que ya no dibuja puntos sino cuánta gente hay en cada casilla.

**r = 0 no significa "sin relación".** Significa "sin relación lineal". Una
parábola perfecta da r cercano a cero. Mirá la nube, no el número.

**Correlación no es causa, y encima puede ser de un tercero.** Dos variables
pueden moverse juntas porque una tercera las mueve a las dos. Colorear por esa
tercera suele deshacer el espejismo en un segundo.

**El muestreo cambia el dibujo, no la cuenta.** Si el badge de muestreo está
activo, los puntos son una muestra con semilla; `r` y `rho` se calcularon sobre
el total.
