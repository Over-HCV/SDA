## Para qué sirve

Saber a quién le está mintiendo el dibujo. El plano factorial muestra dos
dimensiones de las `p` que había: la calidad de representación dice qué fracción
de cada variable es lo que estás viendo, y qué fracción se quedó afuera.

## Qué muestra

El `cos²` de cada variable en cada uno de los dos ejes, apilado. Es el cuadrado
de su correlación con la componente, que es también el cuadrado de la
coordenada de su flecha en el círculo:

$$
\cos^2_{ij} = r^2(x_i, \mathrm{CP}_j), \qquad
\cos^2_{\text{plano}} = \cos^2_{i1} + \cos^2_{i2}
$$

Una barra completa hasta 1 es una variable que vive enteramente en este plano.
Media barra es una variable de la que estás viendo la mitad. El apilado es a
propósito: lo que importa es la suma, y de paso se ve cuál de los dos ejes la
recoge.

## Qué buscar

- **Las barras cortas.** Son las variables que este plano no representa, y son
  el motivo para mirar CP1–CP3 antes de concluir nada sobre ellas. Es lo mismo
  que la flecha corta del círculo, con el número a la vista.
- **De qué eje es cada variable.** El color dice si la variable está en el
  horizontal, en el vertical, o repartida. Las repartidas son las que aparecen
  en diagonal en el biplot.
- **La barra más corta de todas.** Es la candidata a justificar una tercera
  componente: si al pasar a CP3 se completa, la tercera componente es "esa
  variable".
- **Todas las barras largas.** El plano representa bien el conjunto entero y dos
  componentes alcanzan.

## Cuándo engaña

**Calidad no es contribución.** Una variable puede estar perfectamente
representada en el plano y aportar poco a cada eje, y al revés. La calidad
pregunta "¿se ve?"; la contribución, "¿manda?".

**Un `cos²` bajo no invalida la variable, invalida su posición en el dibujo.**
Su flecha corta y su ángulo son casi ruido: no la interpretes ahí, mirala en
otro plano.

**Solo mide los dos ejes elegidos.** Cambiá el par de componentes y todas las
barras cambian. Es una propiedad del plano, no de la variable.

**Sobre S el `cos²` puede pasarse de 1.** Si descomponiste la covarianza, las
coordenadas no son correlaciones y la cuenta deja de ser una proporción. El
gráfico lo avisa en el subtítulo en vez de recortar el número y fingir que
cerró.
