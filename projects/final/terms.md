Términos:

**:: GMM (modelo de mezclas gaussianas)**
**Qué es:** Método suave que supone que cada grupo sigue una distribución normal y lo estima con EM. En la clase 5
  quedó para otro curso.
**En Zoo:** *No aplica, porque nuestras variables no son numéricas. Es el punto de partida para explicar clases latentes.*

---

**:: Método duro / suave**
**Qué es:** El duro le da a cada animal una sola etiqueta de grupo. El suave le da una probabilidad de pertenecer a
  cada grupo.
**En Zoo:** *K-modas y Gower son duros. Clases latentes es suave.*

---

**:: Clases latentes**
**Qué es:** Versión categórica del GMM. Cada clase es una tabla de probabilidades por atributo, por ejemplo P(leche
  = sí | clase 1).
**En Zoo:** *Es el tercer enfoque: Cambia el modelo y deja igual la distancia y el centro.*

---

**:: Distribución categórica**
**Qué es:** La que da una probabilidad a cada categoría de un atributo. Las probabilidades suman 1.
**En Zoo:** *Para patas en una clase: P(0), P(2), P(4), P(5), P(6) y P(8).*

---

**:: Independencia local**
**Qué es:** Supuesto central del modelo: Dentro de una misma clase, saber un atributo no dice nada de otro.
**En Zoo:** *Falla con pelo y leche, que siguen asociados aun dentro de una clase.*

---

**:: EM (Expectation-Maximization)**
**Qué es:** Algoritmo que repite dos pasos hasta que la verosimilitud deja de subir.
**En Zoo:** *Lo escribimos a mano en el cuaderno (em_latente()).*

---

**:: Paso E**
**Qué es:** Calcula, con los parámetros actuales, la probabilidad de que cada animal pertenezca a cada clase (la
  posterior).
**En Zoo:** *Se hace en logaritmos porque el producto de 16 probabilidades es diminuto.*

---

**:: Paso M**
**Qué es:** Con esas probabilidades recalcula los pesos de las clases y las probabilidades de cada categoría.
**En Zoo:** *Es la parte de masa, theta y pesos en la diapositiva de código.*

---

**:: Probabilidad de pertenencia (posterior)**
**Qué es:** Probabilidad de que un animal sea de cada clase, vistos sus 16 atributos. La partición final toma la
  clase más probable.
**En Zoo:** *Es lo que hace "suave" al método.*

---

**:: Pesos o proporciones (π)**
**Qué es:** Tamaño relativo de cada clase en el modelo.
**En Zoo:** *Ejemplo: Una clase que pesa 0.39 reúne cerca del 39 % de los animales.*

---

**:: θ (theta)**
**Qué es:** Probabilidad de cada categoría dentro de cada clase.
**En Zoo:** *Una θ igual a 0 o 1 es una de las limitaciones, porque el modelo queda "seguro" de algo que solo vio en pocos animales.*

---

**:: Tabla indicadora (Y)**
**Qué es:** Una columna por categoría, con un 1 donde el animal tiene esa categoría.
**En Zoo:** *Es la entrada del EM.*

---

**:: Verosimilitud / log-verosimilitud**
**Qué es:** Qué tan probable es ver los datos según el modelo. Más alta es mejor y se usa en logaritmo.
**En Zoo:** *Va de −994.9 con k = 1 a −480.9 con k = 8.*

---

**:: Arranques**
**Qué es:** Correr el algoritmo desde varios puntos iniciales y quedarse con el mejor.
**En Zoo:** *25 arranques por cada k, con semillas 42 a 66.*

---

**:: Máximo local**
**Qué es:** Solución que ya no mejora con cambios pequeños pero no es la mejor posible.
**En Zoo:** *Con pocos arranques un k alto quedaba peor que uno bajo. Es el mismo problema de k-medias.*

---

**:: Parámetros**
**Qué es:** Lo que el modelo estima: (K − 1) pesos más K·Σ(R_j − 1) probabilidades. R_j es el número de categorías
  del atributo j.
**En Zoo:** *Cada clase de más suma 21 parámetros: k = 4 tiene 83 y k = 7 tiene 146.*

---

**:: BIC**
**Qué es:** −2·log-verosimilitud + parámetros · log(n). Menor es mejor y castiga fuerte los modelos grandes.
**En Zoo:** *log(101) ≈ 4.6 por parámetro. Su mínimo está en k = 4.*

---

**:: AIC**
**Qué es:** −2·log-verosimilitud + 2 · parámetros. Castiga menos que el BIC.
**En Zoo:** *Su mínimo está en k = 7, justo el número de tipos.*

---

**:: Tabla de cruce**
**Qué es:** Tabla de grupos encontrados contra clase real, que muestra qué se mezcló con qué.
**En Zoo:** *Con k = 4 quedan mamíferos (39), aves (20 y un reptil), insectos con invertebrados (18) y acuáticos de sangre fría (13 peces, 4 anfibios, 4 reptiles y 2 mamíferos).*

---

**:: ARI (índice de Rand ajustado)**
**Qué es:** Acuerdo entre dos particiones, corregido por el azar. 1 es acuerdo perfecto y 0 es azar. No importa
  cómo se numeren los grupos.
**En Zoo:** *Clases latentes: 0.83 con k = 7 y 0.82 con k = 4.*

---

**:: ACP / ACM**
**Qué es:** El ACP resume variables numéricas en pocas dimensiones. El ACM hace lo mismo con variables cualitativas
  a partir de la tabla indicadora.
**En Zoo:** *El ACM es el equivalente cualitativo del ACP de la clase 5.*

---

**:: Inercia**
**Qué es:** La "varianza" del ACM: Cuánta información resume cada dimensión.
**En Zoo:** *Las 5 primeras dimensiones juntan el 71.6 %.*

---

**:: Herramienta de diagnóstico**
**Qué es:** Algo que sirve para mirar los datos y no para formar los grupos.
**En Zoo:** *El maestro lo dijo del ACP en la clase 5 y por eso el tándem es un contraejemplo.*

---

**:: Tándem**
**Qué es:** Primero ACM (5 dimensiones) y luego k-medias sobre esas coordenadas.
**En Zoo:** *ARI 0.83. Funciona aquí, pero nada asegura que las dimensiones con más inercia separen bien los grupos.*

---

**:: Validación externa**
**Qué es:** Comparar los grupos con una clase que nunca entró al ajuste.
**En Zoo:** *tipo nunca entró y aun así se recupera, igual que las zonas de Bogotá en el anexo de la clase 5.*

---

**:: Enlace simple / promedio**
**Qué es:** Formas de medir la distancia entre dos grupos en el jerárquico: El par más cercano (simple) o el
  promedio de todos los pares (promedio).
**En Zoo:** *Gower jerárquico da el mejor ARI: 0.94 con simple y 0.89 con promedio.*

---

**:: Arranque de Huang**
**Qué es:** Forma de escoger las modas iniciales de k-modas: Sortea categorías según su frecuencia y toma el animal
  real más parecido.
**En Zoo:** *Da el ARI más bajo de todos (0.63).*

Lo más probable es que te pregunten por tres cosas:
1. Por qué el BIC y el AIC eligen distinto: Por cuánto castiga cada uno los parámetros (4.6 contra 2 por parámetro).
2. Qué es la independencia local: Que dentro de una clase los atributos no se informan entre sí. En Zoo falla con pelo y leche.
3. Por qué el tándem es un contraejemplo: Porque las dimensiones que más inercia resumen no tienen por qué ser las que mejor separan los grupos.