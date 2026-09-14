-- Catálogo del libro, parte 2: vegetales, frutas y lácteos.

-- ---------------------------------------------------------------------------
-- Vegetales
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, v, l, g, nota, orden) values
  ('veg-001', 'vegetales', null, 'Vegetales crudos y cocinados', '{}', '½ taza', 0, 1, 0, 0, null, 1),
  ('veg-002', 'vegetales', 'Salsas de vegetales', 'Salsas de tomate preparadas con hongos, carne, albahaca o ranchera', array['Roma'], '½ taza', 0, 1, 0, 0, null, 2),
  -- El PDF pone el ½ en la columna de lácteos. Una salsa de tomate embotellada
  -- no lleva lácteo, y el ½ corresponde al aceite con que viene preparada, así
  -- que el valor iba una columna a la derecha.
  ('veg-003', 'vegetales', 'Salsas de vegetales', 'Salsas de tomate', array['Naturas', 'Prego'], '½ taza', 0.5, 1, 0, 0.5, null, 3),
  ('veg-004', 'vegetales', 'Salsas de vegetales', 'Salsa Chunky', '{}', '½ taza', 0, 1, 0, 0, '1 al día', 4),
  ('veg-005', 'vegetales', 'Salsas de vegetales', 'Pasta de tomate', '{}', '2 cucharadas', 0, 1, 0, 0, null, 5)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, v = excluded.v, l = excluded.l, g = excluded.g,
  nota = excluded.nota, orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Frutas
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, f, orden) values
  ('fruta-001', 'frutas', null, 'Fruta pequeña o mediana (manzana, kiwi)', '{}', '1 unidad',                0, 1,  1),
  ('fruta-002', 'frutas', null, 'Fresa, frambuesa, mora',                  '{}', '1 taza',                  0, 1,  2),
  ('fruta-003', 'frutas', null, 'Banano grande',                           '{}', '1 unidad',                0, 2,  3),
  ('fruta-004', 'frutas', null, 'Fruta picada en general',                 '{}', '½ taza',                  0, 1,  4),
  ('fruta-005', 'frutas', null, 'Melón, papaya',                           '{}', '1 taza (65 g)',           0, 1,  5),
  ('fruta-006', 'frutas', null, 'Sandía',                                  '{}', '¼ de sandía pequeña',     0, 1,  6),
  ('fruta-007', 'frutas', null, 'Ciruela',                                 '{}', '2 pequeñas',              0, 1,  7),
  ('fruta-008', 'frutas', null, 'Jocotes',                                 '{}', '3 maduros o 5 verdes',    0, 1,  8),
  ('fruta-009', 'frutas', null, 'Mamón chino',                             '{}', '6 unidades',              0, 1,  9),
  ('fruta-010', 'frutas', null, 'Manzana de agua',                         '{}', '2 pequeñas o 1 grande',   0, 1, 10),
  ('fruta-011', 'frutas', null, 'Nance',                                   '{}', '19 unidades',             0, 1, 11),
  ('fruta-012', 'frutas', null, 'Uvas',                                    '{}', '17 pequeñas u 8 grandes', 0, 1, 12),
  ('fruta-013', 'frutas', null, 'Cerezas',                                 '{}', '15 unidades',             0, 1, 13),
  ('fruta-014', 'frutas', null, 'Fruta seca o deshidratada en general',    '{}', '¼ taza',                  0, 1, 14),
  ('fruta-015', 'frutas', 'Jugos de frutas', 'Jugo 100% natural casero',   '{}', '½ taza',                  0, 1, 15),
  ('fruta-016', 'frutas', 'Jugos de frutas', 'Pulpa de fruta',             '{}', '¼ taza',                0.5, 1, 16),
  ('fruta-017', 'frutas', 'Jugos de frutas', 'Agua de pipa',               '{}', '2 tazas',                 0, 1, 17)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, f = excluded.f, orden = excluded.orden;

-- ---------------------------------------------------------------------------
-- Lácteos
--
-- Tres alimentos traen conteo alternativo (el "ó" del libro impreso): cuentan
-- de una forma o de la otra, a elección del paciente.
-- ---------------------------------------------------------------------------

insert into libro_alimentos
  (id, seccion_id, subseccion, nombre, marcas, porcion, c, p, l, g, alternativa, orden) values
  ('lact-001', 'lacteos', 'Yogurt', 'Yogurt natural y de frutas light, diferentes marcas', '{}', '200 ml',   0,   0,   1,   0, null,  1),
  ('lact-002', 'lacteos', 'Yogurt', 'Yogurt griego líquido Plus',           array['Dos Pinos'],  '1 unidad', 0, 1.5,   1,   0, null,  2),
  -- El PDF pone el 1 en la columna de carbohidratos y deja el yogurt sin
  -- lácteo, único caso en toda la sección: el valor iba en lácteos.
  ('lact-003', 'lacteos', 'Yogurt', 'Yogurt griego light o regular',        array['Dos Pinos'],  '1 unidad', 0,   0,   1,   0, null,  3),
  ('lact-004', 'lacteos', 'Yogurt', 'Yogurt griego alto en proteína',       array['Nikkos Fit'], '1 unidad', 0,   1,   1,   0, null,  4),
  ('lact-005', 'lacteos', 'Yogurt', 'Yogurt Bio Defensa o Lula Cre-C',      array['Dos Pinos'],  '1 unidad', 0.5, 0, 0.5,   0, null,  5),
  ('lact-006', 'lacteos', 'Yogurt', 'Yogurt Bio Delactomy',                 array['Dos Pinos'],  '1 unidad', 1,   0,   1,   0, null,  6),
  ('lact-007', 'lacteos', 'Yogurt', 'Yogurt regular Deligurt',              array['Dos Pinos'],  '1 unidad', 1,   0, 0.5, 0.5, null,  7),
  ('lact-008', 'lacteos', 'Yogurt', 'Yogurt líquido fit, varios sabores',   array['Nikkos'],     '1 unidad', 1, 0.5,   2,   0, null,  8),
  ('lact-009', 'lacteos', 'Yogurt', 'Yogurt light',                         array['Pops'],       '1 unidad', 0,   0,   1,   0, null,  9),

  ('lact-010', 'lacteos', 'Leche', 'Leche doble proteína',                  array['Dos Pinos'],  '1 taza',   0,   1,   1,   0, null, 10),
  ('lact-011', 'lacteos', 'Leche', 'Leche 0% grasa',                        array['Dos Pinos'],  '1 taza',   0,   0,   1,   0, null, 11),
  ('lact-012', 'lacteos', 'Leche', 'Leche + Proteína, diferentes sabores',  array['Dos Pinos'],  '1 unidad', 0,   1,   1,   0, null, 12),
  ('lact-013', 'lacteos', 'Leche', 'Choco Leche',                           array['Dos Pinos'],  '200 ml',   1,   0,   1, 0.5, null, 13),
  ('lact-014', 'lacteos', 'Leche', 'Rompope regular',                       array['Dos Pinos'],  '½ taza',   1,   0, 0.5,   0, null, 14),

  ('lact-015', 'lacteos', 'Helados', 'Helado + Proteína Plus',              '{}',                '½ taza',   0,   0,   1,   0, null, 15),
  ('lact-016', 'lacteos', 'Helados', 'Helados sin grasa y sin azúcar',      array['TCBY'],       '½ taza',   0,   0,   1,   0, null, 16),
  ('lact-017', 'lacteos', 'Helados', 'Helados light',                       array['Pops'],       '½ taza',   0,   0,   1,   1, null, 17),

  ('lact-018', 'lacteos', 'Quesos', 'Queso mozzarella rallado, cualquiera', '{}',                '¼ taza',   0,   1,   0, 0.5, '{"l": 1, "g": 0.5}', 18),
  ('lact-019', 'lacteos', 'Quesos', 'Queso fresco',                         '{}',                '30 g',     0,   1,   0,   0, '{"l": 1}', 19)
on conflict (id) do update set
  seccion_id = excluded.seccion_id, subseccion = excluded.subseccion,
  nombre = excluded.nombre, marcas = excluded.marcas, porcion = excluded.porcion,
  c = excluded.c, p = excluded.p, l = excluded.l, g = excluded.g,
  alternativa = excluded.alternativa, orden = excluded.orden;
