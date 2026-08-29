## Para qué sirve

Ver el reparto antes de creerle a la partición. Es el primer sitio donde se
nota que k-medias encontró lo que había, o que partió una nube por la mitad.

## Qué muestra

Una barra por grupo con cuántas observaciones cayeron en él, y el subtítulo con
la fracción de la muestra que va del grupo más chico al más grande.

## Qué buscar

- **Un grupo con dos o tres observaciones.** Casi siempre son atípicos que el
  algoritmo apartó para bajar la inercia. Es un hallazgo sobre esos puntos, no
  sobre la estructura de los datos.
- **Un grupo con la mitad de la muestra.** Suele ser una nube que no se partió:
  el `k` que pediste se gastó separando los extremos y dejó el centro entero.
- **Un reparto parejo cuando no esperabas uno.** k-medias tiende a producir
  grupos de tamaño parecido incluso cuando la estructura real no lo es, así que
  la uniformidad no confirma nada por sí sola.

## Cuándo engaña

**Los tamaños parejos son en parte un artefacto del método.** Minimizar la
suma de cuadrados favorece particiones equilibradas: un grupo grande aporta
mucha inercia y el algoritmo prefiere partirlo antes que dejar uno pequeño. Un
reparto equilibrado no es evidencia de grupos equilibrados en la población.

**Un grupo chico puede desaparecer con otra semilla.** Antes de contar una
historia sobre él, volvé a ajustar con otra semilla o con más reinicios y mirá
si sobrevive. Si cambia, era del arranque y no de los datos.
