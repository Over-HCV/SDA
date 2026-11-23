# Cuaderno del proyecto final: Agrupamiento de variables cualitativas

- `clustering-cualitativo.Rmd` es el cuaderno con todo el análisis. Se abre en RStudio y se le da **Knit**.
- `clustering-cualitativo.html` es el mismo cuaderno ya compilado, para leerlo sin correr nada.
- `zoo.csv` es la copia local de los datos. Solo se usa si no hay internet.

Antes de la primera corrida se instalan los paquetes desde la consola de R:

```r
install.packages(c("rmarkdown", "rmdformats", "ggplot2",
                   "cluster", "factoextra"))
```

Los datos se bajan solos de Kaggle ([overhcv/uci-zoo](https://www.kaggle.com/datasets/overhcv/uci-zoo)), que es la base Zoo de UCI. No hace falta nada más del repositorio. La corrida completa toma unos 15 segundos y, con la semilla 42, da los mismos resultados en cualquier computador.
