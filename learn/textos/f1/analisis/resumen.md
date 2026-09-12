## Para qué sirve

Poner en números lo que la caja muestra en forma, y comprobar que las dos
cuentan la misma historia. Es la tabla que se cita cuando hay que escribir el
centro y la dispersión de una variable sin adjetivos.

## Qué muestra

Los cinco números de `summary()` —mínimo, Q1, mediana, media, Q3, máximo— más
la desviación estándar, el rango intercuartílico y la asimetría, con el conteo
de faltantes al lado.

Qué estadísticos aparecen **lo decide la escala declarada en el Diccionario**,
no el tipo de dato en memoria:

```
nominal  -> moda y tabla de frecuencias
ordinal  -> moda, mediana y cuantiles
intervalo -> todo menos los cocientes
razon    -> todo
```

La media de una nominal no sale porque no se calcula, no porque esté escondida.

## Qué buscar

- **Media contra mediana**: si la media es menor, hay cola a la izquierda; si
  es mayor, cola a la derecha. Es la regla de bolsillo de la asimetría, y se
  confirma con el coeficiente.
- **Desviación contra RIC**: cuando la desviación es mucho mayor de lo que el
  RIC sugiere, unos pocos valores extremos la están inflando.
- **Dispersión relativa**: un RIC de 2,5 °C sobre una mediana de 30 es el 8 %;
  el mismo 2,5 sobre una mediana de 1,7 sería otra variable completamente.
  Comparar dispersiones en unidades distintas no significa nada.
- **Faltantes**: cuántos son y si `summary()` los está descontando.

## Cuándo engaña

**Un resumen no distingue formas.** Dos variables con los mismos seis números
pueden tener una moda o dos. Por eso esta tabla va al lado del histograma y de
la densidad, no en su lugar.

**La media de una escala de intervalo se puede calcular; el cociente no.**
30 °C no es el doble de calor que 15 °C. El resumen no lo avisa: lo avisa la
escala que se declaró en el Diccionario.

**Con n chico los cuartiles se mueven mucho.** Por debajo de unas 20
observaciones, agregar o quitar un dato cambia Q1 y Q3 de forma visible, y la
tabla se lee con la misma desconfianza que la caja.
