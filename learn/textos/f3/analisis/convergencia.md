## Para qué sirve

Decidir si el resultado se puede usar. Un optimizador que no convergió
devuelve números igual, con la misma cara que uno que sí: esta es la card que
hay que mirar antes de creerle a cualquier otra de la fase.

## Qué muestra

El valor de la función objetivo en cada iteración del optimizador. Es el
equivalente honesto de la "curva de pérdida por época" de las redes
neuronales: en estadística multivariada clásica el optimizador también itera,
solo que las iteraciones no se llaman épocas.

Qué está bajando (o subiendo) depende del método:

| Método | Optimizador | Qué se mueve |
|---|---|---|
| k-medias | Lloyd | inercia intra-grupo `W`, baja |
| Mezclas gaussianas | EM | log-verosimilitud, **sube** |
| LASSO / Ridge | descenso por coordenadas | desviación penalizada, baja |
| Regresión logística | IRLS | log-verosimilitud, sube |
| MDS no métrico | SMACOF | *stress*, baja |

## Qué buscar

- **Por qué se detuvo.** Hay dos motivos y no son intercambiables. Si la curva
  se aplanó y el cambio quedó por debajo de la tolerancia, convergió. Si se
  cortó todavía bajando, se agotaron las iteraciones y el resultado está a
  medio camino: subí `maxit` y volvé a correr.
- **Cuántas iteraciones tardó.** Si convergió en tres, el problema era fácil o
  la tolerancia demasiado laxa. Si tardó doscientas, algo está mal
  condicionado: revisá el escalado.
- **La forma del descenso.** Una caída fuerte al principio y una cola larga y
  plana es lo normal y es buena señal. Escalones o mesetas intermedias indican
  que el optimizador quedó atrapado un rato antes de encontrar salida.
- **Que no suba lo que debería bajar.** En Lloyd y en EM eso es imposible por
  construcción. Si lo ves, hay un error en el código, no en los datos.

## Cuándo engaña

**Converger no es acertar.** Es lo más importante de este gráfico y lo que más
se malinterpreta. Una curva que baja suave hasta aplanarse demuestra que el
algoritmo encontró un **óptimo local** y nada más. Con otra semilla podría
haber terminado en un valor bastante mejor, con una curva igual de linda.

La forma de saberlo no está en esta curva: está en *Sensibilidad a la semilla*,
que superpone varios reinicios. Si todos aterrizan en el mismo valor, hay una
solución estable. Si se abren en abanico, el resultado que estás mirando es uno
entre muchos.

**La escala del eje vertical exagera o esconde.** Al final del ajuste las
mejoras son diminutas y en escala lineal la curva parece perfectamente plana
mucho antes de estarlo. Pasá a escala logarítmica para ver si de verdad se
detuvo o todavía estaba avanzando.

**Una curva bonita no dice nada sobre el ajuste.** Mide qué tan bien el
optimizador resolvió el problema que le planteaste, no si el problema era el
correcto. Un modelo mal especificado converge igual de bien.
