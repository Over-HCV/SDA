Análisis Estadístico de Datos
 Profesor: Nicolás López

Dependencias
Para la ejecución de este cuaderno, debe instalar con anterioridad los siguientes paquetes desde la consola de R o usando el menú Tools>Install Packages en RStudio:

```
install.packages("plotly").
install.packages("MASS").
install.packages("psych").
install.packages("tidyverse").
install.packages("factoextra").
install.packages("GGally").
```

Instrucciones
La calificación se dará sobre 100 puntos y el trabajo se desarrolla en grupos preestablecidos en el archivo excel. Asegúrese de seleccionar su grupo en la plataforma.
Se motiva a los estudiantes a desarrollar un cuaderno en R markdown, en dado caso debe ser entregado el archivo pdf (el cual puede obtener siguiendo estas instrucciones). Además, es sugerido que el trabajo sea versionado para trabajar de manera colaborativa en el mismo, esto es completamente opcional pero altamente recomendado (los detalles del versionamiento en github lo encuentra aquí y un ejemplo de uso en trabajo en equipo aquí).
Puede enviar el taller antes de la fecha estipulada sin que esto tenga efecto alguno en la nota.
Recuerde indicar y cargar los paquetes necesarios para la elaboración del taller.
Múltiples ayudas se encuentran a lo largo de los ejercicios del taller. Estas dan indicios para la solución de los puntos, pero no necesariamente deben ser usados para solucionar las preguntas. Puede haber diferentes formas de dar solución a la pregunta.
El documento entregado debe contener el código correspondiente como parte de este. En caso que no esté presente, se penalizará el trabajo con 30 puntos.
Calificación
La importancia de cada pregunta para la nota final se presenta mediante la letra 𝑤
. La nota final del parcial está dada por
∑𝑖=1𝑘𝑤𝑖=100
Dónde 𝑘
 representa el número de preguntas.
Sean concisos al momento de justificar los puntos e incluir solamente aquellos gráficos y tablas para la discusión. Esto será considerado en la nota.
Una excelente presentación y orden se verán reflejados de manera positiva en la nota final.
EIA data
U.S. Energy Information Administration (EIA) es una organización que se encarga de recopilar, analizar y difundir información energética de manera independiente e imparcial para promover la formulación de políticas sólidas, mercados eficientes y la comprensión pública de la energía y su interacción con la economía y el medio ambiente.


Los datos que trabajaremos a continuación corresponden a la extracción de diferentes variables relacionadas con energías renovables y combustibles fósiles, las UE son 111 países de todos los continentes del mundo, seleccionados para fines académicos por ser aquellos países que presentan mayor cantidad de información de análisis.

El objetivo de este análisis es encontrar diferentes relaciones entre los países que se están estudiando, de tal forma que podamos caracterizar en términos de importación, exportación, consumo, producción, etc. a los países de estudio.

Librerías
library(tidyverse)
## ── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
## ✔ dplyr     1.1.4     ✔ readr     2.1.5
## ✔ forcats   1.0.0     ✔ stringr   1.5.1
## ✔ ggplot2   3.5.2     ✔ tibble    3.2.1
## ✔ lubridate 1.9.4     ✔ tidyr     1.3.1
## ✔ purrr     1.0.2     
## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
## ✖ dplyr::filter() masks stats::filter()
## ✖ dplyr::lag()    masks stats::lag()
## ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
library(plotly)
## 
## Attaching package: 'plotly'
## 
## The following object is masked from 'package:ggplot2':
## 
##     last_plot
## 
## The following object is masked from 'package:stats':
## 
##     filter
## 
## The following object is masked from 'package:graphics':
## 
##     layout
library(MASS) 
## 
## Attaching package: 'MASS'
## 
## The following object is masked from 'package:plotly':
## 
##     select
## 
## The following object is masked from 'package:dplyr':
## 
##     select
library(psych)
## 
## Attaching package: 'psych'
## 
## The following objects are masked from 'package:ggplot2':
## 
##     %+%, alpha
library(factoextra)
## Welcome! Want to learn more? See two factoextra-related books at https://goo.gl/ve3WBa
library(GGally)
## Registered S3 method overwritten by 'GGally':
##   method from   
##   +.gg   ggplot2
<!-- Dataset online `path = kagglehub.dataset_download("overhcv/eia-united-states")`, keep as a comment, better use this as is online -->
data1 <- read.csv("datos_taller_02.csv", row.names=1, sep=";")
Normal multivariada
Pregunta 1. 𝑤2=5
Encuentre la estimación del vector de medias y la matriz de varianzas y covarianzas para 5 variables de su interés del conjunto de datos.

ACP
Pregunta 2. 𝑤2=5
Realice un análisis descriptivo univariado y bivariado del conjunto de datos. Considere nuevamente las mismas 5 variables de su interés para este punto.

Ayuda:

La función ggpairs() puede serle de utilidad para ver las asociaciones dos a dos entre las variables de una manera sencilla.
Pregunta 3. 𝑤3=8
El conjunto de datos incluye 57 variables, analizarlas de forma individual podría representar un gasto computacional y de tiempo bastante agotador; por lo cuál una técnica de reducción de dimensionalidad sería ideal. Ejecute un ACP sobre estos datos, compare la contribución de las variables sobre el primer plano factorial de un ACP normado (escalado) y uno sin normalizar (sin escalar).

Pregunta 4. 𝑤4=8
Una vez calculado el PCA normado, ¿qué número de componentes principales deberíamos seleccionar? ¿Bajo que criterio seleccionó este número de componentes?

Pregunta 5. 𝑤5=8
Analice la representación de las variables originales sobre las dos primeras componentes en el primer plano factorial. ¿Que conclusiones podemos sacar de este análisis?

Ayuda:

En clase utilizamos herramientas base para realizar múltiples gráficos del análisis de componentes principales. Esta vez, se invita a los estudiantes usar la función fviz_pca_var() de factoextra, pero no es necesario.

Utilice la función fviz_pca_var() de factoextra; para seleccionar diferentes componentes principales. Existe un parámetro de la función donde deberá especificar las componentes que desea graficar, estas entran como un vector de la siguiente forma axes=c(1,2).

Puede filtrar las 30 variables que contribuyen más a la construcción del eje, también existe un parámetro en la función fviz_pca_var() para seleccionar este número.

Busque la forma de disminuir el tamaño de los nombres de las variables para evitar saturar de información el gráfico.

En contraste al ejercicio de clase, en este contamos con una cantidad mayor de componentes relevantes para el análisis, por lo cual, realice el mismo gráfico anterior pero ahora sobre el plano factorial conformado por los componentes 2 y 3. ¿Qué conclusiones podemos sacar de este gráfico?

Pregunta 6. 𝑤6=10
Ahora examine con detenimiento el mapa de individuos sobre los planos factoriales que conforman las componentes (1,2) y (2,3). ¿Qué conclusiones puede sacar según la cercanía de algunas UE?

Ayuda:

En clase utilizamos herramientas base para realizar múltiples gráficos del análisis de componentes principales. Esta vez, se invita a los estudiantes usar la función fviz_pca_ind() de factoextra, pero no es necesario.
Pregunta 7. 𝑤7=12
Como hemos observado en clase, el ACP es una técnica bastante sensible a datos atípicos, ejecute nuevamente el ACP retirando del conjunto de datos a Estados Unidos, China, Arabia Saudi y Rusia. ¿En que cambia el ACP al excluir estos países?. ¿Se perciben clusters de países con mayor claridad?. Calcule únicamente el ACP normado.

Clustering
Los puntos 8 a 11 se realizarán excluyendo de la base de datos los países atípicos mencionados en el punto 7 (es decir, retirando ‘UnitedStates’,‘China’,‘SaudiArabia’,‘Russia’).

Pregunta 8. 𝑤8=8
De acuerdo a lo aprendido en la clase de agrupamiento, utilice el primer plano factorial para determinar de manera aproximada el número de grupos en el análisis. ¿Cuántos clusters espera que existan en el conjunto de datos?

Pregunta 9. 𝑤9=12
Mediante el método de reducción de varianza explicada, determine un número fijo de clusters para su análisis. No tiene que ser el mismo número que el elegido por su compañero, recuerde que ninguno conoce las etiquetas reales de los grupos de los países.

Pregunta 10. 𝑤10=12
Determine mediante k-means y aglomeración jerárquica (usando enlace promedio) la clasificación en grupos para los países de estudio. Considere todas las variables de estudio ¿son diferentes los resultados de los dos análisis cluster?

Pregunta 11. 𝑤11=12
Grafique mediante boxplot la distribución de las 5 variables seleccionadas en el punto 2 diferenciando por los grupos encontrados mediante k-means (es decir, obtenga un boxplot por variable y por grupo: si por ejemplo k-means indica un total de 3 grupos, realice 3 boxplots, uno por grupo, para cada una de las 5 variables). ¿Observa diferencias importantes entre las distribuciones por grupos de la misma variable?