## Qué es

El ACP de las variables cualitativas. Donde el ACP descompone la matriz de
varianzas y covarianzas, el ACM descompone la de **Burt**: todos los cruces de
todas las variables entre sí, en bloques.

El punto de partida es la **matriz indicadora** `Z`: una columna 0/1 por cada
categoría de cada variable, de modo que cada fila tiene exactamente un 1 por
variable. Sobre ella se calculan los perfiles y los residuos respecto a la
independencia:

$$
P = \frac{Z}{nQ}, \qquad
S = D_r^{-1/2}\left(P - r c^{\mathsf{T}}\right) D_c^{-1/2}
$$

`r` y `c` son las masas marginales de filas y columnas. Restar `r cᵗ` es lo que
en el ACP hace el centrado: saca la dimensión trivial que solo dice que la tabla
tiene marginales, y deja la desviación respecto a la independencia, que es la
señal. El SVD de `S` da las direcciones, y los valores propios son `d²`.

Las coordenadas de las filas son los individuos; las de las columnas, las
categorías. Las dos se leen en el mismo plano.

## Por qué es necesaria

Porque la mitad de los datos del mundo no son números. Un censo tiene vivienda
pavimentada sí/no, servicio de agua sí/no, ocupado/desocupado: calcular una
correlación sobre eso sería promediar códigos, y un promedio de códigos no
significa nada.

La necesidad es la misma que en el ACP —hay demasiadas variables y están
asociadas— y la solución también: pocos ejes que resuman la asociación. Lo que
cambia es qué se descompone.

Y hay un efecto secundario que en la práctica importa mucho: **la matriz de Burt
no contiene una sola fila de datos**. Son conteos. Se puede sacar de una sala de
procesamiento cerrada, mandar por correo, y hacer el análisis en otra parte sin
haber movido un dato personal.

## La inercia total no depende de los datos

$$
\text{inercia total} = \frac{J}{Q} - 1
$$

Con `J` categorías en `Q` variables, la inercia total está decidida antes de
mirar los datos. La consecuencia práctica: **los porcentajes de varianza
explicada de un ACM se ven bajos**, y compararlos con los de un ACP es un error
de lectura. Un 25 % en un ACM puede ser una estructura fuerte.

De ahí sale también el umbral de Kaiser del método: la media de los valores
propios vale exactamente `1/Q`, y ese es el corte, no el 1 del ACP.

Las correcciones de Benzécri y Greenacre reescalan los porcentajes para que se
lean como los de un ACP. Quedan fuera de este curso; saber que existen evita
concluir que el ACM "explica poco".

## Cuándo falla

- **Categorías raras.** Una categoría con tres casos tiene masa mínima y una
  desviación enorme respecto a la independencia: define un eje ella sola. Es el
  equivalente del atípico en el ACP, y el semáforo de la fase 2 lo cuenta.
- **Variables con demasiadas categorías.** Si una columna tiene casi una
  categoría por fila, no es una variable cualitativa: es un identificador, y el
  ACM describiría filas en vez de asociaciones.
- **Interpretar distancias entre categorías de variables distintas.** En el plano
  se leen bien las proximidades dentro de una variable y las direcciones; la
  distancia exacta entre una categoría de ojos y una de empleo no tiene la misma
  lectura.
- **El círculo de correlaciones no aplica.** Las coordenadas de una categoría no
  son correlaciones acotadas por 1. Por eso el método no declara esa vista en
  lugar de dibujar un marco que engañaría.

## En R

```r
# En el lab: matriz indicadora, Burt y el ajuste, sin paquetes externos
Z <- matriz_indicadora(datos, columnas)
B <- matriz_burt(Z)                  # el equivalente cualitativo de S
ajuste <- ajustar_acm(datos, columnas, n_componentes = 2)

# Con paquetes, si los tenés instalados
# FactoMineR::MCA(datos[columnas], ncp = 2)
# ca::mjca(datos[columnas])
```

## Para seguir

El **análisis de correspondencias simple** es el mismo método con dos variables:
una tabla de contingencia y su descomposición. Está en el catálogo como
pendiente, y su antesala ya corre en ① Datos — el gráfico de mosaico con
residuos estandarizados es esa tabla, leída sin reducir.

En la otra dirección, si las variables son cuantitativas el método es el
[ACP](acp.md), y si están mezcladas existe el AFDM (análisis factorial de datos
mixtos), que trata cada bloque con su métrica.
