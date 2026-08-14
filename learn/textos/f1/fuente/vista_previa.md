## Qué muestra

Las primeras filas de lo que se acaba de cargar, con el pie que dice cuántas se
muestran y cuántas hay. Es la comprobación más barata que existe y la que más
errores atrapa: si la tabla se ve mal acá, todo lo que venga después está mal.

## Qué buscar

- **Columnas de más o de menos**: casi siempre es el separador equivocado en un
  CSV. Si todo el archivo entró en una sola columna, probá `;` o tabulador.
- **Números leídos como texto**: el separador decimal. Con coma decimal y punto
  como separador de miles, `1.234,5` se convierte en texto y ninguna operación
  numérica va a funcionar.
- **Tildes rotas**: es la codificación. UTF-8 y Latin-1 se confunden fácil.
- **Faltantes disfrazados**: `.`, `-99`, `N/A`, celdas vacías. Si no se declaran
  como faltantes, entran al análisis como valores reales.
- **La primera fila**: ¿es un encabezado o ya es un dato?

## Cuándo engaña

**Ver diez filas correctas no dice nada de las 35.000 restantes.** El problema
típico —una columna que cambia de formato a mitad del archivo— no aparece
arriba. La subsección de Calidad es la que mira el archivo entero.

**Un dataset del curso ya cargado también puede estar transformado.** Si en el
pivot país×año ves ceros, muchos no son ceros observados: son pares sin dato
rellenados en la agregación. El panel lo avisa al cargar y conviene creerle.

**El orden de las filas puede no ser inocente.** Si el archivo viene ordenado
por alguna variable, cualquier partición sin barajar hereda ese orden. Por eso
la subsección de Partición baraja siempre y con semilla.
