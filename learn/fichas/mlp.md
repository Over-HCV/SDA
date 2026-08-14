## Qué es

Capas de regresiones logísticas encadenadas. Cada **neurona** hace exactamente
lo mismo que ya viste: una combinación lineal de sus entradas seguida de una
función no lineal.

```
h  = σ(W₁ x + b₁)        capa oculta
ŷ  = σ(W₂ h + b₂)        salida
```

Lo único nuevo respecto a la regresión logística es la línea del medio: una
**capa oculta** que fabrica variables intermedias en vez de usar las originales.

## Por qué existe

La regresión logística traza una frontera recta. Si las clases no se separan
con una recta, no hay coeficientes que la salven — el problema no es la
estimación, es la familia de hipótesis.

Una capa oculta con `h` neuronas construye `h` nuevas variables, cada una una
proyección no lineal de las originales, y traza la frontera recta **en ese
espacio nuevo**. Vista desde el espacio original, la frontera es curva.

Ese es todo el truco. Lo demás es escala.

## Lo que sí se traslada del curso

| Concepto del curso | Su nombre en redes |
|---|---|
| Verosimilitud a maximizar | función de pérdida a minimizar |
| Newton-Raphson / IRLS | descenso por gradiente, Adam |
| Iteración del optimizador | época |
| Sobreajuste y sesgo-varianza | idéntico, y más agudo |
| Ridge (L²) | *weight decay* |
| Validación cruzada | idéntica |
| Matriz de confusión, ROC, AUC | idénticas |

La estadística no cambia de naturaleza al crecer el modelo. Cambia la
tratabilidad: con dos parámetros hay solución cerrada, con dos millones solo
queda bajar por el gradiente.

## Por qué no corre acá

`torch` no compila a WebAssembly, y las redes neuronales están fuera del
temario de un curso de análisis estadístico de datos de 24 horas.

No es una limitación técnica que valga la pena pelear: si el objetivo es
entender **por qué** funciona un método, el MLP es peor punto de entrada que
la regresión logística, porque agrega parámetros sin agregar comprensión.

## El puente

**Un MLP sin capa oculta y con activación sigmoide *es* una regresión
logística.** No se le parece: es la misma función, los mismos parámetros, la
misma verosimilitud.

Entonces el camino honesto es:

1. Corré la regresión logística en el lab.
2. Mirá su frontera de decisión en la fase 2 (`f2.analisis.frontera_decision`).
   Es una recta.
3. Mirá su traza de convergencia con IRLS en la fase 3. Ya estás viendo un
   optimizador iterativo bajar por una superficie.
4. Ahora imaginá una capa más. Eso es todo lo que un MLP agrega.

Cuando quieras cruzar el puente de verdad, el orden que menos duele es:
logística → logística multinomial → MLP de una capa → todo lo demás.

## Para explorarlo fuera de la app

```r
# Requiere R completo, no el navegador
install.packages("nnet")
ajuste <- nnet::nnet(clase ~ ., data = entrenamiento, size = 5, decay = 1e-3)
```

`nnet` es de 1996, pesa poco y hace un MLP de una capa oculta. Alcanza
perfectamente para ver el punto sin instalar torch.
