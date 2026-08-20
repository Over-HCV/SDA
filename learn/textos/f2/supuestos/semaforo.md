## Para qué sirve

Saber, antes de gastar un ajuste, si el método que elegiste tiene algo que
hacer con estos datos. Cada método pide condiciones; el semáforo las evalúa
sobre tu dataset y dice cuáles se cumplen y cuáles no.

## Qué muestra

Una fila por supuesto declarado en el catálogo, con su veredicto:

- **verde** — la condición se cumple, con el número que lo respalda.
- **amarillo** — se puede ajustar igual, pero el resultado hay que leerlo
  sabiendo esto.
- **rojo** — el método no se puede correr así.

No son adornos: los verdes también traen su cifra, porque "se cumple" sin
número no se puede discutir.

## Qué buscar

- **Amarillos que cambian la interpretación.** El aviso de escalado es el caso
  típico del ACP: no impide ajustar, pero decide qué componente sale primera.
  Un amarillo ignorado es un resultado mal leído, no un resultado inválido.
- **La sugerencia.** Cada aviso dice dónde se arregla: casi siempre en una
  subsección de la fase 1. El semáforo es un puente hacia atrás, no un muro.
- **Qué supuesto NO aparece.** La lista sale del registro del método. Si un
  método declara tres supuestos, hay exactamente tres cosas que la app sabe
  comprobar sobre él, y todo lo demás sigue siendo tu trabajo.

## Cuándo engaña

**Verde no es permiso.** Los supuestos se comprueban con heurísticas y umbrales
convencionales: 5 % de atípicos, correlación de 0,3, desviaciones que difieren
menos de tres veces. Son puntos de corte razonables, no verdades. Un dataset
puede pasar los tres y seguir siendo mala idea para el método.

**Se evalúan sobre los datos de ahora.** Si después transformás, partís o
balanceás, el semáforo mira otra cosa. Volvé a mirarlo si cambiaste la fase 1.

**Un supuesto sin comprobación automática aparece igual, en gris.** Está
declarado en el registro y todavía no tiene prueba. Es deuda visible a
propósito: preferimos decir "esto no lo sé comprobar" antes que callarlo.
