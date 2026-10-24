# Guion de exposición — Clustering de variables cualitativas

Duración objetivo: **12–13 min** en cuatro partes de unos 3 minutos (la rúbrica penaliza desde los 15). El reparto vive en `main.tex` (`\exponeUno` … `\exponeCuatro`) y sale en el pie de cada diapositiva; cambiarlo es cambiar esas cuatro líneas.

Dos usos del mismo guion:
- **Video:** cada integrante graba su parte, de forma que la diapositiva de relevo («Parte n de 4») marca el corte y la frase de traspaso cierra cada parte.
- **En vivo:** expone quien salga al azar, por lo cual cada parte se escribió para entenderse sola y **los cuatro deben ensayar las cuatro**.

El hilo de todo es la sesión 5 (`SL_4.pdf`, cuaderno `NB4_PRF.Rmd`): se repite su arco paso a paso, cambiando la distancia, el centro o el modelo. Cuando el profe preguntó en clase por variables cualitativas respondió que «es por ese tema de trabajo… sí se puede», y conviene recordarlo al abrir.

> **Nota:** las cifras salen de la CLI del lab, la misma que genera las figuras (`projects/final/figuras.sh`: Zoo, k = 7, semilla 42, 25 reinicios) y deben revisarse contra el cuaderno final antes de grabar, pues si cambia la semilla o el arranque cambian los grupos.

---

## Parte 1 — La pregunta de la sesión 5 y los datos (Anyelo · 3 min)

**Diapositivas:** portada → cuatro partes → relevo 1 → «La pregunta que quedó abierta» → «El mismo arco, con categorías» → «101 animales» → «Asociación» → «Primer plano factorial del ACM».

**Guion.** En la sesión 5 se agruparon 15 estaciones de Bogotá con cinco contaminantes, usando la distancia euclídea, estandarizando siempre y resumiendo cada grupo con su media, de forma que la pregunta natural que surgió en clase fue qué pasa cuando las variables son cualitativas, pues no existe la media de «tiene plumas» ni tiene sentido estandarizar un «sí/no». La propuesta de esta presentación es recorrer exactamente el mismo arco de la clase (la tabla lo muestra fila por fila) cambiando solo una de tres piezas: la **distancia**, el **centro** o el **modelo**.

Como datos se usa Zoo (UCI), con 101 animales descritos por 15 atributos binarios y el número de patas (tratado como categoría, ya que 5 patas no es «más» que 4 en ningún sentido útil), y además la clase real `tipo` (mamífero, ave, pez, etc.), que **no entra** al agrupamiento y se guarda para el final, igual que la ubicación geográfica en el anexo de la clase. La asociación entre atributos cumple el papel de la matriz de correlación, de forma que pelo y leche van juntos como lo hacían CO y NO por venir de la misma fuente, y el ACM es el ACP de las cualitativas, por lo cual su primer plano factorial se usa igual que en clase: como **herramienta de diagnóstico** para ver los grupos, no como parte del agrupamiento.

**Traspaso:** «Ya vimos los datos; ahora, ¿cómo se mide que dos animales se parecen? Eso lo explica [Parte 2].»

**Preguntas probables**
- **¿Por qué patas como categoría?** Porque los valores (0, 2, 4, 5, 6, 8) separan formas de cuerpo y no una cantidad que se promedie con sentido.
- **¿Por qué ACM y no ACP?** El ACP necesita variables cuantitativas, mientras que el ACM descompone la tabla de cruces de categorías (la matriz de Burt), que es el análogo de la matriz de covarianzas.

---

## Parte 2 — Distancia, calidad de la partición y k-modas (Daniel · 3 min)

**Diapositivas:** relevo 2 → «Duros y suaves» → «De la euclídea a los desacuerdos» → «Calidad de la partición» → «Lloyd con otro centro» → «K-modas paso a paso» → «Advertencia: la inicialización» → «Perfiles de los grupos».

**Guion.** Como en clase, se distinguen los métodos duros, que dan una etiqueta por animal, de los suaves, que dan un vector de probabilidades de pertenencia, y para cada caso existe una versión cualitativa (k-modas y Gower en los duros, clases latentes en los suaves). La distancia euclídea se reemplaza por el **emparejamiento simple**, que cuenta en cuántos atributos difieren dos animales, con el detalle de que todas las variables ya están en la misma escala y por eso no hay nada que estandarizar; cuando hay variables mixtas se usa Gower, que normaliza cada numérica por su rango y cumple el papel del «estandarizar siempre».

La fórmula de calidad de la partición que se vio en clase (la suma de distancias dentro de cada grupo dividida por su tamaño) no necesita un centro, solo distancias, de forma que funciona igual cambiando la euclídea al cuadrado por los desacuerdos. K-modas es el algoritmo de Lloyd con otro centro: se eligen K animales como modas iniciales, se asigna cada animal a la moda con menos desacuerdos, se recalcula la moda de cada atributo dentro del grupo y se repite hasta que nadie cambie, y la moda es el centro correcto porque el costo se separa por atributo y lo minimiza la categoría más frecuente (Huang, 1998).

La advertencia de la clase sobre la inicialización se cumple aquí con fuerza: el arranque de Huang da un costo de 138 desacuerdos y un ARI de 0,63, mientras que un arranque aleatorio da 139 y un ARI de 0,83, de forma que, igual que con `nstart`, se corre varias veces y se toma el menor costo, sabiendo que el menor costo no garantiza recuperar la estructura real. El mapa de perfiles se lee como el retrato de cada grupo (qué categoría domina en cada atributo).

**Traspaso:** «Fijamos K = 7, pero ¿de dónde sale ese número? Eso lo explica [Parte 3].»

**Preguntas probables**
- **¿Por qué no k-medias sobre variables 0/1?** La media de dummies es una proporción y no una categoría, por lo cual el centro deja de ser interpretable, y la euclídea sobre dummies cuenta doble cada desacuerdo en variables de muchas categorías.
- **¿Qué pasa si hay empate en la moda?** Se rompe por una convención fija (la primera categoría), y es una de las fuentes de inestabilidad.

---

## Parte 3 — Elegir K y jerárquico sobre Gower (Tania · 3 min)

**Diapositivas:** relevo 3 → «Dos guías» → «Los tres enlaces» → «Cortar el árbol» → «¿Qué tan concordantes son?».

**Guion.** La sesión 5 dio dos guías para elegir K y ambas se trasladan: el primer plano factorial (aquí del ACM) para contar grupos a ojo, y el método del codo, que en lugar de la reducción de d² usa la reducción de desacuerdos al agregar grupos, buscando el punto donde agregar uno más aporta poco. Como en clase, el codo es heurístico y gana confianza cuando coincide con el plano factorial.

El agrupamiento jerárquico resuelve las dos limitaciones de k-modas (no exige K de antemano y no depende de un arranque aleatorio) y funciona con cualquier matriz de distancias, por lo cual basta con darle la de Gower. Se comparan los tres enlaces de clase (completo, promedio y simple) en un solo círculo, un sector por enlace con la misma distancia y el mismo corte (la raíz adentro, las hojas en el borde y un punto grande donde nace cada grupo), y el promedio vuelve a ser el más robusto mientras el simple forma cadenas, lo que se ve en sus ramas largas y escalonadas y en los animales que quedan como grupos de uno; cortando el árbol de enlace promedio en 7 grupos se obtiene un ARI de 0,89 contra la clase real, el mejor de todos los métodos. Finalmente, como en la tabla `K_means × Jerárquico` de la clase, se cruzan k-modas y el jerárquico, de forma que donde discrepan aparecen los animales de frontera.

En el dendrograma, la primera gran separación (altura 0,52) deja a los mamíferos de un lado y al resto del otro, y luego se separan peces, anfibios y reptiles de aves e invertebrados; el ornitorrinco, que es un mamífero que pone huevos, queda en un grupo pequeño junto a la tortuga, que es justo el tipo de animal de frontera que un método duro tiene que forzar a un solo grupo.

**Traspaso:** «Hasta aquí todo fue duro: cada animal en un solo grupo. ¿Y si un animal está entre dos? Eso lo explica [Parte 4].»

**Preguntas probables**
- **¿Por qué Gower y no emparejamiento simple en el jerárquico?** Con datos solo categóricos son equivalentes (Gower = desacuerdos / p), y Gower además permite mezclar numéricas y binarias asimétricas.
- **¿Por qué no Ward?** Ward supone geometría euclídea, que Gower no tiene.

---

## Parte 4 — Clases latentes, tándem y anexo (Over · 3 min)

**Diapositivas:** relevo 4 → «El GMM de las categorías» → «¿Cuántas clases?» → «Clases latentes en el plano» → «El tándem» → «La estructura que no se midió» → «Dónde se rompe cada uno» → «Para llevarse».

**Guion.** En clase se dejó el GMM (el método suave con normales y EM) para cursos más avanzados, y su versión categórica son las **clases latentes**: donde el GMM pone una normal, aquí va un producto de distribuciones categóricas, bajo el supuesto de independencia local (dentro de cada clase los atributos no dependen entre sí). Se estima con EM, alternando las probabilidades de pertenencia de cada animal con las nuevas proporciones y probabilidades por clase, y K se elige con BIC, que en Zoo elige **4 clases** (ARI 0,82) aunque haya 7 tipos, mientras que forzando 7 clases el ARI apenas sube a 0,83, de forma que el BIC paga pocos parámetros por casi la misma recuperación, mientras que el AIC, que castiga menos cada parámetro, tiene su mínimo justo en 7 clases, el número real de tipos. Cada k de esa tabla se ajusta con los mismos 25 arranques, por lo cual la verosimilitud crece con k como debe (con menos arranques un k alto quedaba en un máximo local peor, el mismo problema de k-medias).

La tabla de cruce con K = 4 muestra qué se fusiona: una clase de mamíferos (39), una de aves (20, con un reptil), una de insectos e invertebrados juntos (18) y una de animales acuáticos y de sangre fría (13 peces, 4 anfibios, 4 reptiles y 2 mamíferos), de forma que el BIC absorbe justamente las clases pequeñas.

En clase se dijo que el ACP es diagnóstico y no parte del proceso; el tándem (ACM a 5 dimensiones y luego k-medias) se muestra como contraejemplo honesto, ya que aquí recupera bien los tipos (ARI 0,81), pero las primeras dimensiones resumen inercia y no separación entre grupos, por lo cual no hay garantía de que se repita en otros datos.

El anexo de la clase mostraba que, sin usar la ubicación, los grupos recuperaban zonas de Bogotá, y aquí ocurre lo mismo con la taxonomía, pues `tipo` nunca entró al agrupamiento y aun así se recupera, con el mejor resultado en Gower jerárquico (0,89) y el más bajo en k-modas con arranque de Huang (0,63). Se cierra con los fallos de cada método y la idea de fondo: con datos cualitativos no se agrupa distinto, se **mide** distinto.

**Preguntas probables**
- **¿Qué es independencia local y se cumple?** Que, conocida la clase, un atributo no informa sobre otro, y en Zoo falla para pelo y leche, por lo cual el modelo puede necesitar más clases o confundirlas.
- **¿Por qué BIC y AIC eligen distinto?** El BIC multiplica cada parámetro por log(n) ≈ 4,6 y el AIC por 2, de forma que con 21 parámetros por clase adicional el BIC frena antes (k = 4) y el AIC llega a k = 7.
- **¿Cómo se cuentan los parámetros del BIC?** (K − 1) proporciones más K·Σ(R_j − 1) probabilidades, que en Zoo con 16 atributos crece rápido.
- **¿Qué mide el ARI?** El acuerdo entre dos particiones corregido por el acuerdo esperado al azar, sin depender de cómo se numeren los grupos (1 es acuerdo perfecto, 0 es azar).

---

## Tabla de resultados (para todos)

| Método (K = 7) | ARI contra `tipo` |
|---|---|
| K-modas, arranque Huang (costo 138) | 0,626 |
| K-modas, arranque aleatorio (costo 139) | 0,830 |
| Gower + PAM | 0,644 |
| Gower + jerárquico promedio | 0,889 |
| Clases latentes (K = 7 / K = 4 por BIC) | 0,826 / 0,819 |
| Tándem ACM + k-medias | 0,812 (lab, Lloyd) · 0,829 en el cuaderno (`kmeans()` de R, nstart = 100) |
