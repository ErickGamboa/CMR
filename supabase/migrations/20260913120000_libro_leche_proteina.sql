-- Leche + Proteína (Dos Pinos): no es "ó", es "y".
--
-- Se había transcrito como 1 proteína ó 1 lácteo, a elección, igual que el
-- queso fresco. El doctor confirmó que la porción gasta las dos cosas: 1
-- proteína y 1 lácteo. Se quita el conteo alternativo y el lácteo pasa a la
-- columna fija.

update libro_alimentos
   set p = 1,
       l = 1,
       alternativa = null
 where id = 'lact-012';
