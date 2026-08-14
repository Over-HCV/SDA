## Para qué sirve

Ver dónde se concentra la masa cuando hay tantos puntos que la dispersión se
vuelve una mancha. Es el reemplazo natural de la dispersión con decenas de
miles de filas, donde el solapamiento esconde justo lo que interesa.

## Qué muestra

La densidad estimada de las dos variables a la vez: el color es cuánta masa hay
en cada punto del plano y las curvas blancas son curvas de nivel, como en un
mapa topográfico. Cada anillo une puntos de igual densidad.

Es la respuesta al sobreploteo llevada al extremo: donde la dispersión pinta
una mancha uniforme, acá se ve el relieve.

## Qué buscar

- **Cuántos picos hay**: dos máximos separados son dos subpoblaciones, y es el
  hallazgo que la correlación jamás va a reportar.
- **Orientación de los anillos**: inclinados hacia arriba a la derecha,
  correlación positiva; hacia abajo, negativa; redondos, cerca de cero.
- **Anillos apretados o anchos**: qué tan concentrada está la nube.
- **Crestas curvadas**: relación no lineal.

## Cuándo engaña

**Los dos anchos de banda mandan igual que en una dimensión.** `h_x` y `h_y`
están en el subtítulo. Chicos, la superficie se llena de picos falsos; grandes,
se convierte en una loma única y suave. Ninguna de las dos es la verdad.

**Suaviza sobre el vacío.** El estimador reparte densidad alrededor de cada
punto, así que pinta color donde no hay ni una observación —sobre todo en los
bordes y entre grupos separados. Dejá los puntos encendidos para ver dónde hay
datos de verdad y dónde hay solo interpolación.

**Con pocas observaciones la superficie es casi la suma de los núcleos.** Por
debajo de unas 50 filas, la dispersión sola es más honesta.
