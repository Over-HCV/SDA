## Qué muestra

Cada observación contra su posición en el archivo, con los atípicos marcados
según el criterio elegido. Los tres criterios responden preguntas distintas:

```
IQR          fuera de [Q1 − 1.5·RIC , Q3 + 1.5·RIC]   robusto, univariado
z            |x − x̄| / s  por encima de 3            no robusto, univariado
Mahalanobis  d² por encima del cuantil χ²(p)          multivariado
```

Los dos primeros miran una columna; el tercero mira todas a la vez y encuentra
filas que ninguna columna por separado delata.

## Qué buscar

- **Puntos aislados muy lejos del resto**: candidatos a error de captura.
- **Grupos de atípicos juntos en el eje horizontal**: no son ruido, es un tramo
  del archivo distinto —otro año, otro instrumento, otro criterio de medición.
- **Muchos atípicos de un solo lado**: no hay error, hay asimetría. La
  transformación log suele hacerlos desaparecer sin borrar nada.
- **La diferencia entre criterios**: si z no marca nada y el RIC marca veinte,
  es porque la media y la desviación ya fueron arrastradas por los extremos.

## Cuándo engaña

**Atípico no es sinónimo de error.** El criterio es geométrico y no sabe nada
del fenómeno. Borrar por costumbre es la peor decisión posible: en muchos
estudios el atípico es el caso que motivó la investigación.

**z se enmascara a sí mismo.** La media y la desviación estándar se calculan
con los atípicos adentro, así que un valor extremo infla `s` y termina pareciendo
razonable. Con un solo extremo muy grande, ningún punto supera 3 desvíos.

**El 1,5 de Tukey es una convención, no un umbral óptimo.** Nada se rompe si lo
movés; solo cambia cuántos puntos se pintan.

**Mahalanobis exige covarianza invertible y datos completos.** Con colinealidad
exacta o con filas incompletas devuelve vacío, y eso no significa que no haya
atípicos.
