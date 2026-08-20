## Para qué sirve

Ver qué parámetro tardó en acomodarse. La curva de convergencia dice *cuándo*
se detuvo el optimizador; la trayectoria dice *qué* estuvo moviéndose hasta el
final.

## Qué muestra

Una línea por parámetro, contra la iteración. En el ACP los parámetros son las
cargas del autovector: cuánto pesa cada variable original en la componente que
se está estimando. Se ve al vector arrancar en una dirección al azar y girar
hasta quedarse quieto.

La línea horizontal en cero está para leer los signos: una carga que cruza el
cero cambió de lado durante el ajuste.

## Qué buscar

- **Las que se estabilizan primero.** Suelen ser las variables que dominan la
  componente. Su carga queda fija en las primeras iteraciones y ya no se mueve.
- **Las que siguen moviéndose al final.** Son las que el optimizador todavía
  estaba decidiendo cuando se detuvo. Si una carga aún tiene pendiente visible
  en la última iteración, subí el techo de iteraciones y mirá si cambia.
- **Cruces por cero.** Un parámetro que oscila alrededor de cero sin decidirse
  es una variable que no pertenece claramente a esta componente.
- **El arranque.** Las primeras iteraciones son un salto grande: el vector
  inicial es aleatorio y la primera multiplicación por S ya lo acerca mucho.
  Casi todo el trabajo pasa al principio; el resto es afinado.

## Cuándo engaña

**El signo global es arbitrario.** Un autovector y su opuesto describen el mismo
eje. La app fija el signo al final —la carga de mayor magnitud queda positiva—,
pero durante la iteración el vector puede aparecer volteado sin que eso
signifique nada.

**Solo se ve una componente por vez.** Las siguientes se estiman sobre la
matriz ya deflacionada, así que su trayectoria empieza de nuevo y no se puede
comparar directamente con la anterior.

**Con muchas variables el panel se vuelve ilegible.** Diez cargas ya son diez
líneas del mismo color aproximado. Ahí conviene mirar el gráfico de deltas, que
resume todas en un solo número por iteración.

**Estabilizarse no es converger al óptimo.** El vector puede quedarse quieto
porque de verdad llegó, o porque los valores propios son casi iguales y el
método avanza a paso de tortuga. La curva de deltas contra la tolerancia
distingue los dos casos.
