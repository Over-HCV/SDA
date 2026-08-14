## Para qué sirve

Elegir λ, y sobre todo elegir uno redondo. Si la curva es plana alrededor del
máximo, conviene el λ interpretable —el logaritmo, la raíz— antes que el
óptimo con cuatro decimales que después nadie puede explicar.

## Qué muestra

La log-verosimilitud de la familia de Box-Cox en función de λ. La familia es una
sola fórmula que contiene a casi todas las transformaciones que se usan a mano:

$$
y(\lambda) =
\begin{cases}
\dfrac{y^{\lambda} - 1}{\lambda} & \text{si } \lambda \neq 0 \\[10pt]
\log(y) & \text{si } \lambda = 0
\end{cases}
$$

λ = 1 deja la variable como está, λ = 0,5 es la raíz, λ = 0 es el logaritmo y
λ = −1 es el inverso. La curva dice qué λ hace a los datos lo más parecidos
posible a una normal; la línea naranja marca el máximo y la punteada, el valor
redondo más cercano.

## Qué buscar

- **Dónde está el máximo**: es el λ sugerido.
- **Qué tan plana es la curva alrededor**: si entre λ = 0 y λ = 0,25 casi no
  baja, elegí el 0. Un logaritmo se interpreta; un λ = 0,17 no se interpreta.
- **Curva muy picuda**: la transformación importa mucho, conviene respetar el
  óptimo.
- **Máximo cerca de 1**: no hace falta transformar nada.

## Cuándo engaña

**Optimiza normalidad, no interpretabilidad.** El criterio es puramente
estadístico y no sabe que el logaritmo de un ingreso significa algo y su
potencia 0,37 no significa nada para nadie.

**Exige valores positivos.** Con ceros o negativos, la columna se desplaza antes
de calcular el perfil, y ese desplazamiento cambia el λ óptimo. Dos
desplazamientos distintos dan curvas distintas.

**El λ estimado también tiene incertidumbre.** Es un parámetro más, estimado de
los mismos datos, y usarlo después como si fuera conocido subestima los errores
estándar de todo lo que venga.

**Normalizar la variable no es el objetivo de casi ningún método.** La regresión
pide residuos bien portados. Transformar la respuesta para que la variable se
vea normal puede empeorar el modelo, no mejorarlo.
