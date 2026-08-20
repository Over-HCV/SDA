## Para qué sirve

Decidir cuántas componentes conservar. Es la pregunta que el ACP existe para
contestar —*¿cuántas dimensiones hacen falta de verdad?*— y este gráfico es
donde se contesta.

## Qué muestra

Las barras son la proporción de varianza que aporta cada componente, siempre
ordenadas de mayor a menor. La línea es el acumulado: cuánto llevás sumado al
retener hasta ahí. La línea punteada horizontal es el umbral de referencia, y
la vertical marca dónde pusiste el corte.

```
proporcion_j = λⱼ / Σᵢ λᵢ
```

Sobre la matriz de correlación la suma de los λ vale exactamente `p`, así que
una componente con λ mayor que 1 explica más que una variable original suelta.

## Qué buscar

- **El codo.** El punto donde el descenso deja de ser abrupto y se vuelve una
  pendiente suave. Todo lo que viene después aporta parecido entre sí, que es
  otra forma de decir que aporta ruido.
- **Cuánto lleva el acumulado en el codo.** Si el codo está en 3 componentes y
  ahí llevás 85 %, la decisión es fácil. Si llevás 40 %, el ACP te está diciendo
  que estos datos no se resumen bien en pocas dimensiones.
- **La primera barra sola.** Si capta más de la mitad, hay un factor dominante:
  casi todas las variables se mueven juntas.
- **Barras casi iguales.** Componentes con λ parecidos son direcciones
  intercambiables: la rotación entre ellas es arbitraria y sus cargas no se
  deben interpretar por separado.

## Cuándo engaña

**El codo casi nunca es evidente.** Es la trampa central de este gráfico. Con
datos reales suele haber un descenso continuo sin quiebre claro, y dos personas
razonables eligen `k` distinto. Por eso el corte lo ponés vos y se dibuja donde
lo pusiste, en vez de que la app finja que hay una respuesta.

**El umbral del 80 % es una costumbre, no un resultado.** Viene de la práctica,
no de la teoría. En algunos campos se usa 70, en otros 95.

**La regla de λ > 1 solo vale sobre R.** Sobre la matriz de covarianzas los λ
están en las unidades de tus variables y compararlos con 1 no significa nada.

**Varianza no es utilidad.** La componente que más varianza capta puede ser
irrelevante para lo que querés hacer después. Si el objetivo es discriminar
grupos, mirá el mapa 2D: a veces los grupos se separan en la tercera componente
y no en la primera.
