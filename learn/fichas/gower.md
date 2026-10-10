## Qué es

Una forma de medir qué tan distintas son dos observaciones cuando sus
variables **no son números**, o no lo son todas: tiene pelo o no, cuántas patas
(como categoría), qué tipo de suelo, qué región. Sobre esa disimilitud se
agrupa de dos maneras: con **PAM** (k-medoides) o con un **árbol jerárquico**
cortado en `k`.

Gower (1971) compara variable a variable, cada una con la regla de su tipo, y
promedia:

$$
s_{ij} = \frac{\sum_{k=1}^{p} w_{ijk}\, s_{ijk}}{\sum_{k=1}^{p} w_{ijk}},
\qquad d_{ij} = 1 - s_{ij}
$$

`s_ijk` es el parecido de las filas `i` y `j` en la variable `k`, entre 0 y 1,
y `w_ijk` vale 1 si esa comparación cuenta y 0 si no (un faltante, o una
ausencia compartida en una binaria asimétrica).

## Lo que aporta cada tipo de variable

| Tipo | Parecido $s_{ijk}$ | Ejemplo en el zoológico |
|---|---|---|
| nominal | 1 si coinciden, 0 si no | `patas`: 4 contra 4 suma, 4 contra 6 no |
| binaria simétrica | igual que la nominal | `acuatico`: si/si y no/no suman |
| binaria asimétrica | 1 si los dos tienen el atributo; el par no/no **no cuenta** ($w = 0$) | `plumas`: no/no se ignora |
| numérica | $1 - \lvert x_{ik} - x_{jk} \rvert / R_k$, con $R_k$ el rango | — |

Con **solo variables nominales** y sin faltantes todos los pesos valen 1 y la
fórmula se reduce a contar desacuerdos:

$$
d_{ij} = \frac{\#\{k : x_{ik} \neq x_{jk}\}}{p}
$$

que es la distancia de **Hamming** dividida por `p`, el complemento del
coeficiente de **coincidencia simple** (*simple matching*). Gower no inventa
una distancia nueva para lo cualitativo: generaliza esa y le permite convivir
con números.

## Binarias asimétricas: por qué importan en el zoológico

La mayoría de los animales **no** tiene plumas, no es venenoso y no tiene
aletas. Con la regla simétrica cada "no" compartido suma parecido, y dos
animales que casi no tienen atributos (un gusano y una pulga) quedan pegados
por lo que **les falta**, no por lo que comparten. La opción asimétrica saca
los pares no/no del numerador y del denominador: sobre esas columnas es el
coeficiente de **Jaccard**.

En la prueba, pulga contra gusano difieren en una sola de 16 variables
(simétrica: 1/16 = 0.06); de las otras 15, en 13 coinciden en "no". La
asimétrica las deja afuera y mide 1/3 = 0.33. Cuál de las dos es correcta no
lo dice la matemática: lo dice si "no tener alas" es un rasgo o una ausencia.

## PAM contra k-medias

k-medias representa cada grupo por su **media**, y para eso hacen falta
números que promediar: el promedio de un pez y un ave no es un animal. PAM
(*Partitioning Around Medoids*, Kaufman y Rousseeuw, 1990) lo representa por
su **medoide**, la observación real del grupo que menos dista de las demás, y
minimiza

$$
\sum_{i=1}^{n} \min_{m \in M} d(x_i, x_m), \qquad |M| = k
$$

Como solo usa $d$, sirve con **cualquier** disimilitud: Gower, Jaccard, una
tabla de distancias de viaje. Y el centro se puede leer: el medoide del grupo
de las aves es un ave concreta.

1. **BUILD**: elegir medoides de a uno, cada vez el que más baja el costo.
2. **SWAP**: probar cambiar un medoide por una no-medoide; quedarse con el
   cambio si baja el costo. Repetir hasta que ningún cambio ayude.

En la fase 3 la traza son esos pasos: `k` de BUILD (el costo con 1, 2, …, `k`
medoides) y uno por cada intercambio de SWAP. `pam()` no devuelve ese
recorrido, solo lo imprime: el lab toma de ahí qué fila entró o salió y
recalcula el costo con la matriz.

Con la estrategia **jerárquica** el árbol se arma igual que en el jerárquico
numérico (enlace promedio, completo, simple), pero sobre la matriz de Gower.
El "centro" de cada grupo es su **modo**: la categoría más frecuente de cada
variable (la mediana para las numéricas).

## Cuándo falla

- **El rango manda en las numéricas.** $R_k$ es el rango observado: un solo
  atípico lo estira y aplasta las diferencias de todos los demás en esa
  variable. Recortar o transformar antes, o pasarla a categorías.
- **Pesos iguales.** Cada variable pesa 1/p, sin importar cuánta información
  traiga. Quince binarias de anatomía y una de hábitat: la anatomía decide.
  Elegir las columnas es elegir los pesos.
- **Asimétrica o simétrica es una decisión.** El software no puede saber si
  "no" es ausencia o es una categoría más.
- **Memoria O(n²).** Guarda las `n(n−1)/2` disimilitudes, igual que el
  jerárquico: con miles de filas no entra. Para eso está k-modos.
- **Ward no está en su casa.** Ward minimiza una inercia euclídea, y Gower no
  es euclídea: con `ward.D2` el árbol se arma, pero no minimiza nada con
  nombre. (Para coincidencia simple, $\sqrt{d}$ sí es euclídea —Gower y
  Legendre, 1986—; acá no se transforma.)
- **Empates.** Con categorías hay muchas distancias repetidas (en el
  zoológico, animales idénticos en las 16 columnas). PAM y el árbol las
  desempatan por orden de fila: otra permutación de filas puede dar otra
  partición igual de buena.

## En R

```r
library(cluster)
d <- daisy(X, metric = "gower")                      # nominal + numérica
d <- daisy(X01, metric = "gower",
           type = list(asymm = c("plumas", "aletas")))  # 0/1, asimétricas
modelo <- pam(d, k = 7, diss = TRUE)
modelo$id.med                                         # filas que son medoides
arbol <- hclust(as.dist(d), method = "average")
grupos <- cutree(arbol, k = 7)
```

`daisy()` decide qué es "ausencia" por el código: en una asimétrica, el 0. Un
factor con niveles `c("si", "no")` la invierte sin avisar; el lab recodifica a
0/1 con "no" como ausencia antes de llamarla.
