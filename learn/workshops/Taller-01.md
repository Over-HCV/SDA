# Taller 01
## Análisis Estadístico de Datos
### Profesor: Nicolas Lopez

Librerías sugeridas (funcionales en R 4.2.1)
Recuerde, install.packages(). instala el paquete, pero para que este funcione usted debe invocarlo con library(). Además, un paquete que no ha sido instalado, no puede ser invocado.

```R
library(tidyverse)
library(ggplot2)
library(ggExtra)
library(psych)
library(MVN)
library(dplyr)
```

Instrucciones
La calificación se dará sobre 100 puntos y el trabajo se desarrolla en grupos preestablecidos en el archivo excel. Asegúrese de seleccionar su grupo en la plataforma.
Se motiva a los estudiantes a desarrollar un cuaderno en R markdown, en dado caso debe ser entregado el archivo pdf (el cual puede obtener siguiendo estas instrucciones). Además, es sugerido que el trabajo sea versionado para trabajar de manera colaborativa en el mismo, esto es completamente opcional pero altamente recomendado (los detalles del versionamiento en github lo encuentra aquí y un ejemplo de uso en trabajo en equipo aquí).
Puede enviar el taller antes de la fecha estipulada sin que esto tenga efecto alguno en la nota.
Recuerde indicar y cargar los paquetes necesarios para la elaboración del taller.
Múltiples ayudas se encuentran a lo largo de los ejercicios del taller. Estas dan indicios para la solución de los puntos, pero no necesariamente deben ser usados para solucionar las preguntas. Puede haber diferentes formas de dar solución a la pregunta.
Calificación
La importancia de cada pregunta para la nota final se presenta mediante la letra 𝑤
. La nota final del parcial está dada por
∑𝑖=1𝑘𝑤𝑖=100
Dónde 𝑘
 representa el número de preguntas.
Sean concisos al momento de justificar los puntos e incluir solamente aquellos gráficos y tablas para la discusión. Esto será considerado en la nota.
Una excelente presentación y orden se verán reflejados de manera positiva en la nota final.
Datos del taller
Para el desarrollo del siguiente taller considere la base de datos ORI.csv que contiene información de variables meteorológicas medidas en diferentes lugares de Colombia. Cada observación en la base corresponde a la medición en un momento del día determinado en un municipio de una región dada Se tienen, entre otras, las siguientes variables variables:

Temperatura
Velocidad del viento
Dirección del viento
Presión
Punto de Rocío
Cobertura total nubosa
Humedad
Los datos se pueden encontrar de forma libre en la página del IDEAM

Parte 1. Fundamentos estadísticos
Pregunta 1. 𝑤1=7
Importe la base de datos a R y determine el número de UE y de variables en la base de datos. ¿Cuántas filas y cuántas columnas tiene la tabla?, ¿Cuántos registros fueron medidos o recolectados a medio día (hora = 12:00)?

Pregunta 2. 𝑤2=7
Para los registros recolectados a medio día ¿cuál es el pronóstico climático más frecuente? ¿cuál es el menos frecuente?

Pregunta 3. 𝑤3=7
Clasifique las variables 1) Pronóstico, 2) Municipio, 3) Temperatura y 4) Velocidad del viento según su escala y clase, teniendo en cuenta que:

Pronóstico Pronóstico del clima.
Municipio Municipio de medición
Temperatura Temperatura medida en grados centígrados.
Velocidad del viento Velocidad del viento medida en mph.
Pregunta 4. 𝑤4=7
Para los registros recolectados a medio día, describa de manera gráfica la temperatura y la velocidad del viento univariadamente a partir de un diagrama de caja. ¿Qué características observa los datos en términos de centro, localización y dispersión?.

Pregunta 5. 𝑤5=7
Para los registros recolectados a medio día, describa de manera numérica mediante la función summary() la temperatura y la velocidad del viento univariadamente. ¿Concuerda su descripción con los gráficos de boxplot previamente presentados?.

Pregunta 6. 𝑤6=10
Para los registros recolectados a medio día, determine si existen o no observaciones atípicas univariadas para la variables Presión y Punto de Rocio usando el diagrama de caja de Tukey. ¿cuál variable presenta mayor número de atipicidades?

> Ayuda:
> Desde R, aplicar $out a la función boxplot() como sigue: boxplot(variable,plot=FALSE)$out, permite determinar las observaciones atípicas mediante el criterio de diagrama de caja de Tukey.
Pregunta 7. 𝑤7=10
Para los registros recolectados a medio día, describa de manera gráfica la asociación entre la temperatura y velocidad del viento a partir de un diagrama de dispersión entre las variables. Añada el histograma marginal de cada variable. ¿Parecen correlacionarse las dos variables?

Pregunta 8. 𝑤8=10
Para los registros recolectados a medio día, describa de manera numérica la asociación entre temperatura y velocidad del viento a partir de la covarianza y el coeficiente de correlación de Pearson. ¿Parecen correlacionarse las dos variables? ¿en qué unidades se encuentran cada una de las dos medidas anteriormente mencionadas?

Pregunta 9. 𝑤9=5
Para los registros recolectados a medio día, responda. Son estos datos ¿univariados, bivariados o multivariados?

Parte 2. Estimación de la densidad
Pregunta 10. 𝑤10=10
Para los registros recolectados a medio día, elabore la estimación histograma de la densidad y la estimación kernel de la densidad para la variable Temperatura. ¿Podría afirmar que los datos provienen de una distribución normal?

Pregunta 11. 𝑤11=10
Para los registros recolectados a medio día, elabore la estimación histograma de la densidad y la estimación kernel de la densidad para la variable Presión ¿Es la distribución estimada simétrica? explique.

Pregunta 12. 𝑤12=10
Para los registros recolectados a medio día, elabore la estimación kernel de la densidad para la variable Velocidad del viento. Sobreponga en su gráfico la función de densidad normal con la media y desviación estándar observada en sus datos. ¿Se aproxima el modelo normal estimado a la estimación de la densidad encontrada?

> Ayuda:
> Desde R, sumar geom_density(data=datos_noon,aes(Velocidad_del_Viento)) a un ggplot preexistente, añade la kde de la variable de interés sobre el gráfico anterior. Revise el cuaderno de clase 1.