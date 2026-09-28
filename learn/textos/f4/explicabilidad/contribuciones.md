## Para qué sirve

Saber de quién es la varianza de cada componente. Las cargas dicen con qué signo
entra cada variable; la contribución dice cuánto pesa, en una escala que suma
100 y se puede comparar entre componentes.

## Qué muestra

El cuadrado de la carga de cada variable, llevado a porcentaje dentro de su
componente:

$$
\text{contrib}_{ij} = 100 \cdot \frac{v_{ij}^2}{\sum_{l} v_{lj}^2} = 100 \cdot v_{ij}^2
$$

El denominador vale 1 porque los vectores propios son de norma 1: por eso las
contribuciones de una componente reparten exactamente 100. La línea punteada
está en `100/p`, lo que aportaría cada variable si todas aportaran igual.

## Qué buscar

- **Quién pasa la línea.** Esas variables definen el eje; las de abajo vienen
  arrastradas por su correlación con ellas. Nombrar la componente es leer las que
  pasan la línea, con su signo.
- **Una sola variable muy arriba.** La componente es esa variable con adornos.
  Útil, pero no es un resumen: es un cambio de nombre.
- **Todas cerca de la línea.** La componente es un promedio general de todo —el
  clásico "factor de tamaño" de la primera componente cuando todas las
  variables miden lo mismo en distinta escala.
- **Compará CP1 con CP2.** Una variable que contribuye poco al primer eje y
  mucho al segundo es la que separa lo que el primero mezcló: en los carros, eso
  es lo que distingue al deportivo liviano del familiar liviano.

## Cuándo engaña

**Contribución alta no es variable importante.** Es importante *para ese eje*.
Si el eje explica el 5 % de la varianza, dominarlo no significa gran cosa: hay
que leer la contribución junto al porcentaje del scree.

**Contribución baja no es variable irrelevante.** Puede estar bien representada
en otra componente. Esa pregunta la contesta la calidad de representación, no
esta vista; confundirlas es leer el círculo al revés.

**El signo no está acá.** La contribución es un cuadrado, así que una variable
que empuja hacia el lado negativo y otra que empuja hacia el positivo pueden
tener la misma barra. Para el signo están las cargas.

**Sin escalar, el reparto lo decide la unidad de medida.** Si descomponiste la
covarianza, la variable de mayor rango se lleva la contribución por tener
números grandes, no por explicar nada.
