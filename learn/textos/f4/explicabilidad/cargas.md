## Para qué sirve

Ponerle nombre a una componente. El ACP devuelve ejes numerados —CP1, CP2— que
no significan nada por sí mismos; las cargas dicen de qué están hechos, y de ahí
sale la interpretación.

## Qué muestra

Una barra por variable en cada componente retenida: cuánto pesa esa variable en
esa dirección. Las barras van con signo, no en valor absoluto, porque el signo
es media interpretación: dice si la variable empuja hacia el lado positivo o el
negativo del eje.

Formalmente son las coordenadas del autovector, y su norma vale 1:

```
Σᵢ vᵢⱼ² = 1
```

Por eso con muchas variables todas las cargas son pequeñas: se reparten un
presupuesto fijo.

## Qué buscar

- **Las barras largas.** Son las que definen la componente. Si CP1 tiene cargas
  altas en peso, altura y perímetro, esa componente es "tamaño".
- **Los signos.** Cargas grandes de signos opuestos en la misma componente
  indican un contraste: la componente separa dos bloques de variables que se
  mueven en direcciones contrarias. Suele ser el hallazgo más interesante.
- **Cargas repartidas.** Si en una componente todas las variables pesan
  parecido, esa dirección es un promedio general y rara vez dice algo nuevo.
- **Una variable que solo pesa en CP3.** Está capturando algo propio que no
  comparte con las demás.

## Cuándo engaña

**El signo de una componente entera es arbitrario.** Multiplicar todas las
cargas de CP1 por −1 da exactamente el mismo ACP. La app fija una convención
—la carga de mayor magnitud queda positiva— para que dos corridas iguales se
vean iguales, pero no le atribuyas dirección a un eje: lo que importa son los
signos *relativos* dentro de la componente.

**Carga alta no es correlación alta.** La carga es la coordenada del autovector;
la correlación con la componente además pondera por √λ. Dos variables con la
misma carga en componentes distintas pueden estar correlacionadas muy distinto
con su eje. Para eso está el círculo de correlaciones.

**Sobre S las cargas no son comparables entre variables.** Si no
estandarizaste, una carga grande puede reflejar solo que esa variable tiene
unidades grandes.

**Interpretar es opcional y a veces imposible.** Una componente es una
combinación de todas las variables. A veces no corresponde a ningún concepto
nombrable, y forzar un nombre es peor que dejarla como "la segunda dirección de
mayor varianza".
