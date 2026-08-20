## Para qué sirve

Ver exactamente qué entra al modelo antes de ajustarlo. Un método no se aplica
a "los datos": se aplica a una matriz X con filas, columnas y roles decididos.
Esta tabla es esa decisión, escrita.

## Qué muestra

Las cuatro cifras que deciden si el ajuste tiene sentido:

- **Observaciones**: cuántas filas sobreviven. Las que tienen un faltante en
  alguna columna elegida quedan fuera, y acá se ve cuántas.
- **Variables**: cuántas columnas y cuáles.
- **Rango**: cuántas direcciones independientes hay de verdad. Si es menor que
  el número de variables, alguna columna es combinación lineal de las otras.
- **Filas por variable**: cuánta evidencia sostiene cada cosa que se va a
  estimar.

## Qué buscar

- **Rango menor que variables.** Es el aviso más importante de esta tabla. Pasa
  cuando una columna es proporcional a otra, cuando se incluyeron a la vez una
  variable y su cuadrado exacto, o cuando hay dummies que suman siempre 1. La
  matriz de covarianzas no se puede invertir y muchos métodos fallan con un
  mensaje incomprensible; acá el problema tiene nombre.
- **Filas descartadas.** Si al elegir una columna más se caen cuarenta filas,
  esa columna cuesta cuarenta observaciones. Puede valer la pena, o no.
- **Menos de cinco filas por variable.** No es un umbral sagrado, es el punto
  donde conviene preguntarse si el resultado va a decir algo sobre el mundo o
  solo sobre esta muestra.

## Cuándo engaña

**El rango se calcula sobre las filas completas.** Si los faltantes se llevaron
media tabla, el rango que ves es el de lo que quedó, no el de tus datos.

**Contar variables no es contar información.** Diez columnas casi idénticas dan
rango 10 y una sola dimensión útil. El rango detecta la dependencia *exacta*,
no la casi-dependencia; para esa, mirá el mapa de calor de correlaciones o el
scree del ACP.

**Que la matriz sea válida no significa que el modelo sea apropiado.** Esta
tabla dice que el cálculo se puede hacer, nada más. Si tiene sentido hacerlo lo
dice el semáforo de supuestos, en la pestaña de al lado.
