# Guion de exposición: Clustering de variables cualitativas

Son cuatro partes, una por integrante. El reparto solo está en este guion y no sale en las diapositivas.

Dos usos del mismo guion:
- **Video:** Cada integrante graba su parte. La diapositiva de relevo ("Parte n de 4") marca el corte y la frase de traspaso cierra cada parte.
- **En vivo:** Expone quien salga al azar, por eso cada parte se escribió para entenderse sola y **los cuatro tenemos que ensayar las cuatro**. En el traspaso se dice el nombre de quien siga.

El hilo de todo es la clase 5 (`SL_4.pdf`, cuaderno `NB4_PRF.Rmd`): Repetimos su procedimiento paso a paso cambiando la distancia, el centro o el modelo. Cuando en clase se preguntó por variables cualitativas el maestro respondió que ese era tema para el trabajo y que sí se podía, y vale la pena recordarlo al abrir.

> **Nota:** Todas las cifras salen del cuaderno (`cuaderno/clustering-cualitativo.Rmd`, con Zoo, k = 7, semilla 42 y 25 arranques). Si alguien pregunta de dónde sale un número, la respuesta está en el HTML del cuaderno.

---

## Parte 1: La pregunta de la clase 5 y los datos (Anyelo)

**Diapositivas:** Portada → Contenido → relevo 1 → "La pregunta de la clase 5" → "De lo numérico a lo cualitativo" → "101 animales, 16 atributos" → "Asociación entre atributos" → "Primer plano factorial del ACM".

**Guion.** En la clase 5 agrupamos 15 estaciones de Bogotá con cinco contaminantes usando la distancia euclídea, estandarizando siempre y resumiendo cada grupo con su media. La pregunta que salió en clase fue qué pasa cuando las variables son cualitativas pues no existe una media de tener plumas ni tiene sentido estandarizar un sí/no. Lo que proponemos es seguir el mismo procedimiento de la clase (la tabla lo muestra fila por fila) cambiando solo una de tres piezas: La **distancia**, el **centro** o el **modelo**.

Como datos usamos Zoo (UCI), con 101 animales descritos por 15 atributos binarios y el número de patas, que tratamos como categoría porque 5 patas no es "más" que 4 en ningún sentido útil. Además está la clase real `tipo` (mamífero, ave, pez, etc.), que dejamos por fuera del agrupamiento y guardamos para el final, igual que la ubicación en el anexo de la clase. La asociación entre atributos cumple el papel de la matriz de correlación: Pelo y leche van juntos porque los dos son rasgos de mamífero, como el CO y el NO subían juntos porque comparten fuente. El ACM es el ACP de las cualitativas y su primer plano factorial lo usamos igual que en clase, solo para ver los grupos antes de agruparlos.

**Traspaso:** "Ya vimos los datos. Ahora, ¿cómo medimos que dos animales se parecen? Eso lo explica Daniel."

**Preguntas probables**
- **¿Por qué patas como categoría?** Porque los valores (0, 2, 4, 5, 6, 8) separan formas de cuerpo y no son una cantidad que tenga sentido promediar.
- **¿Por qué ACM y no ACP?** El ACP necesita variables cuantitativas, mientras que el ACM descompone la tabla de cruces de categorías (la matriz de Burt), que hace el papel de la matriz de covarianzas.

---

## Parte 2: Distancia, calidad de la partición y k-modas (Daniel)

**Diapositivas:** Relevo 2 → "Métodos duros y suaves" → "Distancia entre categorías" → "Calidad de la partición" → "Algoritmo k-modas" → "K-modas paso a paso" → "Sensibilidad a la inicialización" → "Perfiles de los grupos".

**Guion.** Como en clase, separamos los métodos duros, que le dan una etiqueta a cada animal, de los suaves, que le dan un vector de probabilidades de pertenencia, y para los dos hay versión cualitativa (k-modas y Gower en los duros, clases latentes en los suaves). La distancia euclídea la cambiamos por el **emparejamiento simple**, que cuenta en cuántos atributos difieren dos animales, y como todas las variables ya están en la misma escala no hay nada que estandarizar. Cuando hay variables mixtas se usa Gower, que normaliza cada numérica por su rango y así cumple el papel de estandarizar.

La fórmula de calidad de la partición que vimos en clase (la suma de distancias dentro de cada grupo dividida por su tamaño) solo usa distancias, de forma que funciona igual si cambiamos la euclídea al cuadrado por los desacuerdos. K-modas es el algoritmo de Lloyd con la moda como centro: Se eligen K animales como modas iniciales, cada animal va a la moda con la que tiene menos desacuerdos, se recalcula la moda de cada atributo dentro del grupo y se repite hasta que ningún animal cambie. La moda es el centro que toca porque el costo se separa por atributo y lo minimiza la categoría más frecuente (Huang, 1998).

La advertencia de la clase sobre la inicialización aquí se nota bastante: El arranque de Huang da un costo de 138 desacuerdos y un ARI de 0.63, mientras que un arranque aleatorio da 139 y un ARI de 0.83. Por eso, igual que con `nstart`, corremos varias veces y nos quedamos con el menor costo, sabiendo que un costo menor no asegura recuperar la estructura real. El mapa de perfiles muestra qué categoría domina en cada atributo dentro de cada grupo.

**Traspaso:** "Fijamos K = 7, pero ¿de dónde sale ese número? Eso lo explica Tania."

**Preguntas probables**
- **¿Por qué no k-medias sobre variables 0/1?** La media de dummies es una proporción y deja de ser una categoría, así que el centro ya no se puede leer, y la euclídea sobre dummies cuenta doble cada desacuerdo en variables de muchas categorías.
- **¿Qué pasa si hay empate en la moda?** Se rompe con una convención fija (la primera categoría) y es una de las fuentes de inestabilidad.

---

## Parte 3: Elegir K y jerárquico sobre Gower (Tania)

**Diapositivas:** Relevo 3 → "Elegir K" → "Jerárquico con tres enlaces" → "Dendrograma con enlace promedio" → "Concordancia entre k-modas y jerárquico".

**Guion.** La clase 5 dio dos guías para elegir K y las dos sirven aquí: El primer plano factorial (ahora del ACM) para contar grupos a ojo y el método del codo, que en vez de la reducción de d² usa la reducción de desacuerdos al agregar grupos y busca el punto donde agregar uno más aporta poco. Como en clase, el codo es heurístico y le creemos más cuando coincide con el plano factorial.

El agrupamiento jerárquico resuelve dos limitaciones de k-modas (no pide K de antemano y no depende de un arranque aleatorio) y funciona con cualquier matriz de distancias, así que basta con darle la de Gower. Comparamos los tres enlaces de clase (completo, promedio y simple) en un solo círculo, con un sector por enlace, la misma distancia y el mismo corte. La raíz está en el centro, las hojas en el borde y el punto grande marca dónde nace cada grupo. El simple forma cadenas, lo que se ve en sus ramas largas y escalonadas y en los dos animales que quedan como grupos de uno (el escorpión y la serpiente marina), pero en Zoo es el que más recupera la clase real (ARI 0.94), seguramente porque las clases están bien separadas. Nos quedamos con el promedio porque es el que mejor respeta las distancias (cofenética 0.857), y cortándolo en 7 grupos obtuvimos un ARI de 0.89 contra la clase real. Por último, como la tabla `K_means × Jerárquico` de la clase, cruzamos k-modas con el jerárquico y en las celdas donde no coinciden aparecen los animales de frontera.

En el dendrograma la primera gran separación (altura 0.52) deja a los 41 mamíferos y a la tortuga de un lado y al resto del otro, y después se separan peces, anfibios y reptiles de aves, insectos e invertebrados. El ornitorrinco, que es un mamífero que pone huevos, queda en un grupo de dos con la tortuga, y es justo el tipo de animal de frontera que un método duro tiene que meter en un solo grupo.

**Traspaso:** "Hasta aquí cada animal quedó en un solo grupo. ¿Y si un animal está entre dos? Eso lo explica Over."

**Preguntas probables**
- **¿Por qué Gower y no emparejamiento simple en el jerárquico?** Con datos solo categóricos dan lo mismo (Gower = desacuerdos / p) y Gower además permite mezclar numéricas y binarias asimétricas.
- **¿Por qué no Ward?** Porque Ward supone geometría euclídea y Gower no la tiene.

---

## Parte 4: Clases latentes, tándem y validación (Over)

**Diapositivas:** Relevo 4 → "Modelo de clases latentes" → "Número de clases: BIC y AIC" → "Clases latentes en el plano del ACM" → "ACM seguido de k-medias (tándem)" → "Validación con la variable tipo" → "Limitaciones de cada método" → "Conclusiones".

**Guion.** En clase el GMM (el método suave con normales y EM) quedó para exposición de otro grupo y su versión categórica son las **clases latentes**: Donde el GMM pone una normal, aquí va un producto de distribuciones categóricas, con el supuesto de independencia local (dentro de cada clase los atributos no dependen entre sí). Se estima con EM, que alterna las probabilidades de pertenencia de cada animal con las nuevas proporciones y probabilidades por clase, y K lo elegimos con el BIC. En Zoo el BIC elige **4 clases** (ARI 0.82) aunque haya 7 tipos, y forzando 7 clases el ARI apenas sube a 0.83, de forma que el BIC prefiere menos parámetros a cambio de casi la misma recuperación. El AIC, que castiga menos cada parámetro, tiene su mínimo justo en 7 clases, que es el número real de tipos. Cada k de esa tabla lo ajustamos con los mismos 25 arranques y por eso la verosimilitud crece con k como debe (con menos arranques un k alto quedaba en un máximo local peor, el mismo problema de k-medias).

La tabla de cruce con K = 4 muestra qué se fusiona: Una clase de mamíferos (39), una de aves (20, con un reptil), una de insectos e invertebrados juntos (18) y una de animales acuáticos y de sangre fría (13 peces, 4 anfibios, 4 reptiles y 2 mamíferos), así que el BIC absorbe justo las clases pequeñas.

En la clase 5 el maestro dijo que el ACP es una herramienta de diagnóstico y que no hace parte del agrupamiento. El tándem (ACM a 5 dimensiones y luego k-medias) lo mostramos como contraejemplo: Aquí recupera bien los tipos (ARI 0.83), pero las primeras dimensiones son las que más inercia resumen y nada asegura que sean las que mejor separan los grupos, por lo que en otros datos podría no repetirse.

El anexo de la clase mostraba que, sin usar la ubicación, los grupos recuperaban zonas de Bogotá, y aquí pasa lo mismo con la taxonomía: `tipo` nunca entró al agrupamiento y aun así se recupera, con los mejores resultados en Gower jerárquico (0.94 con enlace simple y 0.89 con promedio) y el más bajo en k-modas con arranque de Huang (0.63). Cerramos con las limitaciones de cada método y las conclusiones.

**Preguntas probables**
- **¿Qué es independencia local y se cumple?** Que, conocida la clase, un atributo no dice nada de otro. En Zoo falla para pelo y leche, por lo que el modelo puede necesitar más clases o confundirlas.
- **¿Por qué BIC y AIC eligen distinto?** El BIC multiplica cada parámetro por log(n) ≈ 4.6 y el AIC por 2, de forma que con 21 parámetros por clase adicional el BIC frena antes (k = 4) y el AIC llega a k = 7.
- **¿Cómo se cuentan los parámetros del BIC?** Son (K − 1) proporciones más K·Σ(R_j − 1) probabilidades, que en Zoo con 16 atributos crece rápido.
- **¿Qué mide el ARI?** El acuerdo entre dos particiones corregido por el acuerdo que se esperaría al azar, sin importar cómo se numeren los grupos (1 es acuerdo perfecto y 0 es azar).

---

## Tabla de resultados (para todos)

| Método (K = 7) | ARI contra `tipo` |
|---|---|
| K-modas, arranque Huang (costo 138) | 0.626 |
| K-modas, arranque aleatorio (costo 139) | 0.830 |
| Gower + PAM | 0.644 |
| Gower + jerárquico promedio | 0.889 |
| Gower + jerárquico simple | 0.935 |
| Clases latentes (K = 7 / K = 4 por BIC) | 0.826 / 0.819 |
| Tándem ACM + k-medias | 0.829 |
