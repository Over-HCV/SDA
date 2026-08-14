## Para qué sirve

Ver de cuánto es el desbalance y decidir si hace falta hacer algo. La
respuesta muchas veces es que no: un 60/40 no necesita tratamiento, y
rebalancear por costumbre estropea la calibración de las probabilidades que
salen del modelo.

## Qué muestra

Cuántas observaciones hay por clase, antes y después de rebalancear. El
subtítulo trae la razón de desbalance: cuántas veces la clase mayoritaria supera
a la minoritaria.

Las tres técnicas disponibles no traen dependencias nuevas y no inventan datos:

- **sub-muestreo** — recorta las clases grandes. Se pierde información real.
- **sobre-muestreo** — repite filas de las chicas. No agrega información.
- **bootstrap** — remuestrea todas con reemplazo hasta un tamaño común.

SMOTE, que interpola entre vecinos y sí fabrica filas nuevas, está en el
catálogo como pendiente: pedirlo suma un paquete al bundle.

## Qué buscar

- **La razón de desbalance**: por debajo de 3 a 1 casi nunca hace falta tocar
  nada. Por encima de 20 a 1 el problema es real.
- **Cuánto se pierde con sub-muestreo**: si la minoritaria tiene 40 casos, la
  mayoritaria queda en 40 y tiraste miles de filas.
- **Cuánto se repite con sobre-muestreo**: si una fila aparece 30 veces, el
  modelo la va a memorizar.
- **Clases con menos de 10 casos**: ninguna técnica las salva.

## Cuándo engaña

**Balancear cambia las probabilidades a priori.** Después de rebalancear, las
probabilidades que estime el modelo no son las de la población: están calibradas
para el mundo artificial 50/50 que construiste.

**El desbalance a veces no es el problema.** Con clases separables, un modelo
aprende bien con 1 % de positivos. Lo que suele estar mal es la métrica:
exactitud con 99 % de negativos se gana prediciendo siempre "no". Antes de
remuestrear, probá cambiar de métrica o usar pesos de clase.

**Nunca se rebalancea la partición de prueba.** Solo el entrenamiento. Si tocás
la prueba, estás midiendo el desempeño en una población que no existe.
