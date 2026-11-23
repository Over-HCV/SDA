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

**IDEA:** En las partes 2 y 3 cambiamos el centro y la distancia para estimar *(cerrando con la interrogante de qué pasa con un animal que está entre dos grupos;
Los métodos duros lo obligarían a escoger uno)*. Aquí cambiamos el modelo *(un modelo suave le da una probabilidad de pertenecer a cada grupo)*:
- ENTONCES = no los buscamos por cercanía SUPONEMOS que hay **grupos ocultos** que generan los datos, los estimamos.
- Después revisamos ese atajo de agrupar sobre el ACM y validamos CÚANTO de la clase real encontraron los métodos sin NUNCA haberla visto.

### 1. Modelo de clases latentes

> 🚫 Antes con GMM partíamos del supuesto que grupo sigue una normal.
> > Con categorías no hay normal [nazca naturalmente], así que cada clase se describe con una tabla de probabilidades:
>>- Dice qué tan probable es que un animal de esa clase; Tenga pelo | Ponga huevos | Es cuadrú-pedo.
> La fórmula busca decir eso:
1. El exponente 0 o 1 = quedarse solo con la $\theta$ de la categoría que el animal sí tiene
   - $\prod \theta$: Prob. [anim] $\in c$ (class) tenga cat. $r$ como att $k$.
   - $\theta_{\text{leche}, \text{sí}, \text{mamíferos}} \approx 1$
2. Mult. esas probabilidades en [16] atributos =es (independencia local).
3. Como no sabemos de qué clase es el animal se promedian todas las clases, **PE**-SANDO cada una por su tamaño.
   - $\sum_1^K\pi_c$: Sum. prob. [anim] $\in$ clase latente ($\sum=1$)


> Con eso logramos definir la probabilidad para un animal como una mezcla de clases


> Multiplicar solo vale si dentro de una clase los atributos no dependen entre sí **(independencia local)**. Es el supuesto fuerte del modelo y lo retomamos en las limitaciones.

### 2. Clases latentes en R: El algoritmo EM (Maximización Esperanza)

**El insight.** Usa el mismo esquema de k-medias y k-modas (asignar y actualizar), con la diferencia de que la asignación es suave <!---ejemplo inline?--->.
Hereda el mismo problema de los arranques <!---qué problema?--->,
por eso corremos 25 y nos quedamos con el mejor.

**Qué contar.** El modelo se estima con EM, que alterna dos preguntas.

Primeramente [paso E] nos preguntamos  
- a partir de lo que sé de cada clase
- qué tan probable es que cada animal pertenezca a cada una. 

 En el [paso M]:
- Con esas probabilidades, recalculamos cómo es cada clase.
 
 
Se repite hasta que la verosimilitud [converja] deja de subir. <!---pero no veo como el condicional ese, no? O no importa?--->

### 3. Número de clases: BIC y AIC (Akaike)

**Qué contar.** Más clases siempre ajustan mejor los individuos "datos", así que la verosimilitud SOLA no sirve para elegir K.

Los criterios de información lo que hacen es cobrarle al modelo por cada parámetro:
- Al Crit. Bay cobra más que al Crit. de Aka,
- Por eso eligen distinto (4 clases el BIC y 7 el AIC).

Ninguno está mal, cada uno responde una pregunta distinta. El BIC YA dice que con 4 clases ya se explica significativamente  <!--decir "casi todo" me parece algo ambiguo, no?-->
- Para eso junta las clases pequeñas (anfibios y reptiles con los peces, insectos con invertebrados),
- mientras que el AIC acepta pagar más parámetros para separarlas.
 
> Que Crit. Aka caiga en 7, el número real de tipos, es interesante pero no lo tomamos como prueba.

>Es el mismo dilema del codo: Hasta dónde vale la pena complicar el modelo.

### 4. Perfil de las 4 clases

Esta es la salida principal de un [análisis de clases latentes]. Para .CADA clase vemos la probabilidad de CADA atributo + TAMAÑO de la clase, es con eso le ponemos *NOMBRE*:
- La clase con pelo y leche son los mamíferos
- la de plumas y huevos son las aves
- la de dientes y vida acuática son los peces, anfibios y reptiles
- y la que no tiene columna ni dientes son los insectos e invertebrados.

<!-- **El insight.** El modelo nunca vio la clase real y aun así cada clase se puede leer como un grupo de la taxonomía.--->

Algo que pasó en Zoo es que los animales lograron quedar en su clase con probabilidad muy alta,
 aquí el método **[suave]** terminó comportándose casi como uno duro porque en ese esecenario clases están MUY SEPARADAS.

### 5. ACM seguido de k-medias (tándem) [A. Corresp. Múlt.]

**Qué contar.** Una TENTACIÓN natural sería convertir las categorías en números con el ACM y luego aplicar el k-means de siempre.
El problema: se nos avisó que el ACP=(An. Com. Prin.) sirve para diagnosticar y que el agrupamiento se hace sobre las variables originales, y este es el caso de esa advertencia.

> El ACM ordena las dimensiones por [cuánta inercia resumen] y NADA asegura que esas sean las que [**separan** los grupos] <!---siento que falta como un ejecmplo más obvio/intuitivo, no tan teórico y términos rimbombantes--->.

> Aquí funciona bien PERO porque los datos nos ayudan.

> Si fueran otros datos donde los grupos se distinguen por un atributo que varía poco, el tándem lo puede perder.


### 6. Validación con la variable tipo

AHORA SÍ esas clases reales que nunca entraron a ningún AJUSTE [ahora la usamos] para ver CUÁNTO de la taxonomía encontró cada método;

> ARI (Ind.Ajus. de Rand) MIDE ese acuerdo corregido por el azar.

**El insight.** Todos recuperan buena parte de la taxonomía, lo que dice que la estructura está en los datos y cada método la encuentra a su manera.

Las diferencias muestran qué premia cada uno:
- Los que arman grupos alrededor de un centro (k-modas y PAM) parten a los mamíferos en dos porque buscan grupos parecidos en todos los atributos,
- mientras que el jerárquico los deja juntos.

> Eso sí, un ARI alto <!---qué es alto? Cercano a 1?---> dice que la {estructura} coincide con esta clase y no que el {método} sea mejor en cualquier conjunto de datos.

### 7. Limitaciones de cada método

Cada método falla justo por la pieza que cambió.
- K-modas = el centro: Depende del arranque y la moda empata con facilidad.
- Gower = la distancia: Pesa igual todos los atributos y hay que decidir qué binarias son asimétricas.
- Clases latentes = el modelo: Suponen independencia local, que en Zoo no se cumple con pelo y leche. 
- y Tándem = el atajo: Las dimensiones del ACM resumen inercia y nada asegura que separen grupos.

**El insight.** Ningún método gana en todo, por eso vale la pena comparar varios y mirar dónde discrepan,
> Ahí están los animales de frontera.

### 8. Conclusiones

La diapositiva dice **qué** concluimos y aquí va el **por qué** de cada punto. El gráfico de la izquierda muestra cuánto recuperó cada método, así que no hace falta decir los números.

- **Ningún método gana en todo.** El que mejor recupera la clase no es el que mejor respeta las distancias, y el que no deja animales sueltos parte a los mamíferos. Por eso vale la pena comparar varios: Donde no coinciden están los animales difíciles, como el ornitorrinco.
- **Cambia una pieza.** No tuvimos que inventar otro análisis. El de siempre funciona si cambiamos la pieza que dependía de que los datos fueran números:
  - Restar (la distancia)
  - promediar (el centro)
  - o suponer una normal (el modelo).
- **Todos recuperan la taxonomía.** Ningún método vio el tipo de animal y aun así todos lo encontraron en buena medida. Eso nos dice que los grupos ya están en los datos y que no fueron un invento del método.
- **El ACM para ver, el agrupamiento para formar.** El ACM fue el mapa para mirar los datos, pero agrupar directamente sobre él es un atajo que aquí funcionó y que en otros datos podría fallar.

---

**Preguntas probables**
- **¿Qué es independencia local y se cumple?** Que, conocida la clase, un atributo no dice nada de otro. En Zoo falla para pelo y leche, por lo que el modelo puede necesitar más clases o confundirlas.
- **¿Por qué BIC y AIC eligen distinto?** El BIC multiplica cada parámetro por log(n) ≈ 4.6 y el AIC por 2, de forma que con 21 parámetros por clase adicional el BIC frena antes (k = 4) y el AIC llega a k = 7.
- **¿Cómo se cuentan los parámetros del BIC?** Son (K − 1) proporciones más K·Σ(R_j − 1) probabilidades, que en Zoo con 16 atributos crece rápido.
- **¿Qué diferencia hay entre categoría y clase?** Un atributo es una característica (pelo, patas), una categoría es uno de sus valores posibles (sí o no, 0 o 4 patas) y una clase es un grupo de animales. Cada clase latente se describe con la probabilidad de cada categoría de cada atributo.
- **¿Qué mide el ARI?** El acuerdo entre dos particiones corregido por el acuerdo que se esperaría al azar, sin importar cómo se numeren los grupos (1 es acuerdo perfecto y 0 es azar).

---

## Tabla de resultados (para todos)

| Método (K = 7)                          | ARI contra `tipo` |
| --------------------------------------- | ----------------- |
| K-modas, arranque Huang (costo 138)     | 0.626             |
| K-modas, arranque aleatorio (costo 139) | 0.830             |
| Gower + PAM                             | 0.644             |
| Gower + jerárquico promedio             | 0.889             |
| Gower + jerárquico simple               | 0.935             |
| Clases latentes (K = 7 / K = 4 por BIC) | 0.826 / 0.819     |
| Tándem ACM + k-medias                   | 0.829             |
