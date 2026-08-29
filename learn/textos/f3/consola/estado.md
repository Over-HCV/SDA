## Para qué sirve

Ver el algoritmo mientras trabaja. Es la vista que convierte «ajustar» de una
caja negra que tarda un rato en una secuencia de decisiones que se pueden
mirar de a una.

## Qué muestra

Las observaciones proyectadas al plano, coloreadas por el grupo que tenían en
la iteración que estás reproduciendo. Con los botones **−1** y **+1**, o con
*Reproducir sola*, se recorre la traza que quedó registrada al ajustar.

El plano no es un resultado: es la proyección sobre las dos direcciones de
mayor varianza, elegida para que la partición se pueda dibujar. Los grupos
viven en todas las variables, no en estas dos.

## Qué buscar

- **Los colores cambiando de zona.** Cada iteración reasigna puntos y recentra:
  las fronteras se mueven hasta que dejan de moverse.
- **Cuántas iteraciones hacen falta.** Con un buen arranque suelen bastar dos o
  tres. Con inicialización aleatoria, muchas más, y eso se ve.
- **Los puntos que cambian de grupo al final.** Son los de la frontera, y son
  los mismos que van a salir con silueta baja en la fase 4.
- **Un grupo que se vacía y reaparece en otro lado.** Es el algoritmo
  reubicando un centroide que se quedó sin nadie.

## Cuándo engaña

**Esto es una reproducción, no un recálculo.** Lo que ves es exactamente la
traza que quedó guardada al ajustar; nada se recalcula al pulsar. Es
deliberado: un paso que se recalcula podría no coincidir con el resultado que
la corrida guardó, y entonces la vista enseñaría algo que no pasó.

**Dos dimensiones de muchas.** Dos grupos que en el dibujo se superponen pueden
estar perfectamente separados en una variable que la proyección no muestra. El
mapa es un mapa, no el territorio.

**El movimiento impresiona más de lo que dice.** Que los centroides caminen
mucho no significa que el resultado sea mejor: significa que el arranque era
malo. Lo que hay que juzgar es dónde terminan, no cuánto anduvieron.
