## Para qué sirve

Ver el repertorio completo de lo que el método puede producir, sin haber
ajustado nada. Antes de preguntarse cuál es la respuesta conviene saber cuáles
eran las respuestas posibles.

## Qué muestra

Cada punto de la curva es un modelo candidato: una dirección del plano, medida
por la proporción de varianza que captaría si la eligieras. El eje horizontal
barre media vuelta —de 0 a 180 grados— porque una dirección y su opuesta
describen el mismo eje.

El punto marcado es el máximo. Eso es la primera componente principal: no hay
que estimar nada para verla, solo mirar la familia entera de una vez.

```
Var(aᵀX) = aᵀ S a,  con ‖a‖ = 1
```

La línea punteada es la dirección que estás mirando ahora en el panel de al
lado.

## Qué buscar

- **Qué tan picuda es la curva.** Un pico angosto significa que hay una
  dirección claramente mejor que las demás: la nube está estirada y el ACP va a
  resumir mucho. Una curva casi plana significa que todas las direcciones
  captan lo mismo, la nube es redonda y reducir no va a ganar nada.
- **Dónde está el máximo.** Su ángulo dice qué mezcla de las dos variables
  forma la componente. A 45 grados, ambas pesan igual.
- **El mínimo.** Está siempre a 90 grados del máximo, y no es casualidad: las
  componentes son perpendiculares por construcción. La dirección de mínima
  varianza es la última componente.
- **La distancia entre máximo y mínimo.** Es exactamente la diferencia entre el
  primer y el último valor propio.

## Cuándo engaña

**Solo se ven dos variables por vez.** Con p variables el espacio de hipótesis
es una esfera de dimensión p−1 y no cabe en una curva. Este panel es la
intuición, no el cálculo: el ajuste real usa todas las columnas elegidas.

**La curva depende de si se estandarizó.** Sobre datos crudos, la variable con
la unidad más grande empuja el máximo hacia su propio eje. Cambiá entre R y S
en Hiperparámetros y mirá cómo se mueve el pico: eso es la decisión más
importante del ACP, dibujada.

**Un máximo claro no garantiza que el resumen sirva.** La dirección de mayor
varianza es la que mejor describe la nube, no necesariamente la que mejor
predice o discrimina. Para clasificar, a veces la componente útil es la última.
