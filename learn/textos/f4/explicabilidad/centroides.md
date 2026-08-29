## Para qué sirve

Contestar la única pregunta que queda después de agrupar: *¿y qué son estos
grupos?* Un número de grupo no significa nada hasta que se puede decir en qué
se diferencia de los demás.

## Qué muestra

La coordenada de cada centroide en cada variable, una barra por grupo y
variable. Si ajustaste con estandarización, las coordenadas están en
desviaciones estándar respecto al promedio general: un centroide en +1.2 quiere
decir que ese grupo está una desviación y pico por encima de la media en esa
variable.

$$
\mu_j = \frac{1}{|C_j|} \sum_{i \in C_j} x_i
$$

La línea vertical en cero es el promedio general.

## Qué buscar

- **La variable donde los grupos más se separan.** Es la que da nombre a la
  partición: si un grupo está muy arriba en ingreso y muy abajo en educación,
  eso es una frase que se puede escribir en el informe.
- **Variables donde todos los grupos están juntos.** No participan de la
  separación: sobran para describir la partición, aunque hayan entrado al
  ajuste.
- **Un grupo que es extremo en todo.** Suele ser el grupo de los atípicos.
- **Perfiles espejados.** Dos grupos opuestos en las mismas variables son las
  dos puntas de un mismo eje continuo, y quizá no eran dos grupos.

## Cuándo engaña

**Sin estandarizar, las alturas no se comparan.** Las barras están en las
unidades de cada variable, y una diferencia de 1000 en salario se ve enorme al
lado de una de 0.3 en un índice, sin que eso signifique nada.

**El centroide es un promedio, y los promedios esconden.** Un grupo bimodal
tiene un centroide en el medio, donde no hay nadie. Cruzalo con el mapa 2D y
con la silueta antes de describir el grupo por su centro.

**Describir no es explicar.** Estas diferencias son las que el algoritmo usó
para partir: encontrarlas no confirma la partición, es circular. Lo que sí
vale es contrastar el perfil con una variable que **no** entró al ajuste.
