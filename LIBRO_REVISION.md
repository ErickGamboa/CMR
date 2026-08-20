# Libro de intercambios — qué se corrigió y con qué criterio

El libro quedó transcrito completo: **284 alimentos** (234 con conteo + 50
libres), sacados del PDF leyendo las coordenadas reales de cada celda, no el
texto suelto, así que las columnas C/F/P/V/L/G están asignadas sin adivinar.

De esos 284, **283 se publican** en la app. Uno queda cargado y oculto (ver
§4).

## El criterio

1. **Se corrige** lo que es demostrablemente un error de columna o de
   transcripción: un valor que cae en un grupo imposible para ese alimento, o
   una fila que rompe el patrón de toda su sección.
2. **Se respeta el número del libro** cuando la duda es de magnitud —si el
   valor parece alto o bajo pero es posible—. El libro es la autoridad clínica,
   y quedarse corto al contar es el error que sí perjudica al paciente.
3. **No se inventa** un platillo que el libro no nombra.

Cada corrección está comentada en la fila del `.sql` que la contiene, así que
se puede auditar sin abrir este documento.

## 1. Conteos corregidos (4)

| Alimento | El PDF dice | Quedó | Por qué |
|---|---|---|---|
| **Garbanzos, lentejas** — ½ taza | 1 carbo + 1 **grasa** | 1 carbo + 1 **proteína** | Las leguminosas hervidas no traen grasa, y el propio libro cuenta las otras con proteína (hummus ½C+½P, gallo pinto ½C+½P). El valor estaba una columna a la derecha. |
| **Salsas de tomate** (Naturas, Prego) — ½ taza | ½C + 1V + ½ **lácteo** | ½C + 1V + ½ **grasa** | Una salsa embotellada no lleva lácteo. El ½ es el aceite con que viene preparada: el valor estaba una columna a la izquierda. |
| **Yogurt griego light o regular** (Dos Pinos) | 1 **carbohidrato**, cero lácteos | 1 **lácteo** | Era el único yogurt de la sección sin lácteo, entre nueve. El valor estaba en la columna de carbohidratos. |
| **Quesoburguesa** (McDonald's) | 2C + 2G, **sin proteína** | 2C + **2P** + 2G | Única hamburguesa del menú sin proteína, y lleva carne. Se le puso la misma que a la Whopper Jr., que es la equivalente. |

## 2. Porciones corregidas o completadas (18)

**Cambio de unidad**, porque la del PDF no puede ser:

- **Sardinas**, **atún en agua** y **atún en aceite**: "1 unidad" → **1 lata**.
  Una sardina suelta no da 60 g de proteína.
- **Sashimi**: "1 unidad" → **1 orden**. 2 proteínas son 60 g de pescado, que
  no es una lámina.

**Completadas** donde la sección no deja duda: Galletas Club y Galleta Club
Social integral (**1 paquete**, como el resto de las galletas); yogurt griego
alto en proteína, Bio Delactomy y yogurt light de Pops (**1 unidad**); helados
TCBY (**½ taza**, como los otros dos helados); cerveza light (**350 ml**);
Adán y Eva (**1 unidad**); vino chardonnay y vino rosado (**150 ml**, como los
otros tres vinos); tamal regular (**1 unidad**); arroz con pollo (**1 taza**);
martini (**1 copa**) y gin tonic (**1 vaso**).

En el menú de restaurantes se escribió la porción obvia (**1 unidad**,
**1 orden**, **1 porción**) porque se sobreentiende, y en Subway **15 cm** a
los cinco sándwiches, aunque el PDF solo lo anota en los dos primeros.

## 3. Fila identificada por sus números (1)

En Pizza Hut, los valores **2.5C + 1.5P + 1V** caen sobre el subtítulo "Pizza",
sin nombre de platillo. La sección lista la personal, la delgada y el
breadstick: lo que falta es la porción de pizza regular, y los números calzan
—la delgada cuenta 2 carbos y esta 2.5, y el vegetal es la salsa de tomate,
igual que en el spaghetti—. Quedó publicada como **"Pizza regular ·
1 porción"**.

## 4. La única fila que queda oculta

En McDonald's, los valores **2C + 2P + 3G** caen sobre el subtítulo
"Ensaladas", y debajo ya vienen las dos ensaladas del menú (pechuga grill y
pechuga crispy). Ponerle nombre sería inventarse un platillo, así que está
cargada con `estado = 'por_revisar'` y **la app no la muestra**. Cuando el
doctor diga cuál es, se le cambia el nombre y el estado y aparece sola.

## 5. Valores que se dejaron como los dice el libro

Se ven raros, pero son posibles y quedarse corto al contar es peor que
sobrar. Vale confirmarlos con Esteban en algún momento, sin que bloqueen nada:

- **Yogurt líquido fit (Nikkos)**, 1 unidad → 1C + ½P + **2 lácteos**. Es el
  doble de lácteo que cualquier otro yogurt de la sección.
- **Pulpa de fruta**, ¼ taza → ½ carbo **+** 1 fruta. Podría ser uno **ó** el
  otro.
- **Pita micro delgado blanco** (Pura Pita) → el libro trae dos filas: 3 u = 1
  carbo y 2 u = 1½ carbos, que se contradicen. Quedaron las dos, cada una con
  su porción, tal como están impresas.

## 6. Erratas de digitación corregidas

Solo ortografía y nombres de marca — ningún número:

`azúcar regulas` → azúcar regular · `98% boja en grasa` → bajo en grasa ·
`Aceite de suya` → de soya · `Cuarto de libre con queso` → de libra ·
`3 tasas` / `½ tasa` → tazas · `petit poas` → petit pois · `mani` → maní ·
`Spaguetti Napolinato` → Spaghetti Napolitano · `Daikiri` → Daiquirí ·
`Mozarella` → mozzarella · `Crunchywrap supreme` → Crunchwrap Supreme ·
`Pop corn Chicken` → Popcorn Chicken · `Tender Grill classic` → TenderGrill
Classic · `(San PellegrinoI:` → (San Pellegrino): · `Aceites es spray` → en
spray · `Kellogg”s` / `Kelloggs` → Kellogg's · `Jacks` → Jack's ·
`Lays` → Lay's · `Hersheys` → Hershey's · `Te frío/negro/verde/chai` → Té ·
`1 cucharada 0 15g` → 1 cucharada o 15 g · `Sandia` → Sandía ·
`Yogurt Griego liquido` → líquido · `no usar mas de 3 segundos` → más.

Dos que **no** se tocaron por no estar seguro de la marca real:
`Yogurt Bio Delactomy` (¿Deslactomy?) y `Lio Te Light`.

## 7. Cosas que el libro da por sabidas y la app explica

- El **alcohol se cuenta como grasa**: por eso todas las bebidas alcohólicas
  gastan intercambios de la columna G. Va como nota de la sección.
- **30 g = 1 proteína**, que el PDF pone en el título de la sección.
- El **`*`** de las comidas compuestas quedó como "grasa según cómo se
  prepare".
- El **`ó`** de tres alimentos (leche + proteína, queso mozzarella, queso
  fresco) quedó como conteo alternativo: cuentan de una forma **o** de la otra.
- Las **cremas en sobre** aparecen entre los alimentos libres pero cuestan
  ½ carbohidrato; quedaron en esa sección con la aclaración.
