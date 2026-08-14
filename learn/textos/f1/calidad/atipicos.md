## Para qué sirve

Decidir qué hacer con los valores extremos: corregirlos, dejarlos, o cambiar a
un método robusto que no dependa de ellos. Lo que no se decide acá se decide
solo más adelante, y casi siempre mal.

## Qué muestra

Cada observación contra su posición en el archivo, con los atípicos marcados
según el criterio elegido. Los tres criterios responden preguntas distintas:

$$
\begin{aligned}
\text{IQR} &: && x \notin \left[\, Q_1 - 1{,}5 \cdot \text{RIC} \;,\; Q_3 + 1{,}5 \cdot \text{RIC} \,\right] && \text{robusto, univariado} \\[4pt]
z &: && \frac{\lvert x - \bar{x} \rvert}{s} > 3 && \text{no robusto, univariado} \\[4pt]
\text{Mahalanobis} &: && d^2 > \chi^2_p(\alpha) && \text{multivariado}
\end{aligned}
$$

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
