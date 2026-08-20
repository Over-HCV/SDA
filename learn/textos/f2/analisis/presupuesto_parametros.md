## Para qué sirve

Preguntarse si los datos alcanzan para lo que estás pidiendo. Cada parámetro
que un modelo estima se paga con observaciones; este panel muestra la factura
antes de gastar.

## Qué muestra

Una barra por cada valor posible de `k`, con la cantidad de parámetros que ese
modelo estimaría. La línea punteada horizontal es `n`, tu número de
observaciones. El color resume la holgura:

- **verde** — cinco o más filas por parámetro;
- **amarillo** — entre una y cinco: cada parámetro se apoya en poca evidencia;
- **rojo** — más parámetros que observaciones.

Para un ACP con `k` componentes sobre `p` variables la cuenta es:

```
p·k − k(k−1)/2   cargas   +   p   medias del centrado
```

El término que se resta es la ortogonalidad: una vez fijada la primera
dirección, la segunda ya no es completamente libre.

## Qué buscar

- **Dónde la barra cruza la línea de n.** Ese es el `k` a partir del cual el
  modelo tiene más incógnitas que datos. Nada impide calcularlo; lo que no hay
  es motivo para creerle.
- **La curva de la barra.** Crece casi linealmente en `k` mientras `k` es
  pequeño y se aplana al acercarse a `p`, porque cada componente nueva tiene
  menos libertad que la anterior.
- **El salto entre k y k+1.** Si retener una componente más cuesta muchos
  parámetros y agrega poca varianza explicada —mirá el scree—, no vale la pena.

## Cuándo engaña

**Cinco filas por parámetro es una convención, no un teorema.** Hay problemas
donde tres bastan y otros donde veinte son pocas. El umbral está para obligar a
mirar, no para decidir.

**Contar parámetros no mide el sobreajuste.** Dos modelos con la misma cantidad
de parámetros pueden sobreajustar muy distinto según cómo estén restringidos.
La medida honesta sigue siendo el desempeño sobre datos que el modelo no vio,
y para eso está la partición de la fase 1.

**El ACP no sobreajusta como una regresión.** No hay una variable respuesta que
memorizar. Lo que pasa cuando `k` es demasiado grande es más sutil: las últimas
componentes describen ruido muestral y se leen como si fueran estructura.
