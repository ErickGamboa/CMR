-- Catálogo del libro, parte 4: menú de restaurantes.
--
-- El PDF no anota la porción de la mayoría de los platillos de restaurante,
-- porque se sobreentiende que es una unidad u orden. Acá va escrita para que
-- la app la pueda mostrar; las que se dedujeron están en LIBRO_REVISION.md.
--
-- En el PDF hay dos filas cuyos valores caen sobre un subtítulo, sin nombre de
-- platillo. La de Pizza Hut se pudo identificar por los números y quedó como
-- "Pizza regular"; la de McDonald's no, y quedó en 'por_revisar', que la app no
-- muestra.

-- ---------------------------------------------------------------------------
-- Subway
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, p, v, g, orden) values
  ('subway-001', 'subway', 'Sándwiches', 'Pollo asado, pollo teriyaki y jamón', '{}', '15 cm', 2.5,   2, 1, 0, 1),
  ('subway-002', 'subway', 'Sándwiches', 'Pavo o roast beef',                   '{}', '15 cm', 2.5, 1.5, 1, 0, 2),
  ('subway-003', 'subway', 'Sándwiches', 'Vegetariano',                         '{}', '15 cm', 2.5,   0, 1, 0, 3),
  ('subway-004', 'subway', 'Sándwiches', 'Mariscos o albóndiga',                '{}', '15 cm', 2.5,   2, 1, 3, 4),
  ('subway-005', 'subway', 'Sándwiches', 'BBQ ribs',                            '{}', '15 cm', 2.5,   3, 1, 0, 5),
  ('subway-006', 'subway', 'Acompañamientos', 'Galleta',                        '{}', '1 unidad',  2, 0, 0, 2, 6),
  ('subway-007', 'subway', 'Acompañamientos', 'Papas', array['Lay''s'],         '1 bolsa',   2, 0, 0, 0.5, 7)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, v = excluded.v, g = excluded.g,
  orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Pizza Hut
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, p, v, l, g, estado, nota, orden) values
  ('pizza-001', 'pizza-hut', 'Pasta', 'Spaghetti Napolitano', '{}', '1 orden',   3, 0, 2, 0.5, 1, 'publicado', null, 1),
  -- En el PDF estos valores caen sobre el subtítulo "Pizza", sin nombre de
  -- platillo. La sección lista la personal, la delgada y el breadstick, así que
  -- lo que falta es la porción de pizza regular; los números calzan (la delgada
  -- cuenta 2 carbos y esta 2.5, y el vegetal es la salsa de tomate, igual que
  -- en el spaghetti).
  ('pizza-002', 'pizza-hut', 'Pizza', 'Pizza regular',        '{}', '1 porción', 2.5, 1.5, 1, 0, 0, 'publicado', null, 2),
  ('pizza-003', 'pizza-hut', 'Pizza', 'Pizza personal',       '{}', '1 unidad', 8.5, 6, 0, 0, 4, 'publicado', null, 3),
  ('pizza-004', 'pizza-hut', 'Pizza', 'Pizza delgada',        '{}', '1 porción',  2, 2, 0, 0, 1.5, 'publicado', null, 4),
  ('pizza-005', 'pizza-hut', 'Pizza', 'Breadstick',           '{}', '1 unidad', 1.5, 0.5, 0, 0, 0.5, 'publicado', null, 5)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, v = excluded.v, l = excluded.l, g = excluded.g,
  estado = excluded.estado, nota = excluded.nota, orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Comida japonesa
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, nombre, marcas, porcion, c, p, v, g, orden) values
  ('jap-001', 'japonesa', 'California roll',              '{}', '8 piezas',    2.5,   1, 0,   1, 1),
  ('jap-002', 'japonesa', 'Philadelphia roll',            '{}', '8 piezas',    2.5, 1.5, 0, 1.5, 2),
  ('jap-003', 'japonesa', 'Dragon roll',                  '{}', '8 piezas',    2.5,   1, 0, 1.5, 3),
  ('jap-004', 'japonesa', 'Rainbow roll',                 '{}', '8 piezas',    2.5, 2.5, 0,   0, 4),
  ('jap-005', 'japonesa', 'Sopa miso pequeña',            '{}', '1 unidad',      0,   0, 1,   0, 5),
  ('jap-006', 'japonesa', 'Salsa de soya',                '{}', '3 cucharadas',  1,   0, 0,   0, 6),
  -- 2 proteínas son 60 g de pescado: eso es una orden, no una lámina.
  ('jap-007', 'japonesa', 'Sashimi',                      '{}', '1 orden',       0,   2, 0,   0, 7),
  ('jap-008', 'japonesa', 'Salsa de anguila o teriyaki',  '{}', '1 cucharada',   1,   0, 0,   0, 8)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, nombre = excluded.nombre,
  marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, v = excluded.v, g = excluded.g,
  orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Taco Bell
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, nombre, marcas, porcion, c, p, g, orden) values
  ('taco-001', 'taco-bell', 'Taco original',      '{}', '1 unidad',   1, 1, 2, 1),
  ('taco-002', 'taco-bell', 'Taco suave',         '{}', '1 unidad', 1.5, 1, 2, 2),
  ('taco-003', 'taco-bell', 'Crunchwrap Supreme', '{}', '1 unidad', 1.5, 1, 1, 3)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, nombre = excluded.nombre,
  marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, g = excluded.g, orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Burger King
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, p, v, g, orden) values
  ('bk-001', 'burger-king', null, 'Whopper clásico',         '{}', '1 unidad', 2.5, 3, 0, 5, 1),
  ('bk-002', 'burger-king', null, 'Whopper Jr.',             '{}', '1 unidad',   2, 2, 0, 2, 2),
  ('bk-003', 'burger-king', null, 'King de pollo',           '{}', '1 unidad',   2, 2, 0, 3, 3),
  ('bk-004', 'burger-king', null, 'TenderGrill Classic',     '{}', '1 unidad', 2.5, 3, 0, 1, 4),
  ('bk-005', 'burger-king', null, 'Chicken Crispy',          '{}', '1 unidad', 2.5, 3, 0, 5, 5),
  ('bk-006', 'burger-king', null, 'Ensalada de pollo grill', '{}', '1 unidad',   0, 3, 3, 2, 6),
  ('bk-007', 'burger-king', 'Acompañamientos', 'Ensalada individual', '{}', '1 unidad', 0, 0, 1, 0, 7),
  ('bk-008', 'burger-king', 'Acompañamientos', 'Papas fritas pequeñas', '{}', '1 orden', 2, 0, 0, 2.5, 8)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, v = excluded.v, g = excluded.g,
  orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- KFC
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, p, v, g, orden) values
  ('kfc-001', 'kfc', 'Pollo', 'Filet grill',                 '{}', '1 unidad',   0, 2, 0, 0, 1),
  ('kfc-002', 'kfc', 'Pollo', 'Filet original',              '{}', '1 unidad', 0.5, 2, 0, 1, 2),
  ('kfc-003', 'kfc', 'Pollo', 'Pollo original (muslo)',      '{}', '1 unidad', 0.5, 2, 0, 2, 3),
  ('kfc-004', 'kfc', 'Pollo', 'Pollo original (pechuga)',    '{}', '1 unidad',   1, 3, 0, 3, 4),
  ('kfc-005', 'kfc', 'Pollo', 'Popcorn Chicken pequeño',     '{}', '1 orden',    2, 2, 0, 3, 5),
  ('kfc-006', 'kfc', 'Acompañamientos', 'Biscuit',           '{}', '1 unidad',   1, 0, 0, 2, 6),
  ('kfc-007', 'kfc', 'Acompañamientos', 'Ensalada de repollo', '{}', '1 porción', 1, 0, 2, 2, 7),
  ('kfc-008', 'kfc', 'Acompañamientos', 'Puré de papa',      '{}', '1 porción',  1, 0, 0, 1, 8)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, v = excluded.v, g = excluded.g,
  orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- McDonald's
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, p, v, g, estado, nota, orden) values
  ('mcd-001', 'mcdonalds', 'Pollo',        '4 nuggets',               '{}', '4 unidades', 0.5,   1, 0, 2, 'publicado', null,  1),
  ('mcd-002', 'mcdonalds', 'Pollo',        'Pollo McCrispy',          '{}', '3 piezas',     1,   2, 0, 4, 'publicado', null,  2),
  ('mcd-003', 'mcdonalds', 'Papas',        'Papas fritas pequeñas',   '{}', '1 orden',    1.5,   0, 0, 2, 'publicado', null,  3),
  -- Estos valores caen sobre el subtítulo "Ensaladas", sin nombre de platillo,
  -- y debajo ya vienen las dos ensaladas del menú (pechuga grill y crispy).
  -- Ponerle nombre sería inventarse un platillo, así que queda cargada y
  -- oculta hasta que el doctor diga cuál es.
  ('mcd-004', 'mcdonalds', 'Ensaladas',    'Ensaladas',               '{}', null,           2,   2, 0, 3, 'por_revisar',
   'Fila sin nombre de platillo en el libro. Pendiente de confirmar.',                        4),
  ('mcd-005', 'mcdonalds', 'Ensaladas',    'Pechuga grill',           '{}', '1 unidad',     0,   3, 2, 0, 'publicado', null,  5),
  ('mcd-006', 'mcdonalds', 'Ensaladas',    'Pechuga crispy',          '{}', '1 unidad',     1, 3.5, 2, 2, 'publicado', null,  6),
  ('mcd-007', 'mcdonalds', 'Desayunos',    'Egg McMuffin',            '{}', '1 unidad',     2,   2, 0, 3, 'publicado', null,  7),
  ('mcd-008', 'mcdonalds', 'Desayunos',    'Pancakes simples',        '{}', '1 orden',      5,   1, 0, 1, 'publicado', null,  8),
  ('mcd-009', 'mcdonalds', 'Desayunos',    'McPinto con huevo',       '{}', '1 orden',    2.5,   2, 0, 2, 'publicado', null,  9),
  ('mcd-010', 'mcdonalds', 'Hamburguesas', 'Big Mac',                 '{}', '1 unidad',     3,   3, 0, 4, 'publicado', null, 10),
  -- El PDF la deja sin proteína, única hamburguesa del menú en ese caso. Lleva
  -- carne y queso, así que se le pone la misma proteína que a la Whopper Jr.,
  -- que es la hamburguesa equivalente.
  ('mcd-011', 'mcdonalds', 'Hamburguesas', 'Quesoburguesa',           '{}', '1 unidad',     2,   2, 0, 2, 'publicado', null, 11),
  ('mcd-012', 'mcdonalds', 'Hamburguesas', 'Cuarto de libra con queso', '{}', '1 unidad',   2,   4, 0, 4, 'publicado', null, 12),
  ('mcd-013', 'mcdonalds', 'Postres',      'M&M McFlurry',            '{}', '1 unidad',     4,   0, 0, 2.5, 'publicado', null, 13),
  ('mcd-014', 'mcdonalds', 'Postres',      'Pastel de manzana',       '{}', '1 unidad',     2,   0, 0, 2, 'publicado', null, 14),
  ('mcd-015', 'mcdonalds', 'Postres',      'Cono de cualquier sabor', '{}', '1 unidad',   4.5,   0, 0, 1, 'publicado', null, 15)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, v = excluded.v, g = excluded.g,
  estado = excluded.estado, nota = excluded.nota, orden = excluded.orden;
