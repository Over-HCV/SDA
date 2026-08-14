## Para qué sirve

Comprobar si el supuesto de normalidad bivariada es defendible antes de usar
un método que lo necesita. Mahalanobis, el análisis discriminante y la T² de
Hotelling lo suponen sin pedirlo, y ninguno avisa cuando no se cumple.

## Qué muestra

La nube de dos variables con los contornos que encerrarían el 50 % y el 95 % de
la masa si la distribución conjunta fuera normal bivariada. La cruz marca el
centro, que es el vector de medias.

La elipse **es** la matriz de covarianzas dibujada: su inclinación viene de la
correlación y el largo de sus dos ejes, de las varianzas en esas direcciones.
Esos ejes son los componentes principales — este gráfico es el ACP antes de
llamarlo así.

## Qué buscar

- **Inclinación**: cuánto se despega de los ejes horizontales. Sin correlación,
  la elipse queda alineada con los ejes.
- **Excentricidad**: una elipse muy alargada dice que casi toda la variación
  ocurre en una sola dirección; ahí una componente ya resume el par.
- **Puntos fuera del contorno del 95 %**: candidatos a atípico conjunto.
- **Densidad dentro del contorno del 50 %**: si la mitad de los puntos no está
  ahí adentro, la normal bivariada no describe bien estos datos.

## Cuándo engaña

**Supone normalidad bivariada y la dibuja igual cuando no la hay.** Con dos
grupos separados, la elipse los abraza a los dos y pinta como típica la zona
vacía del medio, donde no hay una sola observación. El contorno se calcula
siempre; que tenga sentido es otra cosa.

**Media y covarianza no resisten atípicos.** Un solo punto lejano corre el
centro e infla la elipse, y de paso deja de marcarse como atípico él mismo. Es
el argumento entero a favor de los estimadores robustos.

**El nivel no es una promesa empírica.** "95 %" significa 95 % bajo el modelo
normal, no que el 95 % de tus filas caiga adentro. Contá cuántas caen: la
diferencia es la medida del desajuste.
