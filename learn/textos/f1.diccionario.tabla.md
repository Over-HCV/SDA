## Qué muestra

Una fila por columna del dataset, con lo que la app necesita saber de ella:
etiqueta, escala de medición, clase y rol.

```
escala ∈ {nominal, ordinal, intervalo, razon}
clase  ∈ {cualitativa, discreta, continua}
rol    ∈ {respuesta, predictor, id, grupo, peso, ignorar}
```

La escala no se puede deducir del tipo de dato, y ahí está todo el punto: un
código postal es numérico y es nominal; un año es entero y es de intervalo,
porque su cero es convencional. La autodetección propone; vos corregís.

**Esta tabla gobierna el resto de la app.** Si marcás una columna como nominal,
el selector de media se deshabilita y aparece la moda, con la razón escrita al
lado. Los métodos de la fase 2 se filtran por lo mismo.

## Qué buscar

- **Identificadores marcados como predictores**: un `id` correlaciona con
  cualquier cosa por accidente y arruina un modelo en silencio.
- **Códigos numéricos que son categorías**: 1 = norte, 2 = sur. Numéricos en
  memoria, nominales de verdad.
- **Años y fechas marcados como razón**: son de intervalo. Duplicar un año no
  significa nada.
- **Columnas con muchos faltantes**: el porcentaje está en la tabla. Por encima
  de 40 %, imputar es inventar estructura.
- **Columnas constantes**: no aportan información y sobreviven hasta la fase 4
  si nadie las marca como ignorar.

## Cuándo engaña

**La detección automática acierta el tipo, no el significado.** Ve números y
propone razón; ve texto y propone nominal. Ordinal e intervalo no los propone
nunca, porque no se pueden inferir: los tenés que poner vos.

**Un rol mal puesto no rompe nada hoy.** La app te deja seguir y el error
aparece dos fases después, cuando un modelo da un R² sospechosamente perfecto
porque metiste el identificador como predictor.

**Los avisos de conflicto son heurísticos.** Que una columna se llame `year` no
prueba que sea un año. El aviso pregunta; la decisión es tuya.
